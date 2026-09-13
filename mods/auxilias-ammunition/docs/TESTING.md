# Testing

## Automated release checks

`tools/validate.ps1` verifies metadata/version alignment, required files, balanced scripts,
unique item/recipe IDs, all 24 translated items, all 25 translated recipes, EN/KO key parity,
allowed station tags and internal skill IDs, exact ten-round outputs for all nine vanilla
calibers, custom icon presence, component-model mappings and files, the shared model atlas,
Workshop image dimensions/hashes, coverage of the 24 published learned recipe IDs, loot
guards, and the absence of firearm hooks, `modData`, commands, and vanilla item overrides.
The new carbon-grinding recipe needs no manual so pre-update characters can use it. Recipe
checks must also cover
the four body yields, paired legacy-part conversions, and the three powder stages.

`tools/package.ps1` runs validation, creates the ZIP, reopens it, compares every entry length
and SHA-256 with the source Workshop tree, and writes a `.sha256` sidecar.

## v1.1.0 server load smoke

On 2026-09-13, an isolated dedicated-server cache loaded the redesigned Workshop tree on the
installed Build 42.20.4 (`b0bbce05d5`). The server reached `*** SERVER STARTED ****` and
shut down normally. `Crafting/AllRecipes.txt` exported exactly 25 distinct `AuxAmmo*` recipe
IDs, matching the source script. No warning or error line directly named an AuxAmmo recipe or
the mod. Four missing optional AnimSets/actiongroups directory traces under the mod path also
occurred in the prior v1.0.0 smoke and did not prevent startup. The evidence is in
`work/ammo-redesign-smoke/Logs/2026-09-13_16-38_DebugLog-server.txt` and its crafting export.
This is a load check, not an in-game crafting, multiplayer, or save-migration acceptance test.

## Historical v1.0.0 runtime evidence

An isolated dedicated-server cache was used with only `AuxiliasAmmunition` enabled. The first
load exposed two Build 42-specific issues: `//` is not accepted at that script-object location,
and the internal Foraging perk name is `PlantScavenging`. Both were corrected. The clean run:

- loaded `AuxiliasAmmunition`;
- exported all 24 recipes exactly once in `Crafting/AllRecipes.txt`;
- reached `*** SERVER STARTED ****`;
- shut down normally;
- emitted no warning/error mentioning the mod, its IDs, or its model.

Steam updated the local installation during v1.0.0 development; the corrected smoke log reports
Build 42.20.3 revision `70207f62e0`. The target configuration remains release line 42.20,
the v1.0.0 balance audit remains tied to the exact 42.20.2 vanilla data it inspected, and the
current shared tested-build setting is 42.20.4. This historical log does not validate the
redesigned recipes. Vanilla-wide warnings in that log are not attributed to this mod.

## Multiplayer and save review

The MP review confirms that all crafting mutations use vanilla `CraftRecipe` paths and the only
Lua runs server-side before distribution merge. There are no per-tick/per-shot events, custom
packets, client commands, or persistent tables to desynchronize. The loot function has an
idempotence guard.

Save review confirms that recipe auto-learning permits old characters to progress at high skill.
Adding the mod does not retroactively refill explored containers. The redesign keeps published
component IDs, converts matching old projectile+casing/hull pairs at the Hand Press, and
reuses saved `MineralSalts` stacks as crushed mineral powder. Unmatched legacy parts require
separate review; the pair conversion cannot consume a part without its match. Removing the mod
with custom items stored in a save is not supported.

## Redesign acceptance checks for the next release

1. On the configured Build 42 target, load a clean client and dedicated server; verify 25
   recipes, 24 items, nine vanilla output IDs, and EN/KO names and tooltips without script
   errors.
2. Craft each reusable mold, then cast all four body families. Verify each recipe consumes
   one iron ingot, one copper scrap, its intended charcoal amount, and two ripped sheets only
   for shotgun bodies; verify 30/20/15/15 output and retained molds.
3. Crush both `Base.Stone2` and `Base.Limestone` with a retained hammer. Grind both
   `Base.Charcoal` and `Base.Coke` with a retained mortar and pestle. Mix 40 units of each
   powder into 40 field powder on any surface. Confirm no vanilla `Base.GunPowder` is
   produced or accepted by these recipes.
4. Make improvised primers with both powders and copper. Assemble and fire all nine vanilla
   ammo outputs using bodies, field powder, and either primer type.
5. Load a v1.0.0 save with each old projectile and casing/hull pair plus `MineralSalts` and
   `SurvivalPropellant` stacks. Confirm every matching pair converts one-for-one, the saved
   powder IDs remain usable, the conversions appear in the Saved Ammo Parts category,
   carbon grinding is available without rereading Manual II,
   and client/server inventories agree after reconnect.
6. Confirm new body and carbon-powder inventory icons are distinguishable at 32 px and that
   legacy component models still render on an existing save. Current dropped-item visuals
   reuse brass scrap/empty hull and powder-jar models; decide whether those placeholders are
   acceptable before publication or replace them with dedicated world models.

## Historical v1.0.0 manual acceptance matrix

The project owner completed this matrix on the exact public 42.20.3 client and a two-player
dedicated server on 2026-08-23. Repeat it before a future release when the runtime contract or
implementation changes:

1. Inspect all EN and KO names/tooltips and the Ammunition crafting category.
2. Read each manual and verify its recipe tier; verify high-skill fallback on an old save.
3. Craft both molds, all component batches, and all nine final outputs at their required stations;
   run consecutive projectile batches and confirm both fired molds remain usable and unbroken.
4. Fire each vanilla gun using crafted vanilla rounds; reload magazines and revolvers normally.
5. Have two players share a station/container, craft sequentially, reconnect, and confirm counts.
6. Generate new gun-store, police, SWAT, and military containers and sample manual/primer rarity.
7. Confirm that firing creates no mod casing item and that no firearm stats are changed.
8. Place all three projectile types, shot charge, and shotgun hulls on the ground. Confirm that
   they show only their named components, rest above the floor at a readable scale, and do not
   resemble complete cartridges or loaded shotgun shells.

All eight checks passed on 42.20.3. This remains manually reported acceptance coverage rather
than automated UI coverage.
