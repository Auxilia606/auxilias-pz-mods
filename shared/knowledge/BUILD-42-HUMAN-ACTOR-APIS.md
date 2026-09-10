# Build 42 human actor API observations

Inspected 2026-09-09 against installed Project Zomboid 42.20.4 b0bbce05d5.
These are static code observations, not runtime gameplay acceptance.

Research provenance: the Auxilia's Survivors experiment was retired and removed
on 2026-09-12. The versioned implementation reports and live results below are
historical evidence; its mod, fixtures and project-local reports are no longer
part of this repository. Reusable engine observations are retained here.

- `IsoPlayer.setNpc(true)` attaches `zombie.characters.component.AIComponent`.
  `AIComponent.update()` in this revision is empty. Its control/post-update methods
  apply NPC control values; the flag alone does not supply a follow/combat planner.
- `IsoPlayer.pressedMovement(boolean)` returns false for NPC-marked actors before
  checking local keyboard/network input. The shipped `ISWalkToTimedAction` otherwise
  cancels when its character reports player movement or cancel input.
- `ISTimedActionQueue` keys queues by character, not a numeric local-player slot.
  `clear(character)` calls `StopAllActionQueue` and clears queued actions. Its global
  queues table retains character references, which a mod must account for on detach.
- Shipped `WalkToTimedAction.lua` calls `PathFindBehavior2:pathToLocation` in start,
  `update` in the action update and `cancel`/`setPath2(nil)` on stop or completion.
  Its validity check rejects vehicles and game speeds above 2.
- `SurvivorDesc:dressInNamedOutfit`, name setters and human visual hair/beard/skin
  accessors are public. The installed clothing catalog has `Generic01` for both
  male and female outfits. The descriptor-taking IsoPlayer constructor copies the
  descriptor's human visual/worn items during initialization.
- `BodyDamage:ReduceGeneralHealth` and `getOverallBodyHealth` are public. Restoring
  only a total-health scalar is not equivalent to preserving individual wounds,
  infection or character needs.
- The world context menu test pass reads `ISWorldObjectContextMenu.Test`; merely
  returning true from an event listener is not its aggregate success result.
- A fresh cache without `mods/reset-mods-42_00.txt` clears `mods/default.txt` on
  first launch. This was observed in an isolated cache; do not mistake that launch
  for a successful mod-load test.

Source locations: installed `projectzomboid.jar` inspected with `javap -c -p`;
`media/lua/client/TimedActions/{WalkToTimedAction,ISTimedActionQueue}.lua`;
`media/lua/client/ISUI/ISWorldObjectContextMenu.lua`; `media/clothing/clothing.xml`.
Physical rendering/update participation and save/load behavior need live experiments.

## Explicit presentation registration (0.2.0 invisible-actor investigation)

Additional `javap -c -p` inspection of the same build:

- `IsoGameCharacter.setSceneCulled(false)` calls `ModelManager.Add(this)`;
  `true` calls `ModelManager.Remove(this)`. Constructor-created human visual data
  and membership in the cell object/add sets alone do not perform this registration.
- `IsoMovingObject.setMovingSquareNow()` calls `setMovingSquare(current)`, which
  removes old tile membership and adds the object to the current tile's moving
  objects without duplicates. `setCurrent` alone only updates a field.
- `ModelManager.Add` returns if the manager is not created yet or the character
  is already registered. `isAddedToModelManager()` is available for bounded checks.
- The registration method catches Java exceptions internally. A Lua pcall returning
  successfully therefore does not by itself prove a model was registered.

The 0.2.0 user report confirms invisibility after construction; the above observations
identify a missing initialization step. Visual confirmation after correcting it is
still required before asserting the rendering problem is resolved in-game.

## Registered IsoPlayer is omitted from the FBO world draw passes

The user's 0.2.1 runtime logs confirm cell, tile and model registration all true,
with culled=false, while the NPC remains invisible. Static inspection of the same
installed `FBORenderCell` shows:

- `renderMovingObject(IsoMovingObject)` compares `object.getClass()` against
  `IsoPlayer.class` and returns for exact instances, regardless of the NPC flag.
- In single-player, `renderPlayers(int)` iterates only `IsoPlayer.players` up to
  `numPlayers`. An NPC deliberately not registered as a local player is not drawn there.
- `renderOpaqueObjectsEvent(int)` fires `RenderOpaqueObjectsInWorld` in the world
  render phase after local players/opaque terrain. It passes the viewport and picked
  tile coordinates. Those picked coordinates are not the NPC's location.
- Vanilla `media/lua/shared/Fishing/Bobber.lua` uses this event for world rendering.
- `IsoGridSquare.isCanSee(int)` and `getLightInfo(int)` are public. An explicit draw
  should respect visibility and lighting instead of drawing through hidden rooms.
- `IsoGameCharacter.render` also returns early for zero alpha. Model registration
  and an actual render call are distinct diagnostics; neither alone proves pixels.

The experimental companion submitted its own world render via that event without
registering a local-player slot. Visual and depth/occlusion correctness remained
a runtime gate for that implementation.

## Live confirmation on 2026-09-10

In a fresh solo save on the same 42.20.4 revision, the explicitly registered
IsoPlayer rendered visibly through RenderOpaqueObjectsInWorld indoors and outdoors.
The actor moved using the vanilla ISWalkToTimedAction queue, followed the primary
player out of a house, and was removed/recreated without adding a player slot.
It was not drawn while its room was hidden from the outdoor player. This confirms
that this engine path can produce a visible moving human; it does not validate
every lighting, depth, animation or multiplayer case. This is a historical
summary of the retired experiment's live test, not an available runtime feature.

## NPC death and local-player database saves

Inspected with `javap -c -p` against the same 42.20.4 build on 2026-09-12:

- Both `IsoPlayer` constructors initialize `sqlId` to `-1`. A newly constructed
  NPC does not inherit the primary player's database ID.
- `IsoPlayer.OnDeath()` calls `removeSaveFile()` even for a non-local NPC.
  The `OnPlayerDeath` Lua event itself is guarded by `isLocalPlayer()`.
- `removeSaveFile()` calls `PlayerDB.saveLocalPlayersForce()`. That delegates to
  `savePlayersAsync()`, which iterates `IsoPlayer.players[0..numPlayers-1]`;
  it does not select the actor from `IsoPlayer.instance` or the death receiver.
- `PlayerDB$PlayerData.set(IsoPlayer)` copies the passed actor's `sqlId`, position,
  `isDead()` and descriptor name, then serializes that same actor. A companion
  outside the registered player slots is not saved as the primary player merely
  because its death caused the force-save call.
- `IsoDeadBody` contains no `PlayerDB` or `sqlId` update. In single-player its
  constructor associates the corpse's player reference only for a local player.

These observations establish which objects the native save path reads. They do
not establish why a particular local player died; test-fixture cleanup and any
later world simulation must be investigated separately.
