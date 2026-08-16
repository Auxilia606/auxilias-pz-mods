# 42.20.2 smoke-test report

Date: 2026-08-16

The repository build was copied into an isolated Project Zomboid cache and loaded by the locally installed 42.20.2 dedicated server in no-Steam mode.

Verified:

- The game discovered and loaded mod ID `AuxiliasCrossbow`.
- The custom bolt ammo registry initialized without an exception.
- All three custom weapon model references passed script validation.
- The server reached `*** SERVER STARTED ****`.
- No errors in the final server log referenced Auxilia's Crossbow.
- The generated crafting index contained:
  - `MakeImprovisedCrossbow`
  - `MakeReinforcedCrossbow`
  - `MakeHeavyArbalest`
  - `MakeStandardBolts`
  - `SalvageBrokenBolts`

Follow-up interactive playtesting confirmed that all three crossbows work in game and that bolt generation occurs as intended. The 0.1.0 single-player playtest milestone is complete.

## Post-0.1.0 model-pipeline recheck

Date: 2026-08-16

After rebuilding the three crossbow meshes, Blender 5.2 successfully exported and re-imported all five FBX assets. Each FBX retained one mesh, one UV layer, material slots, and its source dimensions. Isometric, top, and side renders passed the geometry checklist in `docs/MODELING.md`.

The rebuilt mod was then copied into an isolated cache and loaded by both the Project Zomboid 42.20.2 dedicated server and client. The server reached `*** SERVER STARTED ****` with no Auxilia model, texture, script, registry, or Lua errors.

An isolated client debug scenario then equipped and cycled Improvised Crossbow, Reinforced Crossbow, and Heavy Arbalest. All three FBX assets resolved without load errors and were visible at long-gun scale in idle and aimed poses. The client check caught and fixed the Build 42 integration details that static validation could not detect: model scripts must use `module Base`, `WeaponSprite` values must be unqualified, FBX unit scale must be `0.01`, and Blender must export with `-Y` forward / `Z` up. The final models follow the character's aim direction instead of appearing oversized, invisible, or vertical.

## Development smoke test — bolt crafting overhaul

The post-0.1.0 bolt-crafting changes were loaded from a fresh isolated cache by the locally installed 42.20.2 dedicated server in no-Steam mode.

Verified:

- The server loaded mod ID `AuxiliasCrossbow` and reached `*** SERVER STARTED ****`.
- `AuxiliasCrossbow.BoltShaft` and `AuxiliasCrossbow.BoltHead` were registered as loaded mod items.
- The generated crafting index contained each of the seven current recipes exactly once:
  - `MakeImprovisedCrossbow`
  - `MakeReinforcedCrossbow`
  - `MakeHeavyArbalest`
  - `CarveBoltShaft`
  - `ShapeBoltHead`
  - `MakeStandardBolts`
  - `SalvageBrokenBolts`
- No server-log error or warning referenced Auxilia's Crossbow.

Interactive verification of the new recipe inputs and outputs remains part of the acceptance procedure in `docs/TESTING.md`.

## Development smoke test — Flint Knapping and Blacksmith paths

The skill-specific Bolt Head recipes were loaded from a fresh isolated cache by the locally installed 42.20.2 dedicated server in no-Steam mode.

Verified:

- The server loaded mod ID `AuxiliasCrossbow` and reached `*** SERVER STARTED ****`.
- `KnappBoltHeads` and `ForgeBoltHeads` were accepted by the Build 42 crafting parser.
- The generated crafting index contained each of the nine current recipes exactly once.
- No server-log error or warning referenced Auxilia's Crossbow.

Interactive verification of the Primitive Forge proximity condition, tool handling, skill gates, and exact output quantities remains part of the acceptance procedure in `docs/TESTING.md`.

## Development smoke test — item icon rebuild

The Blender asset pipeline rendered all seven item icons at 128×128 with transparent backgrounds and automated bounds checks. Each icon retained at least 13 pixels of canvas margin for the crossbows and at least 21 pixels for the bolt components, with no clipped or empty output.

The rebuilt icons were then loaded in an isolated Project Zomboid 42.20.2 client inventory. Verified:

- Improvised Crossbow, Reinforced Crossbow, and Heavy Arbalest use their matching tier silhouettes.
- Standard Bolt and Broken Bolt remain visually distinct at inventory scale.
- Bolt Shaft and Bolt Head use dedicated mod icons instead of the vanilla Handle and Nails icons.
- All seven icon names resolve without missing-texture errors.

## Development smoke test — material-specific bolts and feather fletching

The Stone/Metal ammunition split was copied into a fresh isolated cache and loaded by the locally installed Project Zomboid 42.20.2 dedicated server in no-Steam mode.

Verified:

- Both `auxiliascrossbow:bolt` and `auxiliascrossbow:stonebolt` ammo registries initialized without an exception.
- `Base.AuxiliasStoneCrossbowBolt`, `AuxiliasCrossbow.StoneBoltHead`, and `AuxiliasCrossbow.BrokenStoneBolt` appeared in generated server output.
- The generated crafting index contained each of the eleven current recipes exactly once, including `MakeStoneBolt` and `SalvageBrokenStoneBolt`.
- Both assembly recipes require the vanilla `base:feather` tag, which is present on Chicken and Turkey Feathers supplied by Build 42 animal butchering.
- The server reached `*** SERVER STARTED ****` with no Auxilia-related error or warning.

The initial check detected and corrected an invalid Stone Bolt Head world-model reference (`Base.SharpedStone`); the clean rerun used the vanilla `ChippedStone` model. Inventory-context ammunition switching, normal reload/unload preservation, material-specific hit recovery, and statistical recovery rates remain interactive client checks in `docs/TESTING.md`.

## Development smoke test — stable 42.20.2 recipe alignment

The final recipe rebalance was copied into a fresh isolated cache and loaded by the locally installed Project Zomboid stable 42.20.2 dedicated server in no-Steam mode.

Verified:

- The server loaded mod ID `AuxiliasCrossbow` and reached `*** SERVER STARTED ****`.
- The crafting parser accepted the `AdvancedForge` Heavy Arbalest recipe, its `Base.SteelBarHalf` and charcoal inputs, and the revised hand-tool requirements.
- The generated crafting index contained each of the eleven current Auxilia recipes exactly once.
- No server-log error or warning referenced Auxilia's Crossbow.
- Static validation confirmed the documented time units, materials, tools, skill gates, and XP awards for all eleven recipes.

Real elapsed duration varies with the game's timed-action and character modifiers. Player-observed duration, consumed quantities, and granted XP remain covered by the interactive checks in `docs/TESTING.md`.

## Development smoke test — compact three-tier redesign

The Light Crossbow, Crossbow, and Heavy Crossbow redesign was copied over the existing isolated 42.20.2 client session without deleting its save. Blender regenerated and round-tripped all FBX assets as one mesh, one material, and one UV layer. The three equipped models measure 0.363 units long, matching the approximate 0.357-unit vanilla sawn-off double-barrel shotgun reference.

Verified:

- The crafting index contains `MakeLightCrossbow`, `MakeCrossbow`, and `MakeHeavyCrossbow` exactly once.
- No client error or warning references the new Auxilia model, recipe, item, translation, or texture data.
- Game-native and direct-window aim captures show all three prods facing forward with the tillers below the character's forearms and no large grip or mechanism intersecting the torso.
- Light Crossbow is predominantly wood, Crossbow combines a wooden tiller with iron fittings and a steel prod, and Heavy Crossbow uses an iron tiller with the thickest steel prod.
- The existing internal item IDs remain unchanged for save compatibility while English and Korean display names use the new three-tier terminology.

A follow-up visual pass compared six vanilla firearm meshes around their hand/action area and sampled four vanilla wood-stock textures. The exact sawn double-barrel support-hand body is approximately 0.016 units wide and sits above Z 0.001. The revised crossbows use a 0.024–0.028 rear tiller, a 0.020–0.024 lock, and a continuous 0.016–0.020 support-hand body lifted above Z 0. The primary oak atlas swatch remains near the vanilla target of sRGB 121/58/7. Close left- and right-facing aim captures confirm that the supporting palm now wraps below the tiller instead of emerging through a deep body block.

The prod follow-up removes the former zigzag and reversed tip segment. All three prods now sweep smoothly and continuously rearward, taper through seven sections, and meet a shallower central socket. Updated left- and right-facing client captures show a readable conventional bow silhouette without hooked tips or a clamp-like center.

Firing, projectile behavior, and practical balance remain reserved for the user's final interactive test.
