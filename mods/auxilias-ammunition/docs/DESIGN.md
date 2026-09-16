# Design

## Goal and boundaries

The mod makes ammunition self-sufficiency possible only after the survivor has built a
multi-skill production base. It uses vanilla resources, skills, ammo IDs, recipe learning,
and crafting UI, plus a dedicated hand-operated tabletop ammunition press. Its Lua
adds loot entries, restores missing native station components on saved presses,
and decorates the press's right-click option with its item icon.

No new skill, firearm or ammunition override, custom persistence, client command, or
spent-casing hook is part of this redesign. Improvised rounds have no reliability penalty because
they become vanilla ammunition; adding hidden weapon-state penalties would violate the
compatibility and minimal-runtime goals.

## Loop

`Cartridge body + Field powder -> 10 vanilla rounds`

- **Tabletop station:** craft the wood-and-iron `Mov_AmmoPress` item using carpentry and
  blacksmithing materials, then place it as a moveable on a table. Its item and entity
  scripts define `UiConfig` and `CraftBench` for the `AuxAmmoPress` recipe tag. A
  saved press from before those components were added can keep its earlier world-object
  state, so a scoped load-time repair adds either missing component from the item
  script. The station is unpowered and occupies one tabletop sprite. A scoped
  client click listener opens the native CraftBench window on a left-click; the
  existing right-click option remains available. A 42.20.4 single-player client
  opened its right-click CraftBench window on an existing save.
- **Cartridge body:** press an iron ingot and copper scrap together at the new tabletop
  station into a small pistol, heavy pistol, rifle, or shotgun body. This treats metal
  preparation and die changes as part of one game recipe. Shotgun bodies also require
  ripped sheets. The body combines its projectile and casing or hull in one inventory item.
  No clay mold, kiln, or fuel is needed for body production.
- **Field powder:** crush ordinary stone or limestone with a hammer into mineral powder;
  grind wood charcoal (`Base.CharcoalCrafted`), charcoal, or coke with a mortar and pestle
  into carbon powder without a skill requirement; prepare nitrogenous mix
  from two uses of a compost bag or two uses of NPK fertilizer; mix all three components on
  any surface. Two compost-bag uses are 50% of one full bag, while two fertilizer uses are
  25% of one full bag. Rotten food and picked-up animal dung can become the compost-bag
  input through the vanilla composter. These names and inputs describe an abstract
  ammunition-only game resource, not an actual energetic-material formula. The result
  keeps the published `SurvivalPropellant` item ID and cannot replace vanilla
  `Base.GunPowder` in other recipes.

All component outputs are batches. The press is a reusable station, and kept hand tools may
degrade through vanilla flags. Completed rounds are produced in batches of ten.

`MineralSalts` remains the item ID for crushed mineral powder. Carbon grinding is available
without a skill level or manual; nitrogenous-mix preparation requires Farming 3 but no manual.

## Progression

| Tier | Knowledge | Capability |
|---|---|---|
| I | Field Ammunition I or metal skill fallback | tabletop press and small pistol bodies |
| II | Field Ammunition II or high Foraging/Reloading/metal skill fallback | mineral powder, field powder, common and heavy pistol ammo; carbon grinding has no skill or manual gate, while nitrogenous-mix preparation needs Farming 3 without a manual |
| III | Field Ammunition III or end-game metal/Reloading | rifle and shotgun bodies and advanced ammo |

Manuals spawn primarily in gun-store literature; the last volume is exceptionally rare and
also appears in military ammunition storage. `AutoLearnAll` thresholds are higher than recipe
requirements, preserving manuals as valuable loot while allowing a high-skill route.

## Compatibility

The `AuxiliasAmmunition` module owns all component and recipe IDs. Recipes reference vanilla
inputs and outputs, and cartridge bodies use vanilla ground models.
Other firearm mods remain untouched. Mods using vanilla ammo automatically accept the output;
custom calibers need a separate additive patch.

## Multiplayer and save behavior

Crafting uses native `CraftRecipe` and `CraftBench` definitions, so inventory mutation, station
access, time, skill, and XP are intended to follow vanilla MP authority. The station's
right-click window and recipe list have been checked in a 42.20.4 single-player save;
placement, recovery, material consumption, and multiplayer UI still need acceptance.
Loot is inserted before procedural distributions merge and is
guarded against duplicate insertion within the Lua environment. The mod writes no `modData`,
files, or custom network messages. When adding the mod to a world for the first time, only
unexplored/newly generated containers can receive manuals. Removing the mod while custom
components remain will orphan those items, so players should craft or discard them first.
