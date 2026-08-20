# Release validation report — 1.0.0

Date: 2026-08-20 (Asia/Seoul)
Configured target: Project Zomboid 42.20 / tested build 42.20.2
Available runtime at final smoke: Project Zomboid 42.20.3, revision `70207f62e0`

## Static and repository validation

- Mod validator: pass — 19 unique items, 24 unique `CraftRecipe` IDs, nine exact vanilla
  ammunition outputs, EN/KO parity, manual coverage, icon/branding checks, and v1 runtime
  boundary checks.
- Monorepo validator: pass for both registered mods against configured Build 42.20.2.
- Vanilla procedural distribution names used by the loot injector were found in the installed
  `ProceduralDistributions.lua`.

## Dedicated-server smoke

Isolated cache: `work/ammo-server-smoke`
Final log: `work/ammo-server-smoke/Logs/2026-08-20_23-22_DebugLog-server.txt`

Evidence:

- line 79: runtime version 42.20.3;
- line 92: `loading AuxiliasAmmunition`;
- lines 1031–1054 of `Crafting/AllRecipes.txt`: 24 `AuxAmmo*` recipe IDs, all unique;
- line 1965: `*** SERVER STARTED ****`;
- line 1990: `Shutdown handling finished`;
- warnings/errors whose line mentions `AuxiliasAmmunition`, `AuxAmmo`,
  `AuxiliaBulletMold`, or `AuxAmmoShotgunMold`: zero.

The full runtime log contains unrelated vanilla Build 42 warnings and errors. They are not
reported as a globally clean log. The first development load also found and led to correction
of an invalid script comment and the internal perk ID (`PlantScavenging`).

## Artifact audit

- Archive: `dist/auxilias-ammunition/AuxiliasAmmunition-1.0.0.zip`
- Size: 1,279,354 bytes
- Workshop source files: 19
- ZIP file entries: 19
- Entry lengths and SHA-256 values: matched source during packaging
- SHA-256: `95c21705581fe34993322cf5c6c9bc904493afb70f2e432b70c0ec0168a69104`
- Sidecar: `AuxiliasAmmunition-1.0.0.zip.sha256`

## Publication gate not claimed as automated

Interactive client UI, two-human-player concurrency, and statistical loot sampling on the exact
42.20.2 binary remain the manual Workshop-publication matrix documented in `docs/TESTING.md`.
The implementation and artifact are complete; this report does not fabricate coverage that a
headless server cannot provide.
