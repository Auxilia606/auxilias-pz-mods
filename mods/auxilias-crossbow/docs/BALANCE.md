# First-test balance

The crossbows use Project Zomboid's aimed ranged-weapon system. Build 42.20 does not expose a separate physical projectile entity for ordinary firearms, so this build intentionally uses instant hit resolution and does not draw a flying bolt.

| Weapon | Range | Damage | Critical chance | Sound radius | Practical role |
|---|---:|---:|---:|---:|---|
| Light Crossbow | 9 | 0.75–1.15 | 20% | 6 | Emergency short-range hunting/defence |
| Crossbow | 14 | 1.00–1.45 | 25% | 8 | Deliberate mid-range hunting |
| Heavy Crossbow | 19 | 1.25–1.80 | 30% | 10 | Powerful, very slow single shot |
| Vanilla Pistol (reference) | 15 | 0.60–1.00 | 20% | 100 | Fast repeating sidearm |
| Vanilla Hunting Rifle (reference) | 40 | 1.20–2.00 | 30% | 170 | Long-range repeating rifle |

The numbers deliberately keep every crossbow below a hunting rifle's reach and peak damage. Their advantage is low noise and recoverable ammunition; their disadvantages are one-shot capacity, slow reload, weight, and demanding crafting skills.

Reload speed is tier-specific and intentionally much slower than vanilla firearms. Reloading skill helps, but does not turn the Heavy Crossbow into a fast weapon.

## Bolt crafting economy

Bolts can be assembled individually or in batches of five. Each finished bolt uses the same materials in either recipe. The material flow is:

1. Carve one vanilla Small Handle into one Bolt Shaft, or five Small Handles into five shafts in one batch.
2. Produce one of two distinct Bolt Head materials:
   - **Stone:** Knapp one Chipped Stone into two Stone Bolt Heads with a knapping tool at Flint Knapping 2.
   - **Metal:** Shape one Nail into one Metal Bolt Head with a hammer and file or whetstone at Maintenance 1, or forge one Iron/Steel Piece plus Charcoal into two heads with a smithing hammer and tongs at a Primitive Forge at Blacksmith 2.
3. Assemble each shaft with one matching head, one Twine use, and one item tagged by vanilla as a feather into a Stone or Metal Crossbow Bolt. The five-bolt recipe consumes five of each component.

Small Handles already come from vanilla wood-processing recipes, so the mod does not duplicate the game's branch-to-wood-blank economy. Chicken and Turkey Feathers are supplied by Build 42's animal-butchering system, so the mod consumes the shared `base:feather` tag instead of adding duplicate feather loot. Duct Tape is no longer a substitute for proper fletching.

Crossbow Bolts intentionally do not carry vanilla's `base:ammo` item tag. Build 42 uses that tag as the unrestricted input to `GatherGunpowder`, which would incorrectly let a mechanical bolt yield propellant. Crossbow loading is unaffected because Auxilia registers its two bolt materials through dedicated ammunition types.

A broken bolt cannot be turned directly into another complete bolt. Pliers pull a Metal Bolt Head from its broken shaft, while a sharp knife cuts the bindings and damaged wood away from a Stone Bolt Head. The player must supply a new shaft, feather, and binding before either recovered head can be fired again. Metal bolts have a 70% intact recovery chance, while the easier-to-source Stone Bolts have a 45% intact recovery chance. Both materials use the crossbow's weapon damage because Build 42 applies projectile damage from the weapon rather than the loose ammunition item.

An unloaded crossbow defaults to Metal Bolts. Its inventory context menu shows the current ammunition material and can switch it between Metal and Stone Bolts; normal reload and unload actions then use the selected material. The two advanced head paths make component pairs because a suitable stone or metal piece has enough stock for more than one small head. Both single and five-bolt assembly paths retain the same per-bolt material cost.

All eleven bolt-related recipes remain available when their Carving, Maintenance, Flint Knapping, or Blacksmith requirements are met. No magazine, schematic, or other recipe item is required. The Heavy Crossbow is the only learned recipe: it auto-unlocks at Maintenance 4 and Blacksmith 6, above its crafting requirement of Maintenance 4 and Blacksmith 4.

## Crafting calibration

Recipe duration and XP follow the inspected Build 42 crafting conventions: script `time = 600` for complex two-handed weapons, 230 for knapping, 200 for small forged-part batches, 100 for single-part carving and final assembly, and 60 for non-training salvage. Five-item batches take 450 time and award 40 Carving XP for shafts or 20 Maintenance XP for bolts, slightly below five individual crafts. Secondary skill awards on complete crossbows were reduced to keep a single craft from training several skills as strongly as a primary skill. Crossbow construction forms a linear Light → standard → Heavy upgrade path. Both upgrades require an unloaded input, inherit its condition, and preserve its Metal or Stone ammunition selection. Hand Drill and Stone Drill are explicit alternative tools for both upgrades. The Heavy Crossbow is a `time = 900` Advanced Forge operation using a Steel Bar Half and four Charcoal. See `docs/VANILLA-RECIPE-ALIGNMENT.md` for the vanilla source recipes and the complete comparison.
