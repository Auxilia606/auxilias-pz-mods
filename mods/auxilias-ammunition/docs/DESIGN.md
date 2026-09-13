# Design

## Goal and boundaries

The mod makes ammunition self-sufficiency possible only after the survivor has built a
multi-skill production base. It deliberately uses vanilla stations, resources, skills,
ammo IDs, recipe learning, and crafting UI. New code is limited to additive loot entries.

No new skill, workstation, firearm, ammunition override, custom persistence, client command,
or spent-casing hook is part of v1. Improvised rounds have no reliability penalty because
they become vanilla ammunition; adding hidden weapon-state penalties would violate the
compatibility and minimal-runtime goals.

## Loop

`Cartridge body + Field powder + Primer -> 10 vanilla rounds`

- **Cartridge body:** shape a clay mold at the Pottery Bench and fire it at a Kiln. Cast iron
  ingot and copper scrap together at a Furnace into a small pistol, heavy pistol, rifle, or
  shotgun body. Shotgun bodies also require ripped sheets. Each body replaces one projectile
  and one casing or hull in the inventory and in final assembly.
- **Field powder:** crush ordinary stone or limestone with a hammer into mineral powder;
  grind charcoal or coke with a mortar and pestle into carbon powder; mix the two powders on
  any surface. These names and inputs describe an abstract ammunition-only game resource,
  not an actual energetic-material formula. The result keeps the published
  `SurvivalPropellant` item ID and cannot replace vanilla `Base.GunPowder` in other recipes.
- **Primer:** rare factory primers bypass this high-skill component step. High-level survivors
  can form improvised primers from mineral powder, carbon powder, and copper at the Hand Press.

All component outputs are batches. Molds and tools are kept; tools may degrade through
vanilla flags. Completed rounds are produced in batches of ten.

Previously published projectile, casing, hull, and `MineralSalts` IDs remain defined for old
saves. The four former casing/hull recipe IDs now convert a matching legacy projectile and
casing/hull pair into one new body at the Hand Press. `MineralSalts` is displayed and used as
crushed mineral powder; saved stacks retain that ID. The conversions are listed in a separate
Saved Ammo Parts crafting category. Carbon grinding does not require a
manual because existing characters who read Manual II before the update cannot learn a new
recipe ID from that past reading. This avoids orphaning paired old parts, while unmatched old
parts do not have an automatic conversion route.

## Progression

| Tier | Knowledge | Capability |
|---|---|---|
| I | Field Ammunition I or Pottery/metal skill fallback | molds and small pistol bodies |
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

Crafting is native `CraftRecipe` work, so inventory mutation, station access, time, skill, and
XP follow vanilla MP authority. Loot is inserted before procedural distributions merge and is
guarded against duplicate insertion within the Lua environment. The mod writes no `modData`,
files, or custom network messages. Existing saves can add the mod safely; only unexplored/newly
generated containers can receive manuals or factory primers. Removing the mod while custom
components remain will orphan those items, so players should craft or discard them first.
