# Build 42.20.2 vanilla recipe alignment

This document records the balance pass against the installed stable Project Zomboid 42.20.2 data. The authoritative vanilla sources are under `media/scripts/generated` in the game installation.

Build 42.20.2 does not provide a vanilla bow, crossbow, arrow, or bolt crafting chain. Auxilia therefore uses the closest recipes by operation: carved handles and spears for wooden parts, improvised two-handed weapons for complete crossbows, knapped blades for stone heads, forged nails/hooks/spear heads for metal parts, and spear assembly/reclamation for recipe timing and balance. The visible timed actions use compact-part or stone-working animations because the vanilla spear action displays a knife-tipped spear prop.

## Vanilla anchors

| Vanilla recipe | Time | Skill / XP | Relevant method or material | Why it is comparable |
|---|---:|---|---|---|
| `CarveSmallHandle` | 100 | Carving 1 / 10 XP | Knife + small wood stock | Small carved wooden component |
| `CarveMediumHandle` | 200 | Carving 2 / 20 XP | Knife + handle stock | Higher-precision handle work |
| `NailSpikeWeapon` | 300 | Woodwork 1 / 10 XP | Hammer, wooden weapon, 5 Nails | Simple improvised weapon modification |
| `MakeSawbladePlank` | 600 | Woodwork 3 / 30 XP | Drill, wrench, screwdriver, fasteners, leather | Multi-tool surface-built two-handed weapon |
| `MakeSawbladeWeapon` | 600 | Woodwork 5 / 50 XP | Saw, chisel, drill, mallet, fasteners | Higher-tier complex wooden weapon assembly |
| `ForgeSpearHead` | 400 | Blacksmith 4 / 45 XP | Advanced Forge, 3 Charcoal, Steel Bar Quarter | Forged steel projectile/weapon head |
| `MakeStoneBlade` | 230 | Flint Knapping 1 / 20 XP | Sharp Flint Flake (`Base.SharpedStone`) + knapping tool | Finished sharp stone component |
| `Forge_Nails_From_Piece` | 200 | Blacksmith 1 / 20 XP | Primitive Forge, 1 Charcoal, metal piece → 2 Nails | Batch of two very small forged parts |
| `Forge_Fishing_Hooks` | 200 | Blacksmith 3 / 20 XP | Primitive Forge, Charcoal, wire → 4 hooks | Small precision-forged parts |
| `AssembleSpear` | 100 | Maintenance 1 / 10 XP | Head + shaft + hand tools | Final head-to-shaft weapon assembly |
| `ReclaimFromSpear` | 60 | No requirement / no XP | Reclaims head and shaft | Non-training disassembly/salvage |

Vanilla weapon recipes commonly use `time = 600` for complex two-handed construction. Carving recipes use 100–200 script time units for small or medium parts. Knapping recipes consistently use 230, small forge batches use 200, final implement assembly uses 100, and spear reclamation uses 60. These are the recipe script's relative `time` values; real elapsed time is applied by Build 42's timed-action system and character speed modifiers.

XP usually follows the primary skill gate in roughly ten-point steps. Small secondary operations often award 1–5 XP, while a Blacksmith 4 forged spear head awards 45 XP. Reclaiming an already-built item awards no XP.

## Earlier Auxilia calibration

The following table records the original Build 42.20.2 balance pass. The current changes are listed in the 42.20.4 follow-up below.

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
| Recover Metal Head | time 45; Maintenance 2 gate / 4 XP | **time 60; no skill gate / no XP** | Pliers extract the socketed head; timing matches `ReclaimFromSpear` |
| Recover Stone Head | time 45; Knapping 2 gate / 4 XP | **time 60; no skill gate / no XP** | A sharp knife removes bindings and broken wood without striking the intact stone head; timing matches `ReclaimFromSpear` |

`W`, `C`, `M`, and `B` abbreviate Woodwork, Carving, Maintenance, and Blacksmith in the compact table. Skill requirements on the three complete crossbows remain unchanged; the XP awards now reflect those gates using vanilla-style increments.

## Material and workstation corrections

- Light Crossbow uses one Plank, two Twine, and four Nails. This is below the material mass of large improvised two-handed weapons while retaining the same `time = 600` precision-build duration.
- Crossbow consumes the Light Crossbow and adds one Metal Bar, two Wire, one Rope, and four Screws. Its Screwdriver, Pliers, metal drill, and file/whetstone match the added fastener and metal-fitting operations.
- Heavy Crossbow consumes the standard Crossbow at an **Advanced Forge** with four Charcoal and one Steel Bar Half. A Ball-peen Hammer and Tongs handle forging; the metal drill, file, wrench, and screwdriver handle final fitting. Two Nuts/Bolts and four Screws replace the rope, leather, oversized mechanisms, and decorative hardware used by the previous design.
- Both completed Bolt recipes continue to consume one vanilla-tagged Feather and one Twine. Build 42 supplies Chicken and Turkey Feathers through animal butchering.
- At the 42.20.2 pass, one Sharp Flint Flake (`Base.SharpedStone`) or one Iron/Steel Piece produced two heads. That matched the batch scale of vanilla small forged parts while completed ammunition remained one-at-a-time.

## Cross-recipe compatibility audit

Build 42.20.2's vanilla `GatherGunpowder` recipe destroys any item tagged `base:ammo` and returns Gunpowder. That tag is appropriate for cartridges and shotgun shells but not for mechanically launched bolts. Metal and Stone Crossbow Bolts therefore omit `base:ammo`; their reload behavior continues to use the dedicated `auxiliascrossbow:bolt` and `auxiliascrossbow:stonebolt` ammunition registries.

The remaining shared inputs were checked against their installed vanilla definitions. `item 1 [Base.Twine]` consumes one of Twine's five `UseDelta = 0.2` uses, not a whole fresh spool. Chicken and Turkey Feathers expose `base:feather`, and the listed hand-tool tags resolve to the intended vanilla tool families. No other Auxilia output carries a vanilla recipe-input tag that changes it into an unrelated ingredient.

## Intentional project-specific differences

This earlier balance pass left every Auxilia recipe available through skill gates alone. The later follow-up adds automatic learning to the Heavy Crossbow only; no magazine or schematic item is required.

The Light and standard Crossbows use multiple skills because their recipes combine stock shaping, joinery, and mechanical fitting. The Heavy Crossbow upgrade requires only Maintenance and Blacksmith because it reuses the completed Crossbow's hardwood tiller while adding a steel prod and reinforced iron fittings. Linear upgrade inputs and material cost limit the recipes' usefulness for repeatable XP farming.

## Build 42.20.4 follow-up

The installed Build 42.20.4 scripts confirm that vanilla `AssembleBlade`, `AssembleSpear`, and `NailSpikeWeapon` mark a consumed weapon or main component with `InheritCondition`. `ForgeSpearHead` and `ForgeLongSpearHead` require learned recipes and auto-unlock at higher skills. The installed `InputScript` bytecode checks `IsEmpty` for containers and drainables but not a HandWeapon's ammunition count, so the two crossbow upgrades use an `OnTest` callback to reject loaded inputs. Their `OnCreate` callback carries the selected Metal or Stone ammunition type into the new weapon.

| Current recipe | Time / XP | Change |
|---|---|---|
| Light Crossbow | 600 / Woodwork 20, Carving 10, Maintenance 5 | Reduced secondary-skill XP |
| Crossbow | 600 / Woodwork 40, Carving 15, Maintenance 10 | Reduced secondary-skill XP; inherits Light Crossbow condition and ammunition selection; requires it to be unloaded |
| Heavy Crossbow | 900 / Blacksmith 45, Maintenance 10 | Reduced secondary-skill XP; inherits Crossbow condition and ammunition selection; requires it to be unloaded; auto-learns at Maintenance 4 and Blacksmith 6 |
| Carve 5 Bolt Shafts | 450 / Carving 40 | Five Small Handles yield five shafts, preserving material cost |
| Assemble 5 Metal or Stone Bolts | 450 / Maintenance 20 each | Five shafts, matching heads, feathers, and Twine uses yield five bolts |

The single-bolt recipes retain their original IDs and values. Both Crossbow upgrades explicitly accept `Base.HandDrill` or `Base.StoneDrill`; the latter has only the vanilla `base:drillwoodpoor` tag and therefore cannot enter through the original `base:drillmetal` input. The three new batch recipes bring the total to fourteen without changing existing item IDs.

## Stone-head yield adjustment

`KnappBoltHeads` now makes four Stone Bolt Heads from one Sharp Flint Flake (`Base.SharpedStone`) instead of two. Its Flint Knapping 2 gate, 230 time, and 20 XP are unchanged. The extra yield lowers the flake cost of starting a Stone Bolt supply, while each finished bolt still needs one head, shaft, fletching material, and Twine use. The metal-head recipes and the Stone Bolt recovery chance are unchanged.

## Strip fletching alternative

The installed Build 42.20.4 `RipDenimClothing` recipe cuts denim or leather clothing with scissors or a sharp knife and produces `Base.DenimStrips` or `Base.LeatherStrips`. Both are normal material items in `media/scripts/generated/items/normal.txt`. Vanilla recipes use a bracketed list of item IDs as alternative inputs, including multi-item strip inputs. The four existing Auxilia assembly recipes now use that syntax to accept `Base.ChickenFeather`, `Base.TurkeyFeather`, `Base.DenimStrips`, or `Base.LeatherStrips` in one fletching slot. The explicit item list excludes dirty strips and Duct Tape. It also narrows the prior `base:feather` input to the two verified vanilla feather IDs, so mod-added feathers need explicit compatibility. Component counts, skill gates, timing, XP, published recipe/bolt IDs, and 70%/45% intact recovery rates are unchanged. Mixed fletching items in one five-bolt craft still require an in-game check.
