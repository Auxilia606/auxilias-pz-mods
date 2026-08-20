# Roadmap

## Current release: 0.2.0

The current release is the complete single-player baseline for Project Zomboid 42.20.
Post-release defects and balance evidence are handled under `docs/STABILIZATION.md`.

## 0.3.0: maintenance and field longevity

The next feature release will deepen the existing three-tier progression instead of
adding another crossbow tier. Its theme is keeping a valued crossbow operational during
a long single-player run.

### Planned scope

1. **Tier-appropriate repair recipes**
   - Light Crossbow repair uses woodworking materials and tools.
   - Crossbow repair combines woodworking and metal fittings.
   - Heavy Crossbow repair requires the Advanced Forge and blacksmith tooling.
   - Repairs restore a bounded amount of condition and cannot create a better weapon
     than the input item's pre-damage maximum condition.
2. **Repair balance and progression**
   - Material costs scale with the tier and restored condition.
   - Skill gates reuse the disciplines already required to build each tier.
   - Repair is deliberately cheaper than rebuilding after ordinary wear but does not
     erase the value of Maintenance or make condition loss irrelevant.
3. **Player-facing clarity**
   - English and Korean recipe names and descriptions explain the required workstation,
     materials, and expected repair result.
   - The debug test kit exposes damaged examples without affecting normal play.
4. **Regression coverage**
   - Static validation covers recipe IDs, inputs, workstations, translations, and
     save-compatible item IDs.
   - Interactive testing covers partial damage, repeated repair, tool handling, skill
     gates, equipped state, and save/reload preservation.

### Delivery order

1. Verify stable 42.20.2 vanilla repair recipe semantics and condition-transfer fields.
2. Write the repair balance table and decide exact costs and restoration caps.
3. Implement one Light Crossbow repair path as the integration slice.
4. Validate the slice in a clean client before adding standard and Heavy paths.
5. Add translations, test-kit fixtures, static checks, and the complete acceptance pass.

### Non-goals

- No new crossbow tier or replacement of the three existing item IDs.
- No physical flying-projectile system; Build 42's aimed ranged-weapon hit resolution
  remains the supported mechanism.
- No multiplayer-support claim. Multiplayer concerns continue to be recorded for later
  work without blocking the single-player roadmap.
- No balance change without 0.2.x play evidence or a documented vanilla comparison.

The exact 0.3.0 repair numbers remain intentionally unset until the first delivery step
confirms the stable game's repair semantics. This avoids documenting fields or behavior
that the installed build does not actually support.

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
