# Testing

## Automated release checks

`tools/validate.ps1` verifies metadata/version alignment, required files, balanced scripts,
unique item/recipe IDs, all 25 translated items, all 26 translated recipes, EN/KO key parity,
allowed station tags and internal skill IDs, exact ten-round outputs for all nine vanilla
calibers, custom icon presence, component-model mappings and files, the shared model atlas,
Workshop image dimensions/hashes, coverage of the 24 published learned recipe IDs, loot
guards, and the absence of firearm hooks, `modData`, commands, and vanilla item overrides.
The carbon-grinding and saved-mold salvage recipes need no manual so pre-update characters
can use them. Recipe checks also cover the four body yields, paired legacy-part conversions,
retired mold salvage, the new press station tag, and the three powder stages.

`tools/package.ps1` runs validation, creates the ZIP, reopens it, compares every entry length
and SHA-256 with the source Workshop tree, and writes a `.sha256` sidecar.

## Current tabletop-press server load smoke

On 2026-09-13, an isolated Build 42.20.4 (`b0bbce05d5`) dedicated server loaded the current
Workshop tree with only `AuxiliasAmmunition` enabled. It reached `*** SERVER STARTED ****`,
exported all 26 mod craft recipes, registered `Mov_AmmoPress` in the world dictionary, and
shut down normally. The second run corrected a misplaced XUI skin declaration found on the
first load. Its log is `work/ammo-press-smoke-v2/Logs/2026-09-13_17-50_DebugLog-server.txt`.
No mod-specific recipe, entity, texture-pack, or tile-definition load failure remained. Four
missing `Item_AuxAmmoPress` icon warnings occurred during headless XUI loading despite the
texture being present; vanilla XUI icons produced the same warning in that server run.
Client rendering, tabletop placement/recovery, CraftBench interaction, actual crafting,
old-save migration, and multiplayer behavior still require the acceptance checks below.

An initial 42.20.4 client placement screenshot showed the press on a table but exposed an
oversized sprite and a checkerboard fringe under its wooden base. The art was regenerated
with a maximum 68×65-pixel footprint, a bottom anchor at y=181, and opaque/transparent
alpha only. A later four-orientation client screenshot revealed that the four cropped
renders had then been resized independently, making the same machine change size and
position on rotation. The current candidate regenerates each view through one orthographic
camera and lighting setup and places its common bed anchor at the same tile coordinate;
the wooden handle is shortened. Reload the client and verify the new four faces, scale,
tabletop contact, and clean edges before release.

The placed-object Rotate mode did not recognize the press because its tiles defined
`Facing` without offsets to the other three faces. The current candidate supplies all
three relative offsets on each face. Confirm an already placed press can be selected,
cycled through four directions, rotated, saved, and reloaded on a client; static tile
validation cannot substitute for that interaction check.

## Earlier v1.1.0 server load smoke (before tabletop press)

On 2026-09-13, an isolated dedicated-server cache loaded the redesigned Workshop tree on the
installed Build 42.20.4 (`b0bbce05d5`). The server reached `*** SERVER STARTED ****` and
shut down normally. `Crafting/AllRecipes.txt` exported exactly 25 distinct `AuxAmmo*` recipe
IDs, matching the source script at that time. No warning or error line directly named an AuxAmmo recipe or
the mod. Four missing optional AnimSets/actiongroups directory traces under the mod path also
occurred in the prior v1.0.0 smoke and did not prevent startup. The evidence is in
`work/ammo-redesign-smoke/Logs/2026-09-13_16-38_DebugLog-server.txt` and its crafting export.
This is a historical load check for the preceding mold-and-furnace candidate. It does not
validate the new press, the revised recipes, in-game crafting, multiplayer, or save migration.

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
component IDs, converts matching old projectile+casing/hull pairs at the new press, reclaims
saved unfired molds as clay and fired molds as mineral powder, and reuses saved `MineralSalts`
stacks as crushed mineral powder. Unmatched legacy parts require
separate review; the pair conversion cannot consume a part without its match. Removing the mod
with custom items stored in a save is not supported.

## Redesign acceptance checks for the next release

1. On the configured Build 42 target, load a clean client and dedicated server; verify 26
   recipes, 25 items, nine vanilla output IDs, and EN/KO names, tooltips, and movable label
   without script errors.
2. Craft the movable tabletop press, place it on a table, rotate the installed press
   through all four directions, open its crafting UI, save/reload, recover it, and place
   it again. Confirm it cannot be used as a workstation before placement and that no
   floor-sized footprint appears.
3. Press all four body families at the new station. Verify each recipe consumes one iron
   ingot and one copper scrap, plus two ripped sheets only for shotgun bodies, while keeping
   pliers. Verify 30/20/15/15 output and that no mold, furnace, charcoal, or tongs are
   required.
4. Crush both `Base.Stone2` and `Base.Limestone` with a retained hammer. Grind both
   `Base.Charcoal` and `Base.Coke` with a retained mortar and pestle. Mix 40 units of each
   powder into 40 field powder on any surface. Confirm no vanilla `Base.GunPowder` is
   produced or accepted by these recipes.
5. Make improvised primers with both powders and copper at the new press. Assemble and fire all nine vanilla
   ammo outputs using bodies, field powder, and either primer type.
6. Load a v1.0.0 save with each old projectile and casing/hull pair, fired and unfired clay
   molds, plus `MineralSalts` and `SurvivalPropellant` stacks. Confirm every matching part
   pair converts one-for-one at the new press, unfired molds yield clay, fired molds yield
   mineral powder, saved powder IDs remain usable, and all conversions appear in Saved Ammo
   Parts. Carbon grinding and mold salvage must be available without rereading a manual.
   Check client/server inventory agreement after reconnect.
7. Have two players use and recover the press sequentially, reconnect, and verify the
   workstation and inventory state stay synchronized.
8. Confirm new press, body, and carbon-powder inventory icons are distinguishable at 32 px and that
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
