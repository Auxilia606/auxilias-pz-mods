# Build 42 detached vehicle item repair

Inspected 2026-09-29 against the installed **42.21.0**, revision `4a0e9546ec`.
`projectzomboid.jar` SHA-256:
`E1A69EB743EDE60B213A0FE7F8B83D4FCAB773036D256CC4543A336F3B058A33`.
Core's static GameVersion is 42.21. The repository's active distribution line
and prior tested build still come from `config/project-zomboid.json`; this
inspection does not certify gameplay on either version or advance that config.

## Repair entry points

- `media/lua/shared/TimedActions/ISFixAction.lua`: `perform()` clears UI state;
  `complete()` calls Java `FixingManager.fixItem`. There is no repair-result Lua
  event in this path. A completion wrapper is possible, but is a global hook.
- `FixingManager.fixItem` bytecode increments `HaveBeenRepaired` once on success,
  then calls `syncItemFields()`. Failure can lose a condition point without a
  count increment. This differs from the generic crafting repair behavior
  documented in `BUILD-42-WEAPON-REPAIR.md`; do not conflate the two paths.
- `media/scripts/generated/recipes/recipes_fixing.txt`: new `craftRecipe` repairs
  use a kept input with `IsDamaged` and empty outputs. `OnCreate` changes the
  original item. A custom callback that handles the entire repair must own the
  count update itself and must not also call a vanilla fixing callback.
- `CraftRecipe.OnTestItem` calls the configured Lua predicate with `(item,
  character)` for input items, including materials and tools.
  `CraftRecipeData.luaCallOnCreate(character)` supplies `(recipeData, character)`.
  Do not use the older recipe `(items, result, player)` callback signature.
- `media/lua/shared/Entity/TimedActions/ISHandcraftAction.lua`:
  `performRecipe()` calls `performCurrentRecipe()`, delivers outputs, invokes
  `luaCallOnCreate`, then `processDestroyAndUsedItems`. SP calls this from
  `perform()`; MP calls it on the server from `complete()`. Its client path
  does not apply the recipe. Thus "put everything in complete" is not correct
  for a custom callback attached to this existing handcraft action.

## Item state and network authority

`InventoryItem.getHaveBeenRepaired/setHaveBeenRepaired` access the same integer
field as `getTimesRepaired/setTimesRepaired`. The setter has no hidden increment.
Use the existing count as the diminishing-return input, round condition changes
explicitly, and clamp to `getConditionMax()`.

In the inspected bytecode `InventoryItem.syncItemFields()` sends only when the
outermost container's parent is an `IsoPlayer`. It is not a generic world-item
or vehicle-part synchronization API. `isInPlayerInventory()` uses the same
outermost-container check, including carried bags. `SyncItemFieldsPacket`
serializes and applies both condition and `haveBeenRepaired`. A custom repair
can require the item in the acting player's inventory, mutate once on the
authority side, then call `item:syncItemFields()` once after both changes.

Installed `VehiclePart.setInventoryItem` calls `doInventoryItemStats`, which
reads the item's condition and sets the part's condition and related stats.
`VehiclePart.setCondition` also writes the installed item's condition.
Directly setting an InventoryItem does not call back into a VehiclePart.
`ISInstallVehiclePart.complete()` uses `setInventoryItem(item, Mechanics)` and
`transmitPartItem`. `ISUninstallVehiclePart.complete()` removes the installed
reference, transmits it, and transfers the original item to inventory or the
world. Let these ordinary install/uninstall paths transfer repaired condition.
Tire item capacity is copied from the part during uninstall; repairing condition
need not change pressure/capacity.

## Coverage inspection

`media/scripts/generated/items/normal.txt` and
`media/scripts/generated/vehicles/template_{brake,suspension,muffler,tire}.txt`
define removable condition-bearing parts. Vehicle item stems are expanded by
vehicle type suffix 1/2/3. Suspension has Normal/Modern variants, **no Old
variant**; the other three families have Old/Normal/Modern. These 33 items have
`MechanicsItem = true`, `ConditionMax = 100`, no generic repair tags, no entries
in `generated/fixing.txt`, and no `table repair` in those four templates.
Searches of generated recipes found destructive tire/weapon crafting uses, not
an existing repair for these targets. Do not select all VehicleMaintenance items:
other vehicle families have existing repair or recharge behavior.

Primary sources are the installed scripts above and `javap -c -p` inspection of
`Core`, `FixingManager`, `InventoryItem`, `VehiclePart`, `CraftRecipe`,
`CraftRecipeData`, and `SyncItemFieldsPacket`. The
[official InventoryItem API](https://projectzomboid.com/modding/zombie/inventory/InventoryItem.html)
also lists the repair-count accessors. Network packet delivery, real ingredient
consumption, UI loading, and reinstall behavior still require gameplay tests.
