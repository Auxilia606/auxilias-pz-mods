# Balance

Times are in Build 42 recipe time units. The new tabletop press and hand tools are retained;
tagged tools may degrade. These tables describe the redesigned production contract; validate
the implemented scripts and station placement in game before release.

## Infrastructure and components

| Recipe | Station | Skills | Main consumed inputs | Output | Time |
|---|---|---|---|---:|---:|
| Craft tabletop press | Any surface | Carpentry 3, Blacksmith 4 | Planks 3, iron bar 1, iron bands 2, small sheet metal 1, nails 6; kept hammer and saw | 1 | 300 |
| Small pistol body batch | Tabletop press | Blacksmith 5, Metalworking 5 | Iron ingot 1, copper scrap 1, kept pliers | 30 | 360 |
| Heavy pistol body batch | Tabletop press | Blacksmith 6, Metalworking 6 | Iron ingot 1, copper scrap 1, kept pliers | 20 | 400 |
| Rifle body batch | Tabletop press | Blacksmith 7, Metalworking 7 | Iron ingot 1, copper scrap 1, kept pliers | 15 | 450 |
| Shotgun body batch | Tabletop press | Blacksmith 6, Metalworking 7 | Iron ingot 1, copper scrap 1, ripped sheets 2, kept pliers | 15 | 450 |
| Crush mineral powder | Any surface | Foraging 3 | Stone or limestone 2, hammer (retained) | 40 | 180 |
| Grind carbon powder | Any surface | None | Wood charcoal, charcoal, or coke 8; mortar/pestle (retained) | 40 | 240 |
| Prepare nitrogenous mix from compost | Any surface | Farming 3 | Compost bag 2 uses (50% of a full bag), mortar/pestle (retained) | 1 | 240 |
| Prepare nitrogenous mix from NPK fertilizer | Any surface | Farming 3 | Fertilizer 2 uses (25% of a full bag), mortar/pestle (retained) | 1 | 180 |
| Mix field powder | Any surface | Reloading 5, Blacksmith 5 | Mineral powder 40, carbon powder 40, nitrogenous mix 1, mortar/pestle (retained) | 40 | 300 |

The three field-powder inputs are a fictional ammo-only game abstraction. The carbon
recipe explicitly accepts `Base.CharcoalCrafted` (Wood Charcoal), `Base.Charcoal`, and
`Base.Coke` rather than relying on a tag label in the crafting UI. It requires no skill
level and awards no Reloading XP. No `Base.Coal` item is assumed. Mineral powder retains the
published `MineralSalts` ID, and field powder retains `SurvivalPropellant`. The new
`NitrogenousMix` can be prepared from either vanilla `Base.CompostBag` or `Base.Fertilizer`.
Compost comes from rotten food or picked-up animal dung processed in a vanilla composter.
Native drainable input amounts count uses, not whole bags: `Base.CompostBag` has four uses
(25% each) and becomes `Base.EmptySandbag` on depletion; `Base.Fertilizer` has eight uses
(12.5% each) and has no replacement item defined. A full bag therefore supports two or
four field-powder batches respectively. The two nitrogenous-mix preparation recipes are
skill-gated but do not require a manual.

## Final assembly

Every row consumes ten bodies and the listed amount of field powder.

| Output | Body family | Field powder | Reloading | Time | Batch |
|---|---|---:|---:|---:|---:|
| 9mm | Small pistol | 10 | 5 | 300 | 10 |
| .38 Special | Small pistol | 10 | 5 | 300 | 10 |
| .357 Magnum | Small pistol | 15 | 6 | 330 | 10 |
| .45 Auto | Large pistol | 12 | 6 | 330 | 10 |
| .44 Magnum | Large pistol | 16 | 7 | 360 | 10 |
| 5.56mm | Rifle | 16 | 7 | 390 | 10 |
| .30-30 | Rifle | 18 | 8 | 420 | 10 |
| .308 | Rifle | 20 | 8 | 450 | 10 |
| Shotgun shells | Shotgun body | 20 | 7 | 420 | 10 |

## Economy intent

One mineral-powder batch, one carbon-powder batch, and one nitrogenous-mix unit support one
40-unit field-powder batch. Ten common pistol rounds use one quarter of a field-powder
batch; ten .308 or shotgun rounds use one half. One body batch
always consumes one iron ingot and one copper scrap. Rifle and shotgun yields are only 15,
creating material remainders and discouraging instant mass production. Wood charcoal,
charcoal, or coke is consumed during carbon-powder grinding, while the hand press itself
needs no fuel.

Looted factory ammunition remains superior: it costs no high-level labor, fuel, metal, stone,
or station time.
