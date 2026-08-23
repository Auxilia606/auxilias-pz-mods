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

In debug mode, right-click any inventory item and choose **Auxilia's Crossbow: Spawn Test Kit**. The kit contains all three crossbows, 30 Metal Bolts, 30 Stone Bolts, Twigs, and a Sapling for dropped-model comparison.

Console/full-type IDs retain their pre-redesign names for save compatibility. They display as Light Crossbow, Crossbow, and Heavy Crossbow respectively:

- `AuxiliasCrossbow.ImprovisedCrossbow`
- `AuxiliasCrossbow.ReinforcedCrossbow`
- `AuxiliasCrossbow.HeavyArbalest`
- `Base.AuxiliasCrossbowBolt`
- `Base.AuxiliasStoneCrossbowBolt`
- `AuxiliasCrossbow.BrokenBolt`
- `AuxiliasCrossbow.BrokenStoneBolt`

## Acceptance checks

- In standing, aiming, firing, and reloading poses, both hands remain near the tiller and shallow bolt groove rather than the butt or prod.
- No crossbow is sideways, mirrored, oversized, or centered through the character.
- In the back hotbar slot, inspect the character from behind and both sides: the prod lies close to the back instead of pointing outward; repeat with a backpack equipped.
- Limb halves, string ends, shallow bolt groove, string nut, long tickler, tiller, embedded prod root, bridle strands, and fore-end rivet remain visibly connected from every camera direction.
- From the side, the wooden tiller ends at the prod joint rather than continuing beneath it; from the front, the prod root sits inside the fore-end and both nocks rise gently to the string/bolt axis just above the wood.
- The Standard dark-horn reinforcement and Heavy iron lock plates sit flush against the wooden tiller without a second plate edge appearing as a floating part below it.
- From above, the loaded bolt remains visibly continuous through the centre of the prod; the hemp/leather bridle stays outside the bolt groove.
- With no bolt loaded, the string runs straight between the relaxed limb tips and remains visible above the rail on all three crossbows.
- Loading one bolt bends the limbs rearward/inward, draws the unchanged-length string to the central catch, and places the selected Metal or Stone Bolt on the same power axis with the string touching only the rear face of its nock; no string segment penetrates the bolt or hides inside the tiller.
- Compare each loaded Metal and Stone Bolt with its dropped counterpart: shaft, nock, fletching, and point must keep the same proportions and dimensions on all three tiers, with only about 30 mm of the point projecting beyond the prod.
- Firing immediately removes the visible bolt and restores the relaxed limb and string model on the shot, rather than leaving the crossbow visibly cocked while empty.
- Unloading a bolt also restores the relaxed model, and re-equipping a loaded crossbow restores the cocked model.
- Equip each loaded crossbow and hold aim over standing and prone targets. The Build 42 firearm crosshair must appear, acquire valid targets at range, and allow the bolt to hit instead of showing the ordinary aimed-hand-weapon cursor.
- Fire immediately after equipping, then repeat in split-screen and multiplayer when available. Target selection, ammunition consumption, hit resolution, and remote shot synchronization must remain on the aimed-firearm path.
- Switch the Heavy Crossbow to Stone Bolts, load, and fire at both a target and empty ground. Neither shot may produce an `IsoBulletTracerEffects` error or return to the main menu.
- At night and inside an unlit room, fire every crossbow tier with both bolt materials. The shot must not create a muzzle-flash model or briefly illuminate the shooter and nearby tiles. Build 42's tracer may remain visible because its per-ammunition controller is not exposed to ordinary mod Lua. Immediately fire a vanilla firearm afterward and confirm its muzzle light still works.
- Drop each unloaded crossbow and repeat after loading both Metal and Stone Bolts: the tiller and both prod limbs rest top-side-up above the floor, with neither limb standing vertically or disappearing into the tile.
- A normally dropped Metal Bolt rests with its long axis across the ground, receives a non-central square offset, and gets randomized world rotation comparable to vanilla Twigs and Sapling; Place Item remains manually positioned by the player.
- Wood, metal, cord, and leather texture regions appear on the intended parts instead of an untextured white model.
- Each crossbow loads exactly one bolt and fires once before another reload.
- With an unloaded crossbow, the inventory context menu shows the selected material and switches between Metal and Stone Bolts.
- Pressing reload consumes the selected material, and unloading returns that same material without converting it.
- The three range limits are visibly different.
- Reload order is Light Crossbow, Crossbow, then Heavy Crossbow from fastest to slowest.
- Firing is dramatically quieter than a pistol.
- After hits, zombie and animal corpses contain an intact or broken bolt matching the loaded material.
- A Small Handle can be carved into exactly one Bolt Shaft.
- One Nail can be shaped into exactly one Metal Bolt Head.
- One Chipped Stone can be knapped into exactly two Stone Bolt Heads at Flint Knapping 2.
- One Iron or Steel Piece plus Charcoal can be forged into exactly two Metal Bolt Heads at a Primitive Forge with Blacksmith 2.
- The forging recipe is unavailable away from a Primitive Forge.
- The Heavy Crossbow recipe is unavailable away from an Advanced Forge and consumes one Crossbow, four Charcoal, and one Steel Bar Half.
- Crossbow construction consumes one Light Crossbow and requires both a Screwdriver and Pliers for its screws and wire.
- One Bolt Shaft, one matching Bolt Head, Twine, and one Chicken or Turkey Feather assemble exactly one bolt of that material.
- Duct Tape cannot replace the feather.
- Butchering a chicken or turkey supplies vanilla feathers usable by both bolt assembly recipes.
- One Broken Bolt yields one reusable head of its original material and never a complete bolt.
- Metal-head recovery requires Pliers, while Stone-head recovery requires a non-dull sharp knife; knapping tools and mallets cannot substitute for the knife.
- Both recovery recipes use the compact small-parts action rather than hammering the intact head or displaying a full-size spear prop.
- In a sufficiently large recovery sample, Metal Bolts approach 70% intact and Stone Bolts approach 45% intact.
- Crafting recipes unlock only when every listed skill requirement is met.
- Debug recipe-time and XP checks match `docs/VANILLA-RECIPE-ALIGNMENT.md`: `time = 600` for Light Crossbow and Crossbow, 900 for Heavy Crossbow, 230 for knapping, 200 for small forging, 100 for carving/assembly, and 60 for salvage with no XP.
- Survivor bags and barricaded/safehouse distributions very rarely contain a crossbow.
- Item names and recipe names change correctly between English and Korean.
- All ten dedicated mod icons have no black box, clipped edge, or missing texture and remain distinct from the 3D model textures.
- Stone Bolt Heads use their dedicated compact knapped-point artwork rather than the vanilla Sharp Flint Flake icon; complete and broken Stone Bolts have visibly broader pale stone heads and lighter fletching than their Metal counterparts in both inventory and world views.
- Neither Metal nor Stone Crossbow Bolts appear as valid inputs for vanilla **Gather Gunpowder**.
