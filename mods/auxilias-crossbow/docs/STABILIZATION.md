# 0.2.x stabilization plan

Version 0.2.0 is the feature baseline. The 0.2.x cycle is limited to regression fixes,
localization and packaging corrections, and evidence-backed balance adjustments. New
weapons, ammunition systems, and multiplayer-support claims belong outside 0.2.x.

## Feedback intake

Use the repository's Bug report or Balance feedback issue form. Reports should identify
the mod and game versions, crossbow tier, bolt material, relevant character skills, and
other enabled mods. Reproduction reports should be repeated with only Auxilia's Crossbow
enabled whenever practical.

For balance observations, record the raw counts rather than only the conclusion:

- shots and confirmed hits;
- intact and broken recoveries by bolt material;
- reload time and relevant Reloading skill;
- weapon condition before and after the session;
- crafted quantities, missing bottleneck materials, and loot settings.

## Triage gates

| Result | Action |
|---|---|
| Crash, load failure, item loss, duplication, or save regression caused by the mod | Fix in 0.2.1 and add a static or smoke-test regression check where possible. |
| Incorrect recipe input/output, workstation gate, translation key, or model mapping | Fix in 0.2.1 and extend `tools/validate.ps1`. |
| Repeatable balance problem from at least two isolated play sessions | Compare against `docs/BALANCE.md`, adjust the smallest relevant value, and rerun the full single-player acceptance procedure. |
| One-off preference or report with conflicting mods | Keep open for corroboration; do not change the baseline yet. |
| Multiplayer-only problem | Record it in `docs/MP-NOTES.md`; do not claim multiplayer support in 0.2.x. |

## 0.2.1 release gate

Version 0.2.1 is the current release candidate. Complete the focused procedure in
`docs/RELEASE-TEST-0.2.1.md` and the following release steps before tagging:

1. Run `tools/validate.ps1` and build a fresh audited package with `tools/package.ps1`.
2. Repeat every affected check in `docs/TESTING.md` and the adjacent reload, recovery,
   crafting, and translation checks most likely to regress.
3. Load the release candidate in a clean Project Zomboid 42.20 client.
4. Record the result in `docs/SMOKE-TEST.md` and `CHANGELOG.md`.
5. Keep the existing internal item IDs unchanged for save compatibility.

Version 0.2.0 remains the last accepted release until these gates pass and the 0.2.1
smoke-test result is recorded.
