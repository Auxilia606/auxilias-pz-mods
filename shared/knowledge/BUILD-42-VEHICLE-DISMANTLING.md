# Build 42 vehicle dismantling and removal APIs

Inspected 2026-09-13 against installed Project Zomboid **42.20.4 b0bbce05d5**.
The installed `projectzomboid.jar` had SHA-256
`80E405A4BFC42F6072E75B3735F458A6514143DA011D3226007DED305A442F44`.
This is shipped-Lua and Java-bytecode inspection, **not** a live gameplay or
multiplayer test. `config/project-zomboid.json` remains the active target.

## Vanilla wreck removal

`media/lua/client/Vehicles/ISUI/ISVehicleMenu.lua`, lines 616-645 in this
installation, adds the "Remove Burnt Vehicle" context option only when the
vehicle script's name contains `Burnt` or `Smashed`. The menu requires a welding
mask in the player's inventory and a `Base.BlowTorch` with at least 10 uses.
Its callback walks beside the vehicle, equips the torch, wears the mask, and
queues `ISRemoveBurntVehicle`.

`media/lua/shared/Vehicles/TimedActions/ISRemoveBurntVehicle.lua` defines that
action. Its `isValid()` checks only that the primary-hand item has the
`BLOW_TORCH` tag or `BlowTorch` type, has at least 10 uses, and the vehicle has
not been removed from the world. It does **not** recheck the wreck classification,
mask, passengers, engine, towing, animals, or vehicle containers. At completion
it rolls metal salvage, awards Metal Welding XP, consumes 10 torch uses, and
calls `vehicle:permanentlyRemove()`. Its `serverStart()` captures the primary-hand
item as `self.item`; checks involving that field must allow for the earlier
pre-start `isValid()` call.

Installed `BaseVehicle` bytecode shows `isBurnt()` and `isSmashed()` test whether
`getScriptName()` contains the corresponding word; `isBurntOrSmashed()` combines
them. This matches the vanilla menu's classification for ordinary scripts.
The classification describes a vehicle script, not whether a normal vehicle's
engine currently works.

## Authority and permanent removal

Installed `LuaTimedActionNew.complete()` invokes the Lua `complete` method only
when `GameClient.client` is false. `NetTimedAction.perform()` invokes that method
on the server for a networked timed action. Thus the shared vanilla action's
reward and removal path runs in single-player or on the server, rather than as
a client-side removal command. This establishes the inspected call path, not a
successful multiplayer gameplay run. A mod-specific action should recheck its
own conditions in `complete()` before calling the vanilla completion method;
the vanilla method does not do so.

`BaseVehicle.permanentlyRemove()` in the installed bytecode exits any occupants,
breaks a towing constraint, removes the vehicle from world and square membership,
removes it from its chunk's vehicle list, and calls `VehiclesDB2.removeVehicle()`.
It has no explicit step to transfer vehicle-container contents or installed
parts to the ground. This is a destructive operation; an ordinary dismantle
action must decide how to handle those objects before calling it.

The admin/cheat UI uses `sendClientCommand(player, "vehicle", "remove", ...)` in
`media/lua/client/Vehicles/ISUI/ISVehicleMechanics.lua`. The matching Lua
`Commands.remove` handler in `media/lua/server/Vehicles/VehicleCommands.lua`
looks up the ID and calls `permanentlyRemove()` without an explicit permission
check in that handler. Do not use this command as the ordinary dismantling
path; use a server-executed timed action with its own conditions.

## Available state checks

The installed `BaseVehicle` method table and shipped Lua confirm these names:

| Concern | API |
|---|---|
| Already removed or wreck script | `isRemovedFromWorld()`, `isBurntOrSmashed()` |
| Vehicle occupied | `hasPassenger()` or `getCharacter(seat)` |
| Engine and motion | `isEngineRunning()`, `isStopped()` |
| Towing | `getVehicleTowing()`, `getVehicleTowedBy()` |
| Animals in trailer | `getAnimals():size()` |
| Stored inventory | Iterate `getPartCount()` and zero-based `getPartByIndex(index)`; inspect each `part:getItemContainer():isEmpty()` when a container exists |
| Player beside vehicle | `isCharacterAdjacentTo(character)` |

`isStopped()` specifically means absolute speed below 0.8 km/h with the gas
pedal unpressed in the installed bytecode; it does not assert zero velocity.
`getTotalContainerItemWeight()` sums container weights, so it is less reliable
than `isEmpty()` for detecting contents, including items with zero weight.
The corpse-in-trailer path converts a corpse to an `IsoAnimal` and adds it to
the vehicle's animal list, so the list check includes those bodies in the
inspected implementation.

## Moving vehicle cargo to the ground

For a server-executed dismantle action, iterate every vehicle part's
`getItemContainer()` before calling `permanentlyRemove()`. Move each existing
`InventoryItem` object to `vehicle:getSquare()` with
`square:AddWorldInventoryItem(item, x, y, z)`, then call
`container:Remove(item)` and, on a server, `sendRemoveItemFromContainer(container,
item)`. `ISDropWorldItemAction.complete()` in the installed shared Lua uses this
drop-then-remove ordering; `Vehicles.Update.TrunkDoor` uses the same
`AddWorldInventoryItem(item)` and `Remove(item)` pair for items falling from a
moving trunk. Iterating each item's list from the last index to zero avoids
skipping entries as the container shrinks. The four-argument world-add method
broadcasts ordinary world items on the server in the installed bytecode, so a
second explicit world-item transmit is unnecessary.

Moving the original object preserves item condition, ID, and nested container
contents. Some item classes, including corpses, animals, and generators, may
become special world objects instead of ordinary floor icons. The installed
radio drop action also adds a companion `IsoRadio` object; a generic world-add
preserves the radio item but may not reproduce all placed-radio behavior. If
world-add fails, stop before salvage payout and vehicle removal; a partial
spill can remain beside the still-existing vehicle. This sequence is not
atomic across a server crash and has not been tested in live multiplayer.

Primary sources: the installed Lua paths above and `projectzomboid.jar`,
inspected with `javap -c -p` for `BaseVehicle`, `LuaTimedActionNew`, and
`NetTimedAction`. The [official `BaseVehicle` API](https://projectzomboid.com/modding/zombie/vehicles/BaseVehicle.html)
corroborates the public method names; the installed bytecode establishes the
method behavior described here. Reinspect these paths when the target build
changes.
