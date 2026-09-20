# 0.2.1 release-candidate game test

This is the focused manual acceptance pass for the current 0.2.1 candidate. It covers
everything changed after the accepted 0.2.0 baseline. Use `docs/TESTING.md` when a full
1.0-style acceptance pass is required.

## Test conditions

- Project Zomboid **42.20.4**.
- Single-player, with only **Auxilia's Crossbow** enabled unless a step says otherwise.
- Install the exact audited `AuxiliasCrossbow-0.2.1.zip`, not the repository working
  tree. Record the SHA-256 from its adjacent checksum file.
- Current audited candidate SHA-256:
  `a149748225ad398f19d2e28d486d58e4ef50eb633fce6531e51f1905cfc3fcf5`.
- Use one new debug save and one copy of an existing 0.2.0 save.
- Keep the client console log and screenshots for every visual failure.
- Do not tag 0.2.1 while any required checkbox is unresolved.

Known pre-test issue: the configured reload-speed values currently appear to make the
standard Crossbow faster than the Light Crossbow, while the intended order in
`docs/TESTING.md` is Light, standard, then Heavy. Measure the result below and treat a
different order as a release blocker until either the implementation or the documented
design is corrected.

## 1. Clean load and registration

- [x] Extract the candidate into an empty Workshop test directory and confirm that
  `Contents/mods/AuxiliasCrossbow/42.20/mod.info` reports Version 0.2.1.
- [x] Enable only Auxilia's Crossbow, restart when prompted, and create a fresh save.
- [x] Confirm that all three crossbows, both complete bolts, both broken bolts, the
  shaft, and both heads can be spawned through the debug UI.
- [x] Open the crafting window and confirm that all fourteen Auxilia recipes appear
  exactly once.
- [x] Confirm that the startup and client logs contain no Auxilia script, registry,
  model, texture, translation, or Lua error.

## 2. Crossbow models and state transitions

Repeat the following for Light, standard, and Heavy Crossbows with both Metal and Stone
Bolts.

- [x] The unloaded model has a visibly braced curved prod and a straight relaxed string.
- [x] Loading shows the matching bolt, bends the prod, and draws the string to the nut.
- [x] The string meets the rear nock without entering the bolt or tiller.
- [x] Roughly the same short length of the Metal and Stone points projects beyond the
  prod; neither bolt disappears inside the stock.
- [x] Firing immediately removes the bolt and restores the relaxed model.
- [x] Unloading restores the relaxed model and returns the same bolt material.
- [x] Re-equipping a loaded crossbow restores the correct cocked Metal or Stone model.
- [x] Aiming left and right keeps both hands near the tiller without torso, arm, or prod
  clipping severe enough to obscure the weapon.
- [x] In the back hotbar slot, with and without a backpack, the prod lies close to the
  back instead of pointing outward.
- [x] Dropped unloaded, Metal-loaded, and Stone-loaded states rest top-side-up without a
  limb standing vertically or entering the floor.
- [x] Dropped complete bolts, broken bolts, shaft, Metal head, and Stone head are visible,
  correctly oriented, and proportionate to their inventory icons.

## 3. Combat, effects, and reload

- [x] Each crossbow shows the firearm crosshair, acquires a target, consumes exactly one
  bolt, and damages a target through the ranged path.
- [x] A Heavy Crossbow with a Stone Bolt can fire at a target and empty ground without an
  `IsoBulletTracerEffects` error or return to the menu.
- [x] At night in an unlit room, neither bolt material creates a muzzle-flash model or
  radius-18 muzzle light on any tier.
- [x] A vanilla firearm fired immediately afterward still produces its normal muzzle
  light.
- [x] The practical range increases from Light to standard to Heavy, and all three are
  dramatically quieter than a pistol.
- [x] At Reloading 0, time one reload for each tier under the same conditions and record
  the order and approximate duration below.
- [x] Repeat the timing comparison at Reloading 5. The intended fastest-to-slowest order
  is Light, standard, Heavy.
- [ ] A hit zombie and a hit animal receive exactly one intact or broken bolt matching the
  selected material; a miss does not create a duplicate inventory item.

  **Observed failure:** no recoverable bolt remained in the zombie's body inventory.
  Animal recovery could not be confirmed and appears incompatible with the current
  target-inventory approach. This remains the sole required 0.2.1 retest blocker.

Reloading 0 results:

| Tier | Duration | Order |
|---|---:|---:|
| Light |  |  |
| Standard |  |  |
| Heavy |  |  |

The tester reported that the reload section passed; exact durations were not recorded.

Reloading 5 results:

| Tier | Duration | Order |
|---|---:|---:|
| Light |  |  |
| Standard |  |  |
| Heavy |  |  |

## 4. New and changed crafting paths

- [x] One Sharp Flint Flake produces exactly four Stone Bolt Heads at Flint Knapping 2.
- [x] Five Small Handles produce exactly five shafts and consume no extra handle.
- [x] The five-Metal and five-Stone batch recipes each consume five shafts, five matching
  heads, five Twine uses, and five fletching materials, then produce exactly five bolts.
- [x] Chicken Feather, Turkey Feather, clean Denim Strip, and clean Leather Strip each
  work in both single-bolt recipes.
- [x] Each of the four eligible fletching materials works in both five-bolt recipes when
  all five inputs use the same material.
- [x] A five-bolt craft using a mixture of eligible feathers and clean strips either
  consumes exactly five total and produces five bolts, or is rejected cleanly without
  consuming anything. Record which behavior Build 42.20.4 uses.
- [x] Dirty Denim Strips, Dirty Leather Strips, and Duct Tape cannot replace the listed
  fletching materials.
- [x] A partially used Twine spool contributes only its remaining uses and neither Twine
  nor bolts are duplicated.
- [x] Hand Drill and Stone Drill each satisfy the drill input for both upgrades.
- [x] An unloaded, partially damaged crossbow preserves its condition fraction and its
  selected Metal or Stone ammunition type after upgrading.
- [x] A loaded crossbow is not accepted as an upgrade input and its loaded bolt remains
  intact.
- [x] Heavy Crossbow remains unavailable before Maintenance 4 and Blacksmith 6, then
  auto-unlocks and still requires the Advanced Forge and listed materials.
- [x] Metal- and Stone-head recovery each return one head, use the compact small-parts
  animation, and display the actual broken bolt plus the correct tool.
- [x] Neither complete bolt appears as an input to vanilla Gather Gunpowder.

Mixed five-bolt fletching result:

Passed as part of the crafting-path report; the exact accepted/rejected mixed-input
behavior was not recorded.

## 5. Existing-save and persistence regression

- [x] Load a copied 0.2.0 save with existing crossbows and bolts; no item becomes missing,
  renamed to an internal ID, or replaced by another type.
- [x] Existing weapon condition, loaded count, and selected Metal/Stone ammunition remain
  intact.
- [x] Save with one unloaded crossbow set to Stone, one Metal-loaded crossbow, and one
  Stone-loaded crossbow; reload the save and confirm all three states.
- [x] Fire, unload, upgrade, save again, and reload once more without duplication, lost
  ammunition, or a stuck cocked model.

## 6. Presentation and localization

- [x] At native inventory and hotbar size, all ten icons are present, crisp, unclipped,
  and distinguishable; broken bolts look shorter than intact bolts.
- [x] English shows the expected item, recipe, ammunition-status, and test-kit names.
- [x] Korean shows translated item, recipe, ammunition-status, and test-kit names without
  raw translation keys.
- [x] The mod list displays the shared poster/icon rather than a white placeholder.

## Optional balance sampling

These checks are useful evidence but do not block 0.2.1 unless they expose duplication,
the wrong material, or a grossly incorrect probability.

- [ ] Record at least 30 successful Metal hits and the intact/broken counts.
- [ ] Record at least 30 successful Stone hits and the intact/broken counts.
- [ ] Confirm that crossbows remain rare rather than absent or common in several newly
  generated safehouse/survivor-loot samples.

## Result record

- Date: 2026-09-20
- Tester: project owner
- Game build: 42.20.4
- Candidate ZIP SHA-256: `a149748225ad398f19d2e28d486d58e4ef50eb633fce6531e51f1905cfc3fcf5`
- New-save name:
- Existing-save copy:
- Other enabled mods: none / list
- Reload order at level 0: passed; exact durations not recorded
- Reload order at level 5: passed; exact durations not recorded
- Required checks passed: clean load/registration, model/state transitions, combat
  targeting/effects/reload, crafting, existing-save persistence, presentation/localization
- Required checks failed: recovered bolt did not remain in a hit zombie's body inventory;
  animal recovery was not confirmable with the current design
- Relevant log path:
- Screenshot/evidence paths:
- Final decision: **RETEST** after recovery handling is corrected or deliberately
  redesigned and documented

After a complete pass, summarize the result in `docs/SMOKE-TEST.md`, replace the
release-candidate heading in `CHANGELOG.md` with the release date, and create the
`auxilias-crossbow/v0.2.1` tag from the tested source tree.
