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

In debug mode, right-click any inventory item and choose **Auxilia's Crossbow: Spawn Test Kit**. The kit contains all three crossbows, 30 Metal Bolts, and 30 Stone Bolts.

Console/full-type IDs are:

- `AuxiliasCrossbow.ImprovisedCrossbow`
- `AuxiliasCrossbow.ReinforcedCrossbow`
- `AuxiliasCrossbow.HeavyArbalest`
- `Base.AuxiliasCrossbowBolt`
- `Base.AuxiliasStoneCrossbowBolt`
- `AuxiliasCrossbow.BrokenBolt`
- `AuxiliasCrossbow.BrokenStoneBolt`

## Acceptance checks

- In standing, aiming, firing, and reloading poses, both hands remain near the stock/grip rather than the butt or prod.
- No crossbow is sideways, mirrored, oversized, or centered through the character.
- Limb halves, string ends, rail, stock, stirrup, braces, and windlass remain visibly connected from every camera direction.
- Dropped/world models rest near the ground and keep the same orientation family as vanilla long guns.
- Wood, metal, cord, and leather texture regions appear on the intended parts instead of an untextured white model.
- Each crossbow loads exactly one bolt and fires once before another reload.
- With an unloaded crossbow, the inventory context menu switches between Metal and Stone Bolts.
- Pressing reload consumes the selected material, and unloading returns that same material without converting it.
- The three range limits are visibly different.
- Reload order is Improvised, Reinforced, then Heavy Arbalest from fastest to slowest.
- Firing is dramatically quieter than a pistol.
- After hits, zombie and animal corpses contain an intact or broken bolt matching the loaded material.
- A Small Handle can be carved into exactly one Bolt Shaft.
- One Nail can be shaped into exactly one Metal Bolt Head.
- One Chipped Stone can be knapped into exactly two Stone Bolt Heads at Flint Knapping 2.
- One Iron or Steel Piece plus Charcoal can be forged into exactly two Metal Bolt Heads at a Primitive Forge with Blacksmith 2.
- The forging recipe is unavailable away from a Primitive Forge.
- The Heavy Arbalest recipe is unavailable away from an Advanced Forge and consumes four Charcoal plus one Steel Bar Half.
- Reinforced Crossbow construction requires both a Screwdriver and Pliers for its screws and wire.
- One Bolt Shaft, one matching Bolt Head, Twine, and one Chicken or Turkey Feather assemble exactly one bolt of that material.
- Duct Tape cannot replace the feather.
- Butchering a chicken or turkey supplies vanilla feathers usable by both bolt assembly recipes.
- One Broken Bolt yields one reusable head of its original material and never a complete bolt.
- In a sufficiently large recovery sample, Metal Bolts approach 70% intact and Stone Bolts approach 45% intact.
- Crafting recipes unlock only when every listed skill requirement is met.
- Debug recipe-time and XP checks match `docs/VANILLA-RECIPE-ALIGNMENT.md`: `time = 600` for the two wooden crossbow builds, 900 for the Heavy Arbalest, 230 for knapping, 200 for small forging, 100 for carving/assembly, and 60 for salvage with no XP.
- Survivor bags and barricaded/safehouse distributions very rarely contain a crossbow.
- Item names and recipe names change correctly between English and Korean.
- The original seven mod items retain their dedicated icons with no black box, clipped edge, or missing texture.
- Stone Bolt Heads use the recognizable vanilla chipped-stone artwork; material-specific bolts and broken bolts have correct names even where they share the same world silhouette.
