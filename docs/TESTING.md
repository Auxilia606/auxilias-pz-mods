# Test procedure — Project Zomboid 42.20

## Install

Copy the repository's `workshop` folder to:

`C:\Users\USER\Zomboid\Workshop\AuxiliasCrossbow`

Alternatively, extract the test-build zip so that `workshop.txt`, `preview.png`, and `Contents` sit directly inside that folder.

The final local path must contain:

`Contents\mods\AuxiliasCrossbow\42.20\mod.info`

## Enable

1. Start Project Zomboid 42.20 with debug mode enabled.
2. Open **Mods**, enable **Auxilia's Crossbow**, and restart if prompted.
3. Create a fresh single-player sandbox save for the cleanest loot test.

## Spawn the test kit

In debug mode, right-click any inventory item and choose **Auxilia's Crossbow: Spawn Test Kit**. The kit contains all three crossbows and 60 Standard Bolts.

Console/full-type IDs are:

- `AuxiliasCrossbow.ImprovisedCrossbow`
- `AuxiliasCrossbow.ReinforcedCrossbow`
- `AuxiliasCrossbow.HeavyArbalest`
- `Base.AuxiliasCrossbowBolt`
- `AuxiliasCrossbow.BrokenBolt`

## Acceptance checks

- Each crossbow loads exactly one bolt and fires once before another reload.
- The three range limits are visibly different.
- Reload order is Improvised, Reinforced, then Heavy Arbalest from fastest to slowest.
- Firing is dramatically quieter than a pistol.
- After hits, zombie and animal corpses contain either an intact or broken bolt.
- Crafting recipes unlock only when every listed skill requirement is met.
- Survivor bags and barricaded/safehouse distributions very rarely contain a crossbow.
- Item names and recipe names change correctly between English and Korean.
