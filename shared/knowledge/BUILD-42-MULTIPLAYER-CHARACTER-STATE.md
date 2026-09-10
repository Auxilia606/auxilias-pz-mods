# Build 42 multiplayer character state and control ownership

Inspected 2026-09-12 against installed Project Zomboid **42.20.4 b0bbce05d5**.
The active target remains `config/project-zomboid.json`. This report describes
installed Java bytecode and shipped Lua, with isolated binding inspection where
stated. It is not a multiplayer gameplay test or full possession acceptance.

Research provenance: the Auxilia's Survivors experiment was retired and removed
on 2026-09-12. Its implementation and fixture results below are historical;
the mod and project-local test tools/reports are no longer available here.
Engine behavior and summarized evidence are preserved for future research.

The metadata probe reached the relevant binding tables before a later engine
initializer failed in the isolated process. Presence in those tables establishes
method binding, not successful invocation on a live character.

## Follow-up native verification

The retired experiment's 0.5.0 development work used an isolated JVM fixture with
actual human IsoPlayers. The final constructor boolean means animal, not skip initialization:
use false and assert `isAnimal()==false`, non-null Nutrition and non-null Fitness.
This matters because animal probes omit the human state under investigation.

The fixture verified the long native XP path with normal multipliers, native
human state serialization, and local-player array/singleton/NPC/camera changes
and rollback. Native control tests use minimal world membership and substitute
UI callbacks; they do not verify live input, the rendered HUD, or primary-save
bootstrap. These are historical observations with the limits stated here, not
instructions to run a currently distributed fixture.

An additional I/O finding: a Java exception during `IsoPlayer.load(String)` may
be logged by the Lua binding while Lua `pcall` still reports success. A real
human payload truncated by eight bytes restored the early ModData identity
marker and falsely passed an identity-only load check. Files therefore require
independent integrity checks; the identity marker alone is not evidence of a
complete native load. Lua file writers also wrap a PrintWriter that can swallow
I/O errors, so critical text writes require readback. These are binding/I/O
observations, not permission to edit native save databases.

`getLuaDebuggerErrorCount()` exposes KahluaThread's cumulative error counter
without requiring debug mode. It increased for the swallowed native load error;
comparison before/after a synchronous native call detects that failure. The
native string saver completes its serialization buffer before opening the output
file; subsequent I/O exceptions also reach this binding error path. A separate
byte-length/checksum readback detects later payload corruption. This does not
make native player saves, world ModData and NPC payloads one atomic transaction.

`getFileInput` reads under the active cache's `Lua` directory. `cacheFileExists`
already prefixes that directory: pass a mod namespace such as `YourMod/...`,
not `Lua/YourMod/...`.
The native string serializer accepts an absolute path in the same namespace,
allowing full readback with ordinary Lua. Save backups then need both the world
save and the associated cache-Lua payload directory.

## What multiplayer actually contributes

Multiplayer separates a character's identity, input owner, simulation authority,
replicated presentation, and durable save. A client rendering several people does
not independently run every person's complete player simulation.

In this installed build, survival state is substantially **server authoritative**:

| Area | Observed path | Consequence |
|---|---|---|
| Body damage | `BodyDamage.Update()` returns on a multiplayer client for a living `IsoPlayer`; a non-local living player's local body-damage representation is additionally restored to full health in that path. | A remote actor's ordinary body-damage object is not a complete authoritative medical record. |
| Needs and nutrition | Hunger/fatigue/thirst updates have server paths; client nutrition skips the calorie/macronutrient simulation. Single-player has a separate current-character context. | Adding an NPC to a remote-player collection cannot supply a missing survival simulation. |
| State delivery | `NetworkPlayerAI.syncStats/syncDamage/syncHealth/syncXp` require server mode and a connected owning connection. | These methods are not a single-player multi-character update API. |
| Typed snapshots | Stats/effects, injuries/damage, health and XP have separate packets. `PlayerStatsPacket` includes Stats, Nutrition and main BodyDamage values. | Movement, full medical details, XP and durable saves must not be treated as one universal synchronization record. |
| XP | Server Lua `addXp` reaches `GameServer.addXp`, which authorizes the target and uses the long native XP overload. | Server XP works through a different route from the short single-player wrapper. |

This is specific to the inspected build. The often repeated model that every
owner client computes all health/needs and the server merely relays them does not
describe these methods here. It also does not mean that all input, movement or
action logic is computed only on the server.

Movement has a different flow: the owner client sends prediction/current
movement through `PlayerPacket`; the server parses it into `NetworkPlayerAI`,
updates the connection's relevant position, and forwards it to other relevant
connections. Player validation/anti-cheat participates in this network path.
This audit did not establish the complete validation graph or packet cadence.

Detailed remote medical viewing uses an explicit subscription and applies
`BodyDamageUpdatePacket` data to `getBodyDamageRemote()`. This is a separate copy
from the remote actor's ordinary `getBodyDamage()`. A single-player squad can
instead read the actual loaded actor's body state. Client-originating body-change
paths also exist, such as `sendPlayerDamage`; the server-centered description is
not a claim that every health-related mutation originates on the server. The
complete medical/action packet validation graph was not audited.

## The isolated-NPC XP distinction

The shipped `media/lua/server/XpSystem/XpUpdate.lua` calls global `addXp`.
`LuaManager.GlobalObject.addXp` first checks that the actor exists in the world:

- Server: `GameServer.addXp` obtains the player's connection and checks permission
  or connection ownership. It calls the six-argument native `XP.AddXP` overload,
  then updates the XP checker.
- Multiplayer client: this global helper does not directly perform the award.
- Single-player: it calls `XP.AddXP(Perk, float)`, whose entry condition requires
  an `IsoPlayer` that is a registered local player. An isolated NPC fails it.

The longer XP overload retains native skill/trait/multiplier and other award
checks without that entry gate. This is a candidate for a deliberately scoped
single-player NPC adapter, after verifying the desired multiplier, event and
exactly-once behavior. `addXpNoMultiplier` is not an equivalent fix: its semantics
intentionally differ. Do not change the global server/client flags or temporarily
insert an NPC into a local-player slot merely to get an XP award.

## Control and presentation are separate responsibilities

`IsoPlayer.setLocalPlayer(slot, actor)` changes the local-player array entry;
`setInstance(actor)` changes a singleton context; `setNpc(boolean)` changes the
AI component. None is a complete character-possession lifecycle by itself.
The singleton can also change temporarily during native character updates; it is
not a durable character identity or proof of local-player membership.

An isolated, metadata-only process confirmed Lua bindings for `setLocalPlayer`,
`setInstance`, `setNpc`, `getIndex`, `getPlayerNum`, and the relevant IsoCamera
setters. The installed bindings do not expose a `setPlayerIndex`, `setPlayerNum`
or `setIndex` method, nor ordinary writable bindings for `playerIndex`/`sqlId`.
Both ordinary constructed actors can nevertheless have index 0, making a
single-slot-0 handoff a narrower experiment than adding more local players.

`IsoCamera.SetCharacterToFollow` also replaces the local player's moodle display.
Shipped `ISPlayerDataObject.lua`, `ISInventoryPage.lua`, `ISHotbar.lua`, and
`XpSystem/ISUI` panels contain a mixture of slot lookups and cached character or
inventory references. Changing only the singleton or camera can leave the HUD,
inventory actions, health panels and hotbar pointing at the previous character.

The vanilla global `setPlayerMouse(existingActor)` routes through
`addPlayerToWorld(0, actor, false)`. That path assigns `sqlId = 1`, unregisters the
outgoing emitter and culls its model, replaces the slot, and starts the co-op
world-registration path. `AddCoopPlayer` also handles chunk loading and
`OnCreatePlayer`. It is a useful lifecycle reference, not a transparent way to
keep the outgoing character alive as an independently saved NPC.

## Persistence and identity

The local-player slot, network identity and save identity serve different
purposes. A mod needs its own stable member ID rather than using a slot index as
the identity of a person.

`playerIndex` identifies a local/connection slot, `OnlineID` identifies a live
network actor, and `sqlId` identifies a local saved character. Network packet
resolution also depends on connection ownership and player maps. Multiplayer
character storage uses world/account/slot information rather than treating a
temporary OnlineID as permanent identity.

`PlayerDB.savePlayersAsync` traverses the registered local-player array.
`savePlayerAsync` allocates an ID when `sqlId == -1`, then captures that actor's
native state. An isolated NPC is not included just because it exists in the cell.
Putting one in slot 0 therefore changes what normal autosave captures; it does
not by itself establish the correct character to resume next launch.

`IsoWorld.LoadPlayerForInfo` and the ordinary primary-alive/startup path select
database ID 1. An incoming actor initially at `sqlId == -1` can therefore get a
different save ID after a raw slot swap, while the next launch still starts from
ID 1. Global `setSavefilePlayer1` is a save-selection-screen operation that
rewrites/swaps database row IDs. It does not reconcile current actor IDs, queued
saves and the in-memory allocator, so it must not be reused as a live handoff.

The native character serializer is much broader than a hand-written health
summary: its chain includes inventory and equipment, visuals, Stats, BodyDamage,
XP, Nutrition and Fitness. Full state persistence must also preserve mod-owned
identity/orders and coordinate world registration, death, item ownership and
the vanilla primary-player save. Native serialization alone does not provide
this lifecycle.

The actual `IsoPlayer` Lua method table exposes `save(String)` and `load(String)`;
these provide a native file payload candidate without constructing a ByteBuffer
from Lua. `ByteBuffer`, `PlayerDB` and `ClientPlayerDB` are not on the ordinary
Lua whitelist. The zero-argument `save()` is a different operation that writes
the vanilla `map_p.bin`, and is not an NPC snapshot helper.

The string save method writes directly to the supplied file and does not provide
an atomic snapshot commit. String load returns silently when the file is absent;
`pcall` success therefore does not prove restoration. Validate the payload and
its member/revision, and verify restored values before replacing a known-good
checkpoint. Native payloads use a version header; do not hardcode its integer.

String save/load sets `actor.saveFileName`. On NPC death, `removeSaveFile()` can
delete that file after requesting a local-player force-save. An independent
snapshot scheme must therefore account for native deletion and durable death
records; blindly falling back to an older alive payload could resurrect a dead
character and duplicate corpse items. The exposed file methods were inspected,
not exercised on a live actor or an existing save in this investigation.

## Reuse boundary for single-player mods

Reuse the separation of responsibilities: stable character identity, one live
state owner, explicit controller ownership, and views of that state. Continue
using normal native single-player updates where they already run. Audit and
adapt only the paths that demonstrably reject non-local NPCs; calling native
Stats/BodyDamage updates again can double-advance time or damage.

Do not treat a remote network replica as an autonomous NPC. Network registration,
connection ownership, privileged state packets and server persistence are not
available merely by assigning an OnlineID or invoking a sync helper. Actual
multiplayer NPC support would require a separate server-owned design.

## Sources and reproduction

Primary evidence: installed `projectzomboid.jar`, inspected with `javap -c -p`:
`IsoPlayer`, `IsoGameCharacter$XP`, `BodyDamage`, `Nutrition`, `NetworkPlayerAI`,
`GameServer`, `LuaManager$GlobalObject`, `PlayerDB`, and the corresponding
`zombie.network.packets.character` packet classes. UI evidence comes from shipped
`media/lua/client/ISUI/PlayerData`, `ISInventoryPage.lua`, `ISHotbar.lua`, and
`media/lua/client/XpSystem/ISUI`. Lua accessibility was checked against
`LuaManager$Exposer` and the installed Lua binding table without creating actors
or invoking a control/save operation.

Official API references corroborate the available names, not the inspected
method bodies or a working possession workflow:

- [IsoPlayer](https://projectzomboid.com/modding/zombie/characters/IsoPlayer.html)
- [Lua global methods](https://projectzomboid.com/modding/zombie/Lua/LuaManager.GlobalObject.html)
- [SyncPlayerStatsPacket](https://projectzomboid.com/modding/zombie/network/packets/SyncPlayerStatsPacket.html)
- [BodyPartSyncPacket](https://projectzomboid.com/modding/zombie/network/packets/BodyPartSyncPacket.html)

Related engine findings: `BUILD-42-HUMAN-ACTOR-APIS.md` and
`BUILD-42-NPC-COMBAT-APIS.md`. Feature-specific decisions belong in a mod's docs.
