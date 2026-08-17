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

Bolts are assembled one at a time instead of being produced as an abstract bundle. The material flow is:

1. Carve one vanilla Small Handle into one Bolt Shaft.
2. Produce one of two distinct Bolt Head materials:
   - **Stone:** Knapp one Chipped Stone into two Stone Bolt Heads with a knapping tool at Flint Knapping 2.
   - **Metal:** Shape one Nail into one Metal Bolt Head with a hammer and file or whetstone at Maintenance 1, or forge one Iron/Steel Piece plus Charcoal into two heads with a smithing hammer and tongs at a Primitive Forge at Blacksmith 2.
3. Assemble one shaft, one matching head, Twine, and one item tagged by vanilla as a feather into either a Stone or Metal Crossbow Bolt.

Small Handles already come from vanilla wood-processing recipes, so the mod does not duplicate the game's branch-to-wood-blank economy. Chicken and Turkey Feathers are supplied by Build 42's animal-butchering system, so the mod consumes the shared `base:feather` tag instead of adding duplicate feather loot. Duct Tape is no longer a substitute for proper fletching.

Crossbow Bolts intentionally do not carry vanilla's `base:ammo` item tag. Build 42 uses that tag as the unrestricted input to `GatherGunpowder`, which would incorrectly let a mechanical bolt yield propellant. Crossbow loading is unaffected because Auxilia registers its two bolt materials through dedicated ammunition types.

A broken bolt cannot be turned directly into another complete bolt. The matching tool recovers a head of the same material; the player must supply a new shaft, feather, and binding before it can be fired again. Metal bolts have a 70% intact recovery chance, while the easier-to-source Stone Bolts have a 45% intact recovery chance. Both materials use the crossbow's weapon damage because Build 42 applies projectile damage from the weapon rather than the loose ammunition item.

An unloaded crossbow defaults to Metal Bolts. Its inventory context menu shows the current ammunition material and can switch it between Metal and Stone Bolts; normal reload and unload actions then use the selected material. The two advanced head paths make component pairs because a suitable stone or metal piece has enough stock for more than one small head. Finished bolts are still assembled one at a time.

All eight bolt-related recipes remain automatically available when their Carving, Maintenance, Flint Knapping, or Blacksmith requirements are met. No magazine, schematic, or other recipe item is required.

## Crafting calibration

Recipe duration and XP follow stable Build 42.20.2 crafting conventions: script `time = 600` for complex two-handed weapons, 230 for knapping, 200 for small forged-part batches, 100 for small carving and final assembly, and 60 for non-training salvage. Crossbow construction forms a linear Light → standard → Heavy upgrade path. The Heavy Crossbow is a `time = 900` Advanced Forge operation using a Steel Bar Half and four Charcoal. See `docs/VANILLA-RECIPE-ALIGNMENT.md` for the vanilla source recipes and the complete comparison.
