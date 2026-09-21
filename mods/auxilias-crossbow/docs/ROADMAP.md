# Roadmap

## Current development version: 0.3.0 in development

Version 0.2.0 remains the last accepted single-player baseline for Project Zomboid
42.20. Version 0.2.1 consolidates the subsequent fixes, crafting adjustments, and
asset refresh as a release candidate. The current worktree has started the 0.3.0
maintenance feature on top of that candidate. Post-release defects and balance evidence
are handled under `docs/STABILIZATION.md`.

## 0.3.0: maintenance and field longevity

This feature release deepens the existing three-tier progression instead of adding
another crossbow tier. Its theme is keeping a valued crossbow operational during a long
single-player run.

### Implemented design

1. **Tier-appropriate repair recipes**
   - Light Crossbow repair uses woodworking materials and tools.
   - Crossbow repair combines woodworking and metal fittings.
   - Heavy Crossbow repair requires the Advanced Forge and blacksmith tooling.
   - Repairs use Build 42's bounded native condition restoration and can reach, but
     never exceed, the item's original maximum condition.
2. **Repair balance and progression**
   - Material costs scale with the tier; repeated repairs restore less condition per
     package, increasing the effective cost of each restored point.
   - Skill gates reuse the disciplines already required to build each tier.
   - Repair is deliberately cheaper than rebuilding after ordinary wear but does not
     erase the value of Maintenance or make condition loss irrelevant.
3. **Player-facing clarity**
   - English and Korean recipe names plus the crafting inputs expose the required
     workstation and materials; the native tooltip identifies the risk of failure.
   - The debug test kit exposes damaged examples without affecting normal play.
4. **Regression coverage**
   - Static validation covers recipe IDs, inputs, workstations, translations, and
     save-compatible item IDs.
   - Interactive testing covers partial damage, repeated repair, tool handling, skill
     gates, equipped state, and save/reload preservation.

### Verification status

1. Build 42.20.4 repair tags, recipes, callbacks, repeat-repair fields, and firearm
   fixing semantics have been inspected and recorded in shared knowledge.
2. The repair balance table and exact tier costs are documented in `docs/BALANCE.md`.
3. All three repair recipes, unloaded-item checks, translations, damaged test-kit
   fixtures, and static validation are implemented.
4. An isolated Build 42.20.4 dedicated server loaded the mod, registered all three
   repair recipes in `AllRecipes.txt`, reached `SERVER STARTED`, and shut down cleanly.
5. A clean client acceptance pass remains required for material consumption, displayed
   recipes, success/failure condition changes, repeated repairs, and save/reload.

### Non-goals

- No new crossbow tier or replacement of the three existing item IDs.
- No physical flying-projectile system; Build 42's aimed ranged-weapon hit resolution
  remains the supported mechanism.
- No multiplayer-support claim. Multiplayer concerns continue to be recorded for later
  work without blocking the single-player roadmap.
- No balance change without 0.2.x play evidence or a documented vanilla comparison.

The current repair numbers are an initial 0.3.0 balance pass and remain subject to the
clean-client acceptance results and longer single-player evidence.

## Path to 1.0.0

After the 0.3.0 maintenance milestone, development remains pre-release until the
existing systems feel complete and coherent in sustained single-player play. Additional
pre-1.0 milestones should be driven by recorded defects, balance evidence, usability
gaps, and presentation quality rather than by a requirement to add more weapon tiers.

Public Steam Workshop publication is intentionally deferred to 1.0.0. Before that
point, `tools/deploy.ps1` remains a local testing workflow and GitHub packages remain
development/test builds.

### 1.0.0 and Steam Workshop release gate

1. Complete the agreed single-player feature scope, including the 0.3.0 maintenance
   milestone and every accepted pre-release blocker.
2. Pass the complete procedure in `docs/TESTING.md` on the targeted stable Project
   Zomboid build from a clean installation.
3. Resolve or explicitly defer every accepted bug and balance report under the rules in
   `docs/STABILIZATION.md`.
4. Finalize Workshop presentation: cover, English and Korean description, screenshots,
   optional video, tags, compatibility statement, and change summary.
5. Build and verify the audited 1.0.0 ZIP and SHA-256 checksum, then test that exact
   package from a clean extraction.
6. Create the public Steam Workshop item, record its numeric Workshop ID in the project,
   and verify a clean subscribe/download/enable cycle.
7. Confirm the public Workshop contents and GitHub 1.0.0 release originate from the same
   tagged source tree.

Multiplayer support is not a 1.0.0 publication requirement unless the project scope is
changed explicitly. The Workshop description must state the tested support level.
