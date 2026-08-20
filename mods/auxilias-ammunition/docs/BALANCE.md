# Balance

Times are in Build 42 recipe time units. Tools and fired molds are retained; tagged tools may
degrade. The tables are the release balance contract and are also checked structurally by the
validator.

## Infrastructure and components

| Recipe | Station | Skills | Main consumed inputs | Output | Time |
|---|---|---|---|---:|---:|
| Shape bullet mold | Pottery Bench | Pottery 4 | Clay 3 | Unfired mold 1 | 180 |
| Fire bullet mold | Kiln | Pottery 4 | Unfired mold 1, fuel 2, ignition | Fired mold 1 | 40 |
| Shape shotgun mold | Pottery Bench | Pottery 5 | Clay 3 | Unfired mold 1 | 180 |
| Fire shotgun mold | Kiln | Pottery 5 | Unfired mold 1, fuel 2, ignition | Fired mold 1 | 40 |
| Small projectile batch | Furnace | Blacksmith 5 | Iron ingot 1, charcoal 4 | 30 | 300 |
| Heavy projectile batch | Furnace | Blacksmith 6 | Iron ingot 1, charcoal 5 | 20 | 330 |
| Rifle projectile batch | Furnace | Blacksmith 7 | Iron ingot 1, charcoal 6 | 15 | 360 |
| Shot charge batch | Furnace | Blacksmith 6 | Iron ingot 1, charcoal 5 | 20 | 330 |
| Small casing batch | Hand Press | Metalworking 5 | Copper scrap 1 | 30 | 240 |
| Heavy casing batch | Hand Press | Metalworking 6 | Copper scrap 1 | 20 | 270 |
| Rifle casing batch | Hand Press | Metalworking 7 | Copper scrap 1 | 15 | 300 |
| Shotgun hull batch | Hand Press | Metalworking 7 | Copper scrap 1, ripped sheets 2 | 15 | 300 |
| Process mineral salts | Pottery Bench | Farming 6, Foraging 5 | Compost use 1, limestone 1, charcoal 2 | 20 | 500 |
| Blend propellant | Charcoal station | Farming 7, Blacksmith 5 | Salts 20, charcoal 8 | 40 | 500 |
| Form primers | Hand Press | Metalworking 8, Reloading 6 | Salts 10, copper 1, charcoal 4 | 30 | 450 |

## Final assembly

Every row consumes ten projectiles/charges, ten casings/hulls, and ten factory or improvised
primers. Factory primers and improvised primers are alternatives, never combined.

| Output | Projectile family | Propellant | Reloading | Time | Batch |
|---|---|---:|---:|---:|---:|
| 9mm | Small pistol | 10 | 5 | 300 | 10 |
| .38 Special | Small pistol | 10 | 5 | 300 | 10 |
| .357 Magnum | Small pistol | 15 | 6 | 330 | 10 |
| .45 Auto | Large pistol | 12 | 6 | 330 | 10 |
| .44 Magnum | Large pistol | 16 | 7 | 360 | 10 |
| 5.56mm | Rifle | 16 | 7 | 390 | 10 |
| .30-30 | Rifle | 18 | 8 | 420 | 10 |
| .308 | Rifle | 20 | 8 | 450 | 10 |
| Shotgun shells | Shot charge | 20 | 7 | 420 | 10 |

## Economy intent

One salts batch supports one propellant batch, while primers consume an additional half-batch.
Thus propellant and primer infrastructure must operate together. Ten common pistol rounds use
one quarter of a propellant batch; ten .308 or shotgun rounds use one half. Rifle casting and
casing yields are only 15 per ingot/scrap, creating material remainder and discouraging instant
mass production. Charcoal is demanded at every upstream stage, making logging, burn time, kiln
fuel, and workstation throughput meaningful constraints.

Looted factory ammunition remains superior: it costs no high-level labor, charcoal, metal,
compost, or station time. Factory primers are valuable but do not bypass projectile, casing,
propellant, skill, or workstation requirements.
