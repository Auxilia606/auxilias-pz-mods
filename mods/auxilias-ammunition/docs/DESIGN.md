# Design

## Goal and boundaries

The mod makes ammunition self-sufficiency possible only after the survivor has built a
multi-skill production base. It uses vanilla resources, skills, ammo IDs, recipe learning,
and crafting UI, plus a dedicated hand-operated tabletop ammunition press. New Lua code
is limited to additive loot entries.

No new skill, firearm or ammunition override, custom persistence, client command, or
spent-casing hook is part of this redesign. Improvised rounds have no reliability penalty because
they become vanilla ammunition; adding hidden weapon-state penalties would violate the
compatibility and minimal-runtime goals.

## Loop

`Cartridge body + Field powder + Primer -> 10 vanilla rounds`

- **Tabletop station:** craft the wood-and-iron `Mov_AmmoPress` item using carpentry and
  blacksmithing materials, then place it as a moveable on a table. Its `CraftBench` advertises
  the `AuxAmmoPress` recipe tag. The station is unpowered and occupies one tabletop sprite,
  subject to in-game placement and recovery checks.
- **Cartridge body:** press an iron ingot and copper scrap together at the new tabletop
  station into a small pistol, heavy pistol, rifle, or shotgun body. This treats metal
  preparation and die changes as part of one game recipe. Shotgun bodies also require
  ripped sheets. Each body replaces one projectile and one casing or hull in inventory
  and final assembly. No clay mold, kiln, or fuel is needed for new bodies.
- **Field powder:** crush ordinary stone or limestone with a hammer into mineral powder;
  grind charcoal or coke with a mortar and pestle into carbon powder; mix the two powders on
  any surface. These names and inputs describe an abstract ammunition-only game resource,
  not an actual energetic-material formula. The result keeps the published
  `SurvivalPropellant` item ID and cannot replace vanilla `Base.GunPowder` in other recipes.
- **Primer:** rare factory primers bypass this high-skill component step. High-level survivors
  can form improvised primers from mineral powder, carbon powder, and copper at the new press.

All component outputs are batches. The press is a reusable station, and kept hand tools may
degrade through vanilla flags. Completed rounds are produced in batches of ten.

Previously published projectile, casing, hull, mold, and `MineralSalts` IDs remain defined for
old saves. The four former casing/hull recipe IDs convert a matching legacy projectile and
casing/hull pair into one new body at the press. Four published pottery recipe IDs now salvage
saved clay molds; they do not make new molds. `MineralSalts` is displayed and used as crushed
mineral powder; saved stacks retain that ID. All conversions are listed in the separate
Saved Ammo Parts crafting category. Mold salvage needs no manual; matching old-part conversion
still uses its published recipe knowledge or the high-skill fallback. Carbon grinding also
does not require a manual because existing characters who read Manual II before the update cannot learn a new
recipe ID from that past reading. This avoids orphaning paired old parts, while unmatched old
parts do not have an automatic conversion route.

## Progression

| Tier | Knowledge | Capability |
|---|---|---|
| I | Field Ammunition I or metal skill fallback | tabletop press and small pistol bodies |
| II | Field Ammunition II or high Foraging/Reloading/metal skill fallback | mineral powder, field powder, primers, common and heavy pistol ammo; carbon grinding needs Reloading 3 but no manual |
| III | Field Ammunition III or end-game metal/Reloading | rifle and shotgun bodies and advanced ammo |

Manuals spawn primarily in gun-store literature; the last volume is exceptionally rare and
also appears in military ammunition storage. `AutoLearnAll` thresholds are higher than recipe
requirements, preserving manuals as valuable loot while preventing old saves from becoming
permanently blocked.

## Compatibility

The `AuxiliasAmmunition` module owns all component and recipe IDs. `Base` is used only for a
model definition that exposes a shipped mesh and for references to vanilla inputs/outputs.
Other firearm mods remain untouched. Mods using vanilla ammo automatically accept the output;
custom calibers need a separate additive patch.

## Multiplayer and save behavior

Crafting uses native `CraftRecipe` and `CraftBench` definitions, so inventory mutation, station
access, time, skill, and XP are intended to follow vanilla MP authority. The new station's
placement, recovery, save/reload behavior, and multiplayer UI still need in-game acceptance.
Loot is inserted before procedural distributions merge and is
guarded against duplicate insertion within the Lua environment. The mod writes no `modData`,
files, or custom network messages. Existing saves can add the mod safely; only unexplored/newly
generated containers can receive manuals or factory primers. Removing the mod while custom
components remain will orphan those items, so players should craft or discard them first.
