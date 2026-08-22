# Testing

## Automated release checks

`tools/validate.ps1` verifies metadata/version alignment, required files, balanced scripts,
unique item/recipe IDs, all 19 translated items, all 24 translated recipes, EN/KO key parity,
allowed station tags and internal skill IDs, exact ten-round outputs for all nine vanilla
calibers, custom icon presence, Workshop image dimensions/hashes, manual coverage, loot guards,
and the absence of firearm hooks, `modData`, commands, and vanilla item overrides.

`tools/package.ps1` runs validation, creates the ZIP, reopens it, compares every entry length
and SHA-256 with the source Workshop tree, and writes a `.sha256` sidecar.

## Runtime evidence

An isolated dedicated-server cache was used with only `AuxiliasAmmunition` enabled. The first
load exposed two Build 42-specific issues: `//` is not accepted at that script-object location,
and the internal Foraging perk name is `PlantScavenging`. Both were corrected. The clean run:

- loaded `AuxiliasAmmunition`;
- exported all 24 recipes exactly once in `Crafting/AllRecipes.txt`;
- reached `*** SERVER STARTED ****`;
- shut down normally;
- emitted no warning/error mentioning the mod, its IDs, or its model.

Steam updated the local installation during development; the corrected final smoke log reports
Build 42.20.3. The target configuration remains release line 42.20 and audited/tested build
42.20.2. Vanilla-wide warnings in that log are not attributed to this mod.

## Multiplayer and save review

The MP review confirms that all crafting mutations use vanilla `CraftRecipe` paths and the only
Lua runs server-side before distribution merge. There are no per-tick/per-shot events, custom
packets, client commands, or persistent tables to desynchronize. The loot function has an
idempotence guard.

Save review confirms that recipe auto-learning permits old characters to progress at high skill.
Adding the mod does not retroactively refill explored containers. Removing it with custom items
stored in a save is not supported.

## Manual in-game acceptance matrix

Before Workshop publication, repeat these interactive checks on the exact public 42.20.2 client
and a two-player dedicated server if that build is available:

1. Inspect all EN and KO names/tooltips and the Ammunition crafting category.
2. Read each manual and verify its recipe tier; verify high-skill fallback on an old save.
3. Craft both molds, all component batches, and all nine final outputs at their required stations;
   run consecutive projectile batches and confirm both fired molds remain usable and unbroken.
4. Fire each vanilla gun using crafted vanilla rounds; reload magazines and revolvers normally.
5. Have two players share a station/container, craft sequentially, reconnect, and confirm counts.
6. Generate new gun-store, police, SWAT, and military containers and sample manual/primer rarity.
7. Confirm that firing creates no mod casing item and that no firearm stats are changed.

This matrix is an honest publication gate; it is not claimed as automated UI coverage.
