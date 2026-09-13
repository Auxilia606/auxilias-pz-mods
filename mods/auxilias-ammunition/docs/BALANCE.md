# Balance

Times are in Build 42 recipe time units. Tools and fired molds are retained; tagged tools may
degrade. These tables describe the redesigned production contract; validate the implemented
scripts against them before release.

## Infrastructure and components

| Recipe | Station | Skills | Main consumed inputs | Output | Time |
|---|---|---|---|---:|---:|
| Shape bullet mold | Pottery Bench | Pottery 4 | Clay 3 | Unfired mold 1 | 180 |
| Fire bullet mold | Kiln | Pottery 4 | Unfired mold 1, fuel 2, ignition | Fired mold 1 | 40 |
| Shape shotgun mold | Pottery Bench | Pottery 5 | Clay 3 | Unfired mold 1 | 180 |
| Fire shotgun mold | Kiln | Pottery 5 | Unfired mold 1, fuel 2, ignition | Fired mold 1 | 40 |
| Small pistol body batch | Furnace | Blacksmith 5, Metalworking 5 | Iron ingot 1, copper scrap 1, charcoal 4 | 30 | 360 |
| Heavy pistol body batch | Furnace | Blacksmith 6, Metalworking 6 | Iron ingot 1, copper scrap 1, charcoal 5 | 20 | 400 |
| Rifle body batch | Furnace | Blacksmith 7, Metalworking 7 | Iron ingot 1, copper scrap 1, charcoal 6 | 15 | 450 |
| Shotgun body batch | Furnace | Blacksmith 6, Metalworking 7 | Iron ingot 1, copper scrap 1, ripped sheets 2, charcoal 5 | 15 | 450 |
| Crush mineral powder | Any surface | Foraging 3 | Stone or limestone 2, hammer (retained) | 40 | 180 |
| Grind carbon powder | Any surface | Reloading 3 | Charcoal or coke 8, mortar/pestle (retained) | 40 | 240 |
| Mix field powder | Any surface | Reloading 5, Blacksmith 5 | Mineral powder 40, carbon powder 40, mortar/pestle (retained) | 40 | 300 |
| Form primers | Hand Press | Metalworking 8, Reloading 6 | Mineral powder 10, carbon powder 10, copper scrap 1 | 30 | 450 |

The two powder inputs are a fictional ammo-only game abstraction. Charcoal and vanilla coke
share the `base:charcoal` tag; no `Base.Coal` item is assumed. Mineral powder retains the
published `MineralSalts` ID, and field powder retains `SurvivalPropellant`.

## Legacy-part conversion

The four former casing/hull recipe IDs are now one-for-one Hand Press conversions for
previously saved parts. Each consumes one matching projectile/charge and casing/hull, and
produces one body. They take 45 time units and award 1 Metalworking XP per item.

| Old pair | New body | Metalworking |
|---|---|---:|
| Small pistol projectile + casing | Small pistol body | 5 |
| Heavy pistol projectile + casing | Heavy pistol body | 6 |
| Rifle projectile + casing | Rifle body | 7 |
| Shot charge + shotgun hull | Shotgun body | 7 |

## Final assembly

Every row consumes ten bodies and ten factory or improvised primers. Factory primers and
improvised primers are alternatives, never combined.

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

One mineral-powder batch and one carbon-powder batch support one 40-unit field-powder batch;
primers require another ten of each powder per 30-unit batch. Ten common pistol rounds use
one quarter of a field-powder batch; ten .308 or shotgun rounds use one half. One body batch
always consumes one iron ingot and one copper scrap. Rifle and shotgun yields are only 15,
creating material remainders and discouraging instant mass production. Charcoal or coke is
still consumed in body casting and powder grinding, so fuel production remains a constraint.

Looted factory ammunition remains superior: it costs no high-level labor, fuel, metal, stone,
or station time. Factory primers are valuable but do not bypass body manufacture, field
powder, skill, or workstation requirements.
