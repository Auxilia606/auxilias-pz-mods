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
| Light Crossbow | old Improvised recipe: time 600; W20/C20/M10 XP | **time 600; W20/C20/M10 XP** | Complex two-handed weapon time; compact one-Plank construction |
| Crossbow | old Reinforced recipe: time 600; W40/C40/M30 XP | **time 600; W40/C30/M30 XP** | Upgrades the Light Crossbow with a metal prod and fittings |
| Heavy Crossbow | old Heavy Arbalest recipe: time 900; W60/C50/M40/B45 XP | **time 900; M40/B45 XP** | Forged compact upgrade; Blacksmith 4 mirrors forged spear-head XP |
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

- Light Crossbow uses one Plank, two Twine, and four Nails. This is below the material mass of large improvised two-handed weapons while retaining the same `time = 600` precision-build duration.
- Crossbow consumes the Light Crossbow and adds one Metal Bar, two Wire, one Rope, and four Screws. Its Screwdriver, Pliers, metal drill, and file/whetstone match the added fastener and metal-fitting operations.
- Heavy Crossbow consumes the standard Crossbow at an **Advanced Forge** with four Charcoal and one Steel Bar Half. A Ball-peen Hammer and Tongs handle forging; the metal drill, file, wrench, and screwdriver handle final fitting. Two Nuts/Bolts and four Screws replace the rope, leather, oversized mechanisms, and decorative hardware used by the previous design.
- Both completed Bolt recipes continue to consume one vanilla-tagged Feather and one Twine. Build 42 supplies Chicken and Turkey Feathers through animal butchering.
- Stone and Metal Bolt Heads keep their existing raw-material yields: one Chipped Stone or one Iron/Steel Piece produces two heads. That matches the batch scale of vanilla small forged parts while completed ammunition remains one-at-a-time.

## Cross-recipe compatibility audit

Build 42.20.2's vanilla `GatherGunpowder` recipe destroys any item tagged `base:ammo` and returns Gunpowder. That tag is appropriate for cartridges and shotgun shells but not for mechanically launched bolts. Metal and Stone Crossbow Bolts therefore omit `base:ammo`; their reload behavior continues to use the dedicated `auxiliascrossbow:bolt` and `auxiliascrossbow:stonebolt` ammunition registries.

The remaining shared inputs were checked against their installed vanilla definitions. `item 1 [Base.Twine]` consumes one of Twine's five `UseDelta = 0.2` uses, not a whole fresh spool. Chicken and Turkey Feathers expose `base:feather`, and the listed hand-tool tags resolve to the intended vanilla tool families. No other Auxilia output carries a vanilla recipe-input tag that changes it into an unrelated ingredient.

## Intentional project-specific differences

Some advanced vanilla recipes require research or auto-learning thresholds. Auxilia recipes intentionally remain available through skill gates alone, as established by the mod's design. No magazine or schematic requirement was added during this balance pass.

The Light and standard Crossbows use multiple skills because their recipes combine stock shaping, joinery, and mechanical fitting. The Heavy Crossbow upgrade requires only Maintenance and Blacksmith because it reuses a completed Crossbow and replaces its primary structure with forged iron. Linear upgrade inputs and material cost limit the recipes' usefulness for repeatable XP farming.
