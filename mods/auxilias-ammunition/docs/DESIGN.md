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

`Projectile + Casing/Hull + Survival Propellant + Primer -> 10 vanilla rounds`

- **Projectile:** clay mold at Pottery Bench, firing at Kiln, metal casting at Furnace.
- **Casing:** copper scrap formed at Hand Press. New manufacture is intentionally expensive;
  casing recovery is reserved for a later version with a verified B42 event contract.
- **Propellant:** compost plus limestone and charcoal become processed mineral salts, then an
  abstract ammo-only propellant at the charcoal station. This is a game-economy abstraction,
  not a real chemical formula.
- **Primer:** rare factory primers skip the hardest component step. High-level survivors can
  form improvised primers from salts, copper, and charcoal at the Hand Press.

All component outputs are batches. Molds and tools are kept; tools may degrade through
vanilla flags. Completed rounds are produced in batches of ten.

## Progression

| Tier | Knowledge | Capability |
|---|---|---|
| I | Field Ammunition I or Pottery/metal skill fallback | molds, small projectiles/casings |
| II | Field Ammunition II or high Farming/Foraging/Reloading | salts, propellant, primers, common pistol ammo |
| III | Field Ammunition III or end-game metal/Reloading | heavy pistol, rifle, and shotgun production |

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
