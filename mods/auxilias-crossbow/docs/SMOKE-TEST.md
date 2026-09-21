# Build 42.20 compatibility and smoke-test report

## Recipe balance and drill alternatives — Build 42.20.4

Date: 2026-09-17

The updated mod was copied into an isolated cache and loaded by the locally installed Build 42.20.4 dedicated server in no-Steam mode. The server discovered `AuxiliasCrossbow`, parsed the fourteen crafting recipes, and reached `*** SERVER STARTED ****`. No script-load error or mod-specific exception appeared in the final server log.

The first load exposed a duplicate `Prop2` assignment in `MakeHeavyCrossbow` (Tongs and the consumed Crossbow). Removing `Prop2` from the Crossbow input fixed the parser error; `InheritCondition` remains on that input. Repository-wide validation passed after the correction.

The server smoke test verifies loading and recipe syntax. Exact ingredient consumption, batch outputs, automatic learning, loaded-weapon rejection, and condition/ammunition inheritance still require the interactive checks in `docs/TESTING.md`.

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

## Development smoke test — Metal Bolt icon and dropped model

Date: 2026-08-17

The rebuilt Metal Bolt was exported and re-imported through Blender, then loaded in an isolated Project Zomboid 42.20.2 debug client. Its world model measures approximately 0.032 × 0.277 × 0.032 units. Against the 0.363-unit crossbows, the bolt is 76.3% as long, reduced from the previous 89.7% proportion.

The client dropped one Metal Bolt, one vanilla Twigs item, and one vanilla Sapling through the same normal inventory Drop path on the same square. The resulting world positions and Z rotations were:

- Metal Bolt: offset 0.173, 0.631, 0.000; rotation 195°
- Twigs: offset 0.446, 0.343, 0.000; rotation 233°
- Sapling: offset 0.222, 0.856, 0.000; rotation 323°

The Metal Bolt therefore follows the same engine-randomized square offset and world rotation behavior as the two vanilla references instead of appearing fixed at the tile center. This first comparison established position and Z-rotation behavior but did not clearly expose the model's vertical long-axis error at the nighttime test scale.

A subsequent daylight screenshot of a player-dropped stack showed the weapon-axis FBX standing upright like a group of spikes. The world attachment was corrected with a 90° X-axis rotation and ground-contact pivot. A clean follow-up dropped twelve Metal Bolts on one square; all twelve received distinct offsets and rotations from 3° through 343° and visibly lay across the ground in different directions instead of standing vertically. No Auxilia-related model, texture, script, or Lua error occurred during the corrected run.

## Final single-player integration acceptance

Date: 2026-08-17

The project owner completed the full interactive procedure in `docs/TESTING.md`. The accepted scope covers ammunition selection and reload/unload material preservation, one-shot firing, range/reload/noise progression, zombie and animal recovery, material-specific recovery rates, all crafting inputs and outputs, workstation and skill restrictions, XP/timing behavior, rare loot, icons, and English/Korean presentation.

## 0.2.0 material-identification and release-pipeline check

Date: 2026-08-17

Blender 5.2 regenerated and round-tripped seven FBX assets, including dedicated Stone Bolt and Broken Stone Bolt models. Both complete bolts retain the compact 0.28-unit length and ground-placement orientation, while the Stone variants use broader pale chipped heads and lighter fletching. All nine generated 128×128 icons passed transparency, bounds, margin, and coverage checks.

The release validator passed 38 required-file checks and all six English/Korean translation files with exact key parity. A clean-deployment test inserted an obsolete sentinel into an existing test install, redeployed through the staged tree swap, and confirmed that the stale file was removed while all 48 source and destination files matched. A package-audit ZIP then matched every current workshop file by path, length, and SHA-256 hash.

The clean 0.2.0 candidate was then loaded by the installed 42.20.2 dedicated server in no-Steam mode. The server loaded `AuxiliasCrossbow`, accepted all eleven recipes, reached `*** SERVER STARTED ****`, and shut down cleanly. The final server log contains no Auxilia-related error or warning; unrelated vanilla Build 42 warnings remain unchanged from the earlier isolated runs.

## Development smoke test — fixed-length crossbow states and dedicated icons

Date: 2026-08-17

Blender 5.2 regenerated and round-tripped ten FBX assets: relaxed and cocked variants of all three crossbows plus the four intact/broken bolt models. Top, side, and isometric renders confirm that relaxed strings remain visible above the rail and cocked strings draw to an exposed central catch while the limbs bend rearward and inward.

The generated physics report measures the same string length in both states to within `0.00000001` units. Sampled relaxed/cocked limb-length drift remains below `0.00009` units, inside the `0.0002` validation tolerance. Generation and static validation fail if either length changes beyond tolerance, if the cocked tips fail to move rearward, or if the catch is not behind the tips.

The rebuilt mod was copied into a fresh isolated 42.20.2 dedicated-server cache. The server loaded `AuxiliasCrossbow`, registered all eleven Auxilia recipes exactly once, reached `*** SERVER STARTED ****`, and shut down cleanly. No Auxilia-related error or warning appeared in the server log.

An isolated 42.20.2 client cache then loaded `AuxiliasCrossbow` through the main-menu asset and Lua initialization path. All six crossbow model definitions, ten dedicated icons, and the ammo-state client script were present; no Auxilia-related model, texture, script, or Lua error appeared. The final client-load rerun also covered the fired-weapon latch that holds the relaxed model through delayed ammo synchronization and repeats the release at `OnPlayerAttackFinished`.

With the project owner's approval, the most recent Apocalypse save was copied to a separate `AuxiliaRuntimeSmoke` save and loaded in the installed 42.20.2 client. The temporary runtime harness resolved all ten item icon mappings to dedicated 128×128 textures, including `AuxiliaStoneBoltHead`, and then equipped every crossbow tier. Light, standard, and heavy variants each passed the complete `relaxed -> cocked -> fired/relaxed` sprite sequence. State captures and the client log confirmed that the standard and heavy equipped models are visible in-world, select their cocked model when ammunition is present, and immediately return to the relaxed model after the firing event. The harness restored the character's original hand items before reporting `PASS`; the temporary save and harness were removed after the check.

## Stone Bolt tracer crash regression

Date: 2026-08-17

A user playtest exposed a Build 42 engine `NullPointerException` when the Heavy Crossbow fired after switching to Stone Bolts. The firing stack reached `IsoBulletTracerEffects.createEffect`, where the Stone Bolt `AmmoType` had no tracer configuration. Metal Bolts did not fail because all three weapon scripts reference the metal type by default, causing `Item.resolveItemTypes()` to initialize it. The Stone Bolt type was previously reachable only through the runtime inventory selector and therefore missed that initialization path.

Both bolt item definitions now self-reference their registered `AmmoType`. This makes Build 42 initialize tracer configuration for both material paths during normal item resolution without restoring the invalid `base:ammo` tag. Static validation enforces the two item-to-registry mappings.

The corrected build was then loaded from a separate copy of the most recent Apocalypse save. A temporary harness equipped a Heavy Crossbow, selected `auxiliascrossbow:stonebolt`, and set one loaded round. A real mouse aim/fire input passed through `CombatManager`, reached the weapon hit-point event, completed the attack, consumed the round from one to zero, and restored `AuxiliaHeavyArbalest`. No `IsoBulletTracerEffects`, `NullPointerException`, or `IngameState.updateInternal` error occurred, and the client remained running. The temporary save and harness were removed after the check.

## 2026-08-18 — Recovery prop and hotbar icon regression

The recovery recipes previously reused vanilla `CraftKnifeSpear`, whose timed-action definition forces the full-size `Base.SpearKnife` prop. The first replacement used a custom timed-action name with the generic `Making` animation, but an interactive retest still presented a spear-like knife-removal motion. The final fix removes `CraftKnifeSpear` from every Auxilia recipe: Metal assembly and recovery use vanilla `MakingJewellery`, Stone assembly uses the same compact-parts motion, and Stone recovery uses `HammerStoneStanding`. Recipe props are the selected tool and the actual broken bolt or compact bolt shaft. The broken model lengths are approximately 20.0 cm and 21.7 cm respectively, rather than spear length.

Build 42's `ISHotbar` uses 60-pixel slots but draws each item texture at native size. All ten independent hand-painted 128×128 masters are now downsampled to distinct transparent 32×32 runtime textures; the installed files were checked at 32×32, placing each texture entirely within one slot under the vanilla render calculation. Static validation passed with 47 required files and six translation files.

## 2026-08-23 — Aimed-firearm path regression and effect redesign

A player report exposed a regression introduced by the firearm-effect workaround: all three crossbows had changed from `IsAimedFirearm = true` to `false`. Build 42.20.2 bytecode inspection confirmed that this flag gates more than presentation. `CombatManager` uses it for ballistics target calculation, `fireWeapon()`, shot statistics, and multiplayer shot notification, while `IsoPlayer` uses it for the firearm aiming path. Calling `IsoPlayer.updateBallistics()` from `OnPlayerUpdate` cannot reproduce those call sites, so the crossbows displayed the ordinary aimed-hand-weapon cursor and could not reliably hit ranged targets.

The redesign restores `IsAimedFirearm = true` on every crossbow. A shot hook snapshots existing cell lights before `CombatManager` creates its hard-coded radius-18 muzzle light; the subsequent `OnTick`, which runs after combat update and before rendering, expires only a newly added matching light at that shooter's tile. The item scripts continue to omit `MuzzleFlashModelKey`, so the engine has no flash model to render.

The first implementation also called `IsoBulletTracerEffects.getInstance()` to set the dedicated Metal and Stone Bolt tracer alpha values to zero. A client test on 2026-08-23 produced `attempted index: getInstance of non-table: null` at game start and again on firing. Inspection of `LuaManager.Exposer` confirmed that Build 42.20.2 exposes the separate `FBORenderTracerEffects` class but not the `IsoBulletTracerEffects` class actually used by `CombatManager`. The invalid call and all tracer mutation were removed. The bright engine tracer remains an accepted limitation so the firearm aiming and hit path can stay intact. Static validation now rejects any direct `IsoBulletTracerEffects` reference as well as the former per-frame `setAngleFromAim()` / `updateBallistics()` workaround. The resulting interactive client checks are recorded in the 42.20.3 acceptance section below.

## 2026-08-23 — Build 42.20.3 compatibility acceptance

An isolated dedicated-server run on Project Zomboid 42.20.3 revision `70207f62e0`
loaded `AuxiliasCrossbow`, reached `*** SERVER STARTED ****`, shut down normally, and
reported no Auxilia-related warning or error.

The project owner then completed the outstanding 42.20.3 client and multiplayer checks
in `docs/TESTING.md`. All three crossbows retained the aimed-firearm targeting and hit
path; firing, Metal/Stone ammunition switching, unloading, and material-matched bolt
recovery passed. Night and unlit-room shots produced neither a muzzle-flash model nor
the radius-18 muzzle light, while a vanilla firearm fired immediately afterward retained
its normal muzzle light. Stone Bolt shots produced no `IsoBulletTracerEffects` error,
and remote firing preserved target selection, ammunition consumption, hit resolution,
and shot synchronization. The existing-save compatibility check also passed.

This completes the 42.20.3 compatibility gate. No runtime code, item/recipe ID, mod
version, or `42.20` distribution-directory change is required for the hotfix.

## 2026-09-16 — Authored Blender assets on Build 42.20.4

The existing Blender source was split into editable linked parts and refined for
all three crossbows. The new exporter preserved that source and round-tripped all
thirteen FBX files, checking triangle positions, winding and UVs within 0.000001.
Every model has one mesh/material/UV layer and zero collapsed UV triangles. Packed,
external-source and runtime atlas hashes match. Root validation passed for all
three registered mods; a local crossbow ZIP passed the full file-content audit.

An isolated 42.20.4 client loaded the new graphics. Actual mouse aim/fire input
passed for Light, standard and Heavy crossbows with both Metal and Stone Bolts.
All six combinations reached the attack-finished event with zero ammunition and
the appropriate relaxed sprite; no Auxilia-related exception or crash occurred.
The test harness only ran in the ignored client cache and is absent from the
Workshop tree. Damage, accuracy and multiplayer acceptance were outside this
graphics check. See [the Blender review](BLENDER-REVIEW-2026-09-16.md) for counts,
evidence paths and visual-check scope.

## 2026-09-17 — Bolt family and crafting components

Refined the existing authored bolt meshes and all six linked loaded states, shortened
both broken fragments with integral fractures, and added canonical shaft/head models
for the three existing crafting components. All sixteen FBX files passed source
triangle/UV/winding comparison. Stock/groove clearance and linked component checks
passed; the prior 393 crossbow body/limb/string parts remained exactly unchanged.
Root validation passed for all three mods and the local candidate package passed its
file-content audit. See [the bolt-family review](BOLT-FAMILY-REVIEW-2026-09-17.md).

This is an offline asset check. The updated bolts and new crafting props have not yet
been rechecked in a client; the September 16 client evidence covers the earlier assets.

## 2026-09-20 — 0.2.1 release-candidate interactive acceptance

The project owner tested the audited 0.2.1 candidate on Project Zomboid 42.20.4.
Clean load and registration, all refreshed model/state transitions, ranged combat and
firearm-effect suppression, tiered reload behavior, every changed crafting path,
existing-save persistence, icons, and English/Korean presentation passed. Exact reload
durations and the mixed-fletching resolution were not recorded, but their acceptance
sections were reported as passed.

One required check failed. A bolt did not remain in a hit zombie's body inventory, and
animal recovery could not be confirmed; the tester observed that the animal lifecycle
may not expose a persistent target inventory suitable for this design. The current
server handler adds the intact or broken result to `hitObject:getInventory()` during
`OnWeaponHitXp`, so target-to-corpse transfer and animal loot persistence now require a
separate implementation investigation.

The complete report is in `RELEASE-TEST-0.2.1.md`. Version 0.2.1 remains a release
candidate and must not be tagged until recovery is corrected or explicitly redesigned,
then retested on both zombie and supported animal targets.

### 2026-09-20 recovery implementation awaiting live retest

The failed target-inventory handler has been replaced. `OnHitZombie` now uses the
engine's coarse `Head`, `Torso_Upper`, and `Torso_Lower` result to select a random
free Human attachment location, attaches the actual rolled recovery item, and lets
the native zombie death path transfer it into corpse loot. Each item also selects
one of two embedded transforms so the single available head anchor does not always
show an identical angle. Full visual regions retain additional results through
`addItemToSpawnAtDeath`.

Non-zombie character hits use `OnWeaponHitCharacter`. Their results remain in that
target's ModData and are created beside its body from authoritative
`OnCharacterDeath`; this avoids relying on the absent animal corpse container.
Static validation covers the new event, model, fallback, and synchronization
contracts. The visual offsets, corpse counts, animal death-site drop, and remote
client result remain unchecked until the procedure in `docs/TESTING.md` is run.

The first live visual check confirmed that attachment rendering worked but found a
fixed air gap between the Bolt and the torso. A first negative-offset correction was
then shown by follow-up screenshots to move in the wrong attachment-space direction;
the same screenshots also exposed a frontal upper-torso hit using a rear knife anchor.
The next correction used positive item-side penetration offsets aligned with vanilla
embedded props, removed both rear anchors from the upper-body pool, and kept a
slightly shallower value for broken fragments. A third set of screenshots still showed
the Bolt displaced from the body. An initial FBX comparison used imported world-space
bounds to identify opposite point directions and compensated with an inverse half-turn.

A fourth screenshot isolated two broken-Bolt alternate poses at `Knife Stomach` and
`Stomach`. The actual fragments were the short black marks below the arms; the green
marks on the trousers were clothing damage. Their corrected axes still exposed an air
gap because the earlier per-length offsets (`0.085`/`0.090`) did not use the item-origin
registration expected by the Human attachment pair. The character and item transforms
are multiplied directly in 42.20.4, and vanilla embedded blade models use the same
`0 0.15 0` item offset for short and long meshes. All Bolt variants now use that exact
offset; positional randomness comes from the engine slots, while the two model variants
change only angle. Debug builds log the reported region, chosen slot, and model variant.
Head, shoulder, and both abdominal placements still require a fresh front/side-camera
retest.

A fifth screenshot showed that the inverse-half-turn build reached the body but exposed
the point while burying the tail, making the Bolt look pasted sideways across the torso.
The earlier comparison had missed that the vanilla FBX keeps its long mesh axis locally
on Z behind a node transform, whereas the Bolt's baked FBX keeps it directly on Y; the
engine applies that mesh transform separately from the item attachment. The Bolt poses
therefore retain the original attachment rotations (`-90 0 -90` and alternate
`-83 8 -101`) so the point faces inward and the tail faces outward, while keeping the
now-verified `0 0.15 0` registration offset that removed the air gap. This combined
orientation and offset still requires a fresh live retest.

That retest still showed the Bolt lying against the zombie rather than penetrating it.
The visual feature is therefore removed instead of receiving another attachment-space
calibration. Zombie hits now roll the same Metal/Stone intact-or-broken result and add
the real item only to `addItemToSpawnAtDeath`, so it is invisible while the zombie is
alive and becomes ordinary corpse loot on death. All Bolt-side Human attachment blocks,
alternate embedded models, `setAttachedItem`, and attached-item synchronization calls
were removed. This decision supersedes the visual-attachment implementation history
above.

The project owner then tested candidate ZIP SHA-256
`64cbd2f2c39a04d6d7a96111dfd72ea775667b48d7a4d92635d70fa4fcf86b3c` and reported
that all focused zombie checks passed: living zombies showed no Bolt, killed zombies
provided the expected intact-or-broken result in corpse inventory, and no recovery item
was missing or duplicated. Animal death-site recovery and a remote multiplayer-client
observation remain unrecorded in this release-candidate pass.
