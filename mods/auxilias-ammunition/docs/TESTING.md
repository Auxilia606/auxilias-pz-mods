# Testing

## September 22 authored-asset candidate

The press .blend was edited directly, eight new world props were authored, and
nine icons now derive from the model renders. See `MODELING.md` and
`reports/ASSET-REFRESH-2026-09-22.md`. This supersedes the former body/powder
placeholder-art decision and the older press tooling descriptions below.
The upper tool is now octagonal. The existing bed/anchor/face IDs are retained.

The new acceptance pass must compare all four body families and all four material
items on light/dark floors, drop and Place Item rotations, and actual game scale.
Check each loose casing/tip/shot for ground contact, the mixture bowl for visible
contents, and field powder for its jar. Compare 32px inventory and world identity.
Recheck the press on different tables in all four directions, then pick up,
replace and save/reload. Prior client/menu tests do not cover these revised assets.

### World-orientation correction after user feedback

The user's client screenshot showed the new props sideways, and the user reported
that +90 degrees on the placement UI's Y axis made them look natural. Inspection
of the installed `ItemModelRenderer` confirms that `worldYRotation` maps to its
Z rotation, while the `world` attachment is inverted. All eight attachments now
use `rotate = 0 -90 -90`, equivalent to that extra placement rotation, and
`offset = 0 0 -0.0004` for renderer-Y clearance. Scale and FBX geometry are unchanged.

After restarting, test fresh drops with placement X/Y rotations at zero. Previously
manually corrected items may still retain Y=90 and need that manual rotation reset
to zero. Check the jar upright, bowl opening upward, powder mounds flat and body
pieces resting on the floor. After local redeployment, the user confirmed that
the correction was applied successfully in the running game. This is user-reported
acceptance of the orientation fix; the broader placement/save/reload checks above
and crafting/multiplayer checks remain separate.

## Automated release checks

`tools/validate.ps1` verifies metadata/version alignment, required files, balanced scripts,
unique item/recipe IDs, all 12 translated items, all 19 translated recipes, EN/KO key parity,
allowed station tags and internal skill IDs, exact ten-round outputs for all nine vanilla
calibers, custom icon presence, Workshop image dimensions/hashes, production-recipe manual
coverage, loot guards, and the absence of firearm hooks, `modData`, commands, and vanilla
item overrides.
Carbon grinding has no skill or manual gate and grants no Reloading XP.
Nitrogenous-mix preparation requires Farming 3 without a manual.
Recipe checks also cover the four body yields, the press station tag, both
drainable-bag inputs, and the field-powder stages.

`tools/package.ps1` runs validation, creates the ZIP, reopens it, compares every entry length
and SHA-256 with the source Workshop tree, and writes a `.sha256` sidecar.

## Current charcoal-recipe server load smoke

On 2026-09-13, an isolated Build 42.20.4 dedicated server loaded the amended Workshop
source and shut down cleanly. Its recipe export registered all 19 current recipes once,
including carbon grinding with explicit `Base.CharcoalCrafted`, `Base.Charcoal`, and
`Base.Coke` alternatives. The field-powder recipe retained `NitrogenousMix`, and the
retired fired-mold recipe was absent. The world dictionary registered all 12 current
mod items. No mod recipe or script parser error appeared. Evidence is in
`work/ammo-charcoal-smoke/Logs/2026-09-13_22-24_DebugLog-server.txt`, the exported
`Crafting/AllRecipes.txt`, and `WorldDictionaryLog.lua`. This load test does not verify
how the crafting UI lists the three fuel types or consumes them; that still needs a
client check after restarting with the updated installed copy.

## Press context-menu diagnosis

On 2026-09-16, one left click on the saved tabletop press at `10698,9804,0`
opened its native CraftBench window in the installed 42.20.4 client. Closing
that window, right-clicking the same press, and selecting the icon-bearing
**Tabletop Ammunition Press** option opened it again. The first left-click
attempt did not open it because its listener inspected only the single object
selected by the left-click picker. The completed listener also searches that
object's square for the matching press, as the right-click path does. The game
was restarted after installing the revised Lua for this check. Material
consumption and multiplayer behavior were not exercised in this interaction
test.

On 2026-09-16, the installed 42.20.4 client displayed the existing press item icon
to the left of **Tabletop Ammunition Press** when right-clicking the saved press tile
at `10698,9804,0`. Selecting that option still opened the CraftBench window and its
body and ammunition recipe list. The icon uses the existing 32×32 item texture.

The September 13 XUI-panel change and subsequent addition of `UiConfig` and
`CraftBench` to `Mov_AmmoPress` did not make an already placed press's menu appear.
The September 15 isolated 42.20.4 server probe established only that a fresh press
item script and item instance expose both components and the enabled XUI style:
`scriptComponents=true item=true ui=true uiEnabled=true uiStyle=true bench=true
benchValid=true`. Its log is
`work/ammo-item-components-smoke/Logs/2026-09-15_21-47_DebugLog-server.txt`.

Vanilla blacksmith workstations define `UiConfig`, `CraftBench`, and `SpriteConfig`
on their entity scripts and advertise station recipe tags. Their XUI styles usually
omit a dedicated component-panel declaration. The tabletop Key Duplicator is the
closer moveable comparison: it declares both `CustomItem` and an entity script, but
its item script has no UI or bench components. Thus the warning about those two
script definitions in
`C:\Users\USER\Zomboid\Logs\logs_2026-09-13\2026-09-13_17-59_DebugLog.txt`
does not, by itself, prove why a saved press lacked a menu.

In the live 42.20.4 client, the existing `auxammo_press_01_0` object at world square
`10698,9804,0` had `CustomItem = AuxiliasAmmunition.Mov_AmmoPress` but only one
component; `UiConfig` was absent. This saved object had kept its earlier component
set after the item script changed. The mod now checks its four press sprites and
`CustomItem` on `LoadChunk` and `OnGameStart`, adding only absent `UiConfig` and
`CraftBench` components from the current item script. Re-entering the same save
showed three components, including both UI and bench. Right-clicking the press's
tile displayed **Tabletop Ammunition Press**; selecting it opened the CraftBench
window with cartridge-body and ammunition recipes. This verifies the context menu
and recipe listing for that existing single-player object. Actual material
consumption, recovery/replacement, and multiplayer use still need the acceptance
checks below.

## Earlier no-primer server load smoke

On 2026-09-13, an isolated Build 42.20.4 dedicated server loaded the current Workshop
tree, reached `*** SERVER STARTED ****`, and shut down cleanly. All 19 current
`CraftRecipe` IDs appeared exactly once in `Crafting/AllRecipes.txt`, including the nine
final ammunition recipes. The world dictionary registered exactly the 12 current mod
items and no retired primer, mold, or separate projectile/casing items. No mod recipe
parser error appeared. Evidence is in `work/ammo-no-primer-smoke/Logs/2026-09-13_21-58_DebugLog-server.txt`,
the exported recipe index, and the save's `WorldDictionaryLog.lua`. The four known
headless `Item_AuxAmmoPress` XUI icon warnings recurred. This load check does not prove
crafting UI behavior or actual material consumption; the current acceptance checks below
cover those.

## Installed-copy mismatch found during crafting review

On 2026-09-13, the user-local staging copy at
`C:\Users\USER\Zomboid\Workshop\AuxiliasAmmunition` still contained the retired
`AuxAmmoFireBulletMold` recipe translated as "Break Down Old Fired Bullet Mold" and an
older `AuxAmmoBlendSurvivalPropellant` without `NitrogenousMix`. The repository Workshop
source had already removed that mold recipe and added
`item 1 [AuxiliasAmmunition.NitrogenousMix]` to the field-powder inputs. This source/install
mismatch explains why the crafting UI showed the obsolete recipe and omitted the
nitrogenous mix. `tools/deploy.ps1 -Mod auxilias-ammunition` replaced the user-local copy
and verified every deployed file against the source tree. At that point a client
restart was required to check the new crafting UI; a server load smoke of a
separate source copy alone does not update the user-local game installation.

## Earlier nitrogenous-mix server load smoke

On 2026-09-13, an isolated Build 42.20.4 dedicated server loaded a copy of the current
Workshop tree and reached `*** SERVER STARTED ****`, then shut down cleanly. All 28 mod
`CraftRecipe` IDs appeared once in `Crafting/AllRecipes.txt`, including both new
nitrogenous-mix recipes and the updated field-powder blend. The new `NitrogenousMix`
item registered in the world dictionary. Evidence is in
`work/ammo-nitrogen-smoke/Logs/2026-09-13_21-35_DebugLog-server.txt`, the exported
recipe index, and the save's `WorldDictionaryLog.lua`. No new item or recipe load error
appeared. The earlier `Item_AuxAmmoPress` XUI icon warnings and vanilla/optional-data
warnings recurred. This load check does not prove in-game partial-bag consumption or
crafting UI behavior; acceptance check 4 below covers those.

## Earlier tabletop-press server load smoke

On 2026-09-13, an isolated Build 42.20.4 (`b0bbce05d5`) dedicated server loaded the current
Workshop tree with only `AuxiliasAmmunition` enabled. It reached `*** SERVER STARTED ****`,
exported all 26 mod craft recipes, registered `Mov_AmmoPress` in the world dictionary, and
shut down normally. The second run corrected a misplaced XUI skin declaration found on the
first load. Its log is `work/ammo-press-smoke-v2/Logs/2026-09-13_17-50_DebugLog-server.txt`.
No mod-specific recipe, entity, texture-pack, or tile-definition load failure remained. Four
missing `Item_AuxAmmoPress` icon warnings occurred during headless XUI loading despite the
texture being present; vanilla XUI icons produced the same warning in that server run.
That earlier smoke did not cover client rendering, tabletop placement/recovery,
CraftBench interaction, actual crafting, or multiplayer behavior. The current release
checks are listed below.

An initial 42.20.4 client placement screenshot showed the press on a table but exposed an
oversized sprite and a checkerboard fringe under its wooden base. The art was regenerated
with a maximum 68×65-pixel footprint, a bottom anchor at y=181, and opaque/transparent
alpha only. A later four-orientation client screenshot revealed that the four cropped
renders had then been resized independently, making the same machine change size and
position on rotation. The current candidate regenerates each view through one orthographic
camera and lighting setup and places its common bed anchor at the same tile coordinate;
the wooden handle is shortened. A later 42.20.4 client check confirmed that all four
faces can be placed and rotated on the dining table. That check also exposed a lighter
wood tone and different apparent sizes across directions. The subsequent art revision
matches the dark dining-table finish, renders at a 30-degree elevation to fit the
game's 2:1 floor projection, and reduces the lever's length and upward angle. The
builder verifies one projected bed footprint and contact height across all four faces.
Reload the client and verify the revised wood, four faces, scale, tabletop contact,
and clean edges before release.
The next art candidate replaces the square lower and upper stamping blocks with shallow,
matching octagonal dies. Inspect all four installed faces to ensure the center reads as
working tooling rather than an unattached iron lump.
The selected centered-lever redesign replaces the offset C-frame and long side grip with
a 0.323 m square bed, mirrored uprights, a forged arch, and one central vertical ram.
The grip stays above the bed footprint. The four Blender faces and the packed tile art
must retain one anchor, one pixel scale, and matching bed bounds. In-client appearance
and save/reload after this redesign still need an acceptance check.
The current 128x256 source tiles have the same alpha bounds `(40,130,89,185)` on
south, east, north, and west. The projected bed is 50.12x31.33 pixels with one
contact height across all faces; the 32-pixel inventory icon remains legible.

The placed-object Rotate mode did not recognize the press because its tiles defined
`Facing` without offsets to the other three faces. The current candidate supplies all
three relative offsets on each face. The client check confirmed placement and rotation
on a table; saved-game reload still needs an acceptance check.

The next client check still found that tabletop placement and rotation settled on one
direction. Build 42 can replace a tabletop moveable's chosen sprite with the parent
table's facing; rotating a single-sprite moveable also goes through pickup and placement.
All four faces now set `IgnoreSurfaceSnap`. An isolated 42.20.4 server probe confirmed
that every face loads as moveable, exposes its three face offsets, and reports
`hasFaces()` and `canManuallyRotate()` true. Its log is
`work/tiledef-runtime-probe/Logs/2026-09-13_18-52_DebugLog-server.txt`.
The later client check confirmed that installed furniture rotates in four directions
on the table used for the screenshots.

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

The MP review confirms that all crafting mutations use vanilla `CraftRecipe` paths.
The press repair runs in shared Lua when chunks load and at client game start, adding
missing native components to matching world objects; the server flags repaired
objects for its normal save path. Loot injection remains server-side before
distribution merge and has an idempotence guard. There are no per-tick/per-shot
events, custom packets, client commands, or persistent tables to desynchronize.

Recipe auto-learning permits high-skill players to progress without manuals. Adding the mod
does not retroactively refill explored containers. `MineralSalts` remains the active item ID
for crushed mineral powder. Removing the mod with custom items stored in a save is not
supported.

## Redesign acceptance checks for the next release

1. On the configured Build 42 target, load a clean client and dedicated server; verify 19
   recipes, 12 items, nine vanilla output IDs, and EN/KO names, tooltips, and movable label
   without script errors.
2. Craft the movable tabletop press, place it on a table, rotate the installed press
   through all four directions, and open its crafting UI by left-clicking once and
   by selecting the right-click option. Check that a click from out of range does
   not open it. Save/reload,
   recover it, and place it again. Confirm it cannot be used as a workstation before
   placement and that no floor-sized footprint appears.
3. Press all four body families at the new station. Verify each recipe consumes one iron
   ingot and one copper scrap, plus two ripped sheets only for shotgun bodies, while keeping
   pliers. Verify 30/20/15/15 output and that no mold, furnace, charcoal, or tongs are
   required.
4. Crush both `Base.Stone2` and `Base.Limestone` with a retained hammer. Grind
   `Base.CharcoalCrafted` (Wood Charcoal), `Base.Charcoal`, and `Base.Coke` with a retained
   mortar and pestle at Reloading 0; verify no Reloading XP is awarded. Prepare one nitrogenous
   mix from two uses of `Base.CompostBag` and, separately, from two uses of `Base.Fertilizer`.
   A full compost bag should show 50% remaining after one craft and return an empty sandbag
   after the second; a full fertilizer bag should show 75% remaining after one craft and
   deplete after four. Repeat with partially used bags and confirm the crafting UI never
   treats two uses as two whole bags. Mix 40 units of each powder plus one nitrogenous mix
   into 40 field powder on any surface. Confirm no vanilla `Base.GunPowder` is produced or
   accepted by these recipes. Verify rotten food and picked-up animal dung both produce
   compost through the vanilla composter.
5. Assemble and fire all nine vanilla ammo outputs using bodies and field powder.
   Confirm the nine recipes consume only those two ingredients.
6. On a clean save, verify retired molds, separate projectile/casing/charge items, and
   primers are absent from current item, recipe, and loot indexes. Confirm the Saved Ammo
   Parts crafting category no longer appears. Check client/server inventory agreement
   after reconnect.
7. Have two players use and recover the press sequentially, reconnect, and verify the
   workstation and inventory state stay synchronized.
8. Confirm all nine dedicated inventory icons are distinguishable at 32 px.
   Inspect all eight authored body/material world models using the September 22
   acceptance pass above; their former vanilla placeholders have been replaced.

## Historical v1.0.0 manual acceptance matrix

The project owner completed this matrix on the exact public 42.20.3 client and a two-player
dedicated server on 2026-08-23. It documents the earlier runtime contract:

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
