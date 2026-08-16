# Build 42.20.2 vanilla recipe alignment

This document records the balance pass against the installed stable Project Zomboid 42.20.2 data. The authoritative vanilla sources are under `media/scripts/generated` in the game installation.

Build 42.20.2 does not provide a vanilla bow, crossbow, arrow, or bolt crafting chain. Auxilia therefore uses the closest recipes by operation: carved handles and spears for wooden parts, improvised two-handed weapons for complete crossbows, knapped blades for stone heads, forged nails/hooks/spear heads for metal parts, and spear assembly/reclamation for final assembly and salvage.

## Vanilla anchors

| Vanilla recipe | Time | Skill / XP | Relevant method or material | Why it is comparable |
|---|---:|---|---|---|
| `CarveSmallHandle` | 100 | Carving 1 / 10 XP | Knife + small wood stock | Small carved wooden component |
| `CarveMediumHandle` | 200 | Carving 2 / 20 XP | Knife + handle stock | Higher-precision handle work |
| `NailSpikeWeapon` | 300 | Woodwork 1 / 10 XP | Hammer, wooden weapon, 5 Nails | Simple improvised weapon modification |
| `MakeSawbladePlank` | 600 | Woodwork 3 / 30 XP | Drill, wrench, screwdriver, fasteners, leather | Multi-tool surface-built two-handed weapon |
| `MakeSawbladeWeapon` | 600 | Woodwork 5 / 50 XP | Saw, chisel, drill, mallet, fasteners | Higher-tier complex wooden weapon assembly |
| `ForgeSpearHead` | 400 | Blacksmith 4 / 45 XP | Advanced Forge, 3 Charcoal, Steel Bar Quarter | Forged steel projectile/weapon head |
| `MakeStoneBlade` | 230 | Flint Knapping 1 / 20 XP | Chipped Stone + knapping tool | Finished sharp stone component |
| `Forge_Nails_From_Piece` | 200 | Blacksmith 1 / 20 XP | Primitive Forge, 1 Charcoal, metal piece → 2 Nails | Batch of two very small forged parts |
| `Forge_Fishing_Hooks` | 200 | Blacksmith 3 / 20 XP | Primitive Forge, Charcoal, wire → 4 hooks | Small precision-forged parts |
| `AssembleSpear` | 100 | Maintenance 1 / 10 XP | Head + shaft + hand tools | Final head-to-shaft weapon assembly |
| `ReclaimFromSpear` | 60 | No requirement / no XP | Reclaims head and shaft | Non-training disassembly/salvage |

Vanilla weapon recipes commonly use `time = 600` for complex two-handed construction. Carving recipes use 100–200 script time units for small or medium parts. Knapping recipes consistently use 230, small forge batches use 200, final implement assembly uses 100, and spear reclamation uses 60. These are the recipe script's relative `time` values; real elapsed time is applied by Build 42's timed-action system and character speed modifiers.

XP usually follows the primary skill gate in roughly ten-point steps. Small secondary operations often award 1–5 XP, while a Blacksmith 4 forged spear head awards 45 XP. Reclaiming an already-built item awards no XP.

## Auxilia changes

| Auxilia recipe | Previous | Adjusted 42.20.2 value | Basis |
|---|---|---|---|
| Improvised Crossbow | time 420; W18/C18/M6 XP | **time 600; W20/C20/M10 XP** | Complex two-handed weapon time; level-scaled XP |
| Reinforced Crossbow | time 650; W32/C28/M14 XP | **time 600; W40/C40/M30 XP** | Vanilla complex weapon time and level-scaled XP |
| Heavy Arbalest | time 900; W42/C32/M22/B38 XP | **time 900; W60/C50/M40/B45 XP** | Keeps top-tier duration; Blacksmith 4 mirrors forged spear-head XP |
| Carve Bolt Shaft | time 45; Carving 4 XP | **time 100; Carving 10 XP** | Small Handle carving baseline |
| Shape Metal Bolt Head from Nail | time 35; Maintenance 3 XP | **time 100; Maintenance 5 XP** | Small hand-work operation, below full weapon assembly XP |
| Knapp Stone Bolt Heads | time 120; Knapping 20 XP | **time 230; Knapping 20 XP** | Exact vanilla knapping duration; small two-piece output |
| Forge Metal Bolt Heads | time 180; Blacksmith 20 XP | **time 200; Blacksmith 20 XP** | Exact small forged-part batch baseline |
| Assemble Metal Bolt | time 60; Carving 4 + Maintenance 2 XP | **time 100; Maintenance 5 XP** | Spear/implement assembly; component skills are earned upstream |
| Assemble Stone Bolt | time 60; Carving 4 + Knapping 2 XP | **time 100; Maintenance 5 XP** | Same final assembly regardless of head material |
| Recover Metal Head | time 45; Maintenance 2 gate / 4 XP | **time 60; no skill gate / no XP** | Matches `ReclaimFromSpear` |
| Recover Stone Head | time 45; Knapping 2 gate / 4 XP | **time 60; no skill gate / no XP** | Matches `ReclaimFromSpear` |

`W`, `C`, `M`, and `B` abbreviate Woodwork, Carving, Maintenance, and Blacksmith in the compact table. Skill requirements on the three complete crossbows remain unchanged; the XP awards now reflect those gates using vanilla-style increments.

## Material and workstation corrections

- Reinforced Crossbow now requires a Screwdriver for its Screws and Pliers for its Wire. Vanilla fastener-heavy weapon recipes require the corresponding hand tools.
- Heavy Arbalest now requires an **Advanced Forge**, four Charcoal, a Ball-peen Hammer, Tongs, and one Steel Bar Half. This replaces two generic `MetalBar` items and surface crafting. The new stock is the same steel family used by vanilla advanced-forge weapon heads and tools.
- The Heavy Arbalest retains its file/whetstone, saw, metal drill, wrench, screwdriver, rope, leather, nuts/bolts, and screws because it combines forging the steel prod with fitting it to the existing Reinforced Crossbow.
- Both completed Bolt recipes continue to consume one vanilla-tagged Feather and one Twine. Build 42 supplies Chicken and Turkey Feathers through animal butchering.
- Stone and Metal Bolt Heads keep their existing raw-material yields: one Chipped Stone or one Iron/Steel Piece produces two heads. That matches the batch scale of vanilla small forged parts while completed ammunition remains one-at-a-time.

## Intentional project-specific differences

Some advanced vanilla recipes require research or auto-learning thresholds. Auxilia recipes intentionally remain available through skill gates alone, as established by the mod's design. No magazine or schematic requirement was added during this balance pass.

The complete crossbows also require multiple skills rather than vanilla's usual single primary skill. Their XP is distributed across the listed skills because each recipe combines stock shaping, joinery, mechanical fitting, and—at the Heavy tier—forging. Material cost and the Heavy tier's Reinforced Crossbow input limit their usefulness as repeatable XP farming recipes.
