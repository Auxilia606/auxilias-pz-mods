# Changelog

## 1.1.0 (release candidate)

- Corrected the eight new props' default world orientation after a client screenshot
  showed them on their sides. The attachment now includes the equivalent of the
  placement UI's +90-degree Y correction, with floor clearance on the corrected axis.
  The user confirmed the corrected orientation after local redeployment.
- Added eight authored world models for cartridge bodies, mineral/carbon powders,
  the mixture bowl and a labelled field-powder jar, replacing shared scrap and
  finished-ammunition placeholders. Nine crisp inventory icons now derive from
  the same editable Blender assets. Complete ammunition still uses vanilla items.
- Refined the existing press's grip/ram contrast and octagonal upper tooling while
  retaining its bed, camera scale and four-direction tabletop anchor.
- Made the Blender files authoritative: exporters evaluate temporary copies and
  audit FBX geometry/UV round trips without rebuilding or saving the source.
  Static validation also checks source/export hashes and pixel-master consistency.
  Broader placement, save/reload and revised-art acceptance checks remain open.

- Open the placed tabletop press's CraftBench window with one left click, like
  the vanilla furnace. This also works when the click picker selects the table
  beneath the press; the icon-bearing right-click option remains available.
- Reused the tabletop press item icon beside its right-click menu entry, making the
  station easier to identify. Verified that the icon renders and the entry still opens
  the CraftBench window in the 42.20.4 client.
- Added a hand-operated tabletop ammunition press as the common station for body
  pressing and final assembly. Its right-click CraftBench window and recipe list were
  confirmed in a 42.20.4 client; crafting consumption still requires acceptance.
- Added `UiConfig` and `CraftBench` to the press's custom moveable item and an enabled
  XUI CraftBench panel. Restored missing components on presses already placed in saves,
  using scoped chunk-load and game-start checks. The previously placed press now shows
  **Tabletop Ammunition Press** on right-click and opens its CraftBench window.
- Reduced its placed sprite to the size of vanilla tabletop machinery and removed
  translucent edge pixels that appeared as a checkerboard along the wooden base.
- Rebuilt all four press faces with one isometric camera, common scale and tabletop
  anchor, even lighting, and a shorter lever after in-game rotation exposed mismatched
  silhouettes and shifting placement.
- Connected the four tile faces with rotation offsets so a press already placed on a
  table can be turned with the furniture Rotate mode.
- Kept the selected face during tabletop placement and rotation by disabling automatic
  surface-facing snap on all four press tiles.
- Matched the press wood to dark dining furniture and reduced its grain contrast;
  adjusted the orthographic view to the game's 2:1 floor projection and shortened and
  flattened the lever so all four faces retain a consistent physical footprint.
- Replaced the stacked square stamping blocks with low, matching octagonal dies seated
  in the forged frame so the working point reads as part of the press at tile scale.
- Rebuilt the tabletop press around the selected centered-lever concept: square
  wooden bed, paired uprights, one forged arch, central ram, and a short grip
  within the bed footprint. Lengthened the grip slightly for a clearer silhouette;
  all four faces use the same model, scale, and anchor.
- Removed pottery molds, kiln firing, and charcoal fuel from body production.
- Combined projectile and casing manufacture into four cartridge-body recipes, with one
  body item per caliber family and preserved vanilla ten-round outputs. Retired the
  separate projectile, casing, hull, charge, and mold items and their recipes.
- Reworked propellant processing around portable mineral and carbon powders plus a new
  nitrogenous mix. Two uses of a compost bag (50%) or two uses of NPK fertilizer (25%)
  prepare one mix; the existing field-powder recipe now consumes it. Collected animal dung
  and rotten food feed the compost route through the vanilla composter. Partially used bags
  remain usable, and the new recipes require Farming 3 without a manual.
- Carbon grinding explicitly accepts wood charcoal, charcoal, or coke and no longer
  requires Reloading 3 or awards Reloading XP for using a mortar and pestle.
- Removed improvised and factory primers from the crafting chain, item set, and loot.
  Final assembly now uses cartridge bodies and field powder. Runtime acceptance remains pending.
- Installed the Workshop poster and mod-list icon beside the Build 42.20 metadata so the game
  no longer renders white placeholders when it selects the versioned `mod.info`.
- Fixed all Build 42 crafting recipe translations so the crafting UI shows localized names
  instead of internal `AuxAmmo*` IDs.
- Added dedicated cartridge-body and powder-component icons that remain distinct at
  the 32×32 inventory size.
- Reworked the Workshop cover as part of the shared Auxilia visual family: worn dark
  workbench, warm upper-left light, blackened metal, and restrained rust-orange accents.
- Added reproducible icon and Workshop-art synchronization from high-resolution sources.

## 1.0.0 — 2026-08-20

- Added a complete late-game production loop for all nine vanilla Build 42 ammunition types.
- Added reusable pottery molds, four projectile/casing families, renewable mineral salts,
  survival propellant, improvised primers, and rare factory primers.
- Added 24 native `CraftRecipe` definitions using vanilla stations and timed actions.
- Added three lootable recipe manuals with high-skill automatic discovery for existing saves.
- Added English and Korean item, recipe, tooltip, and crafting-category translations.
- Added server-safe procedural loot injection without firearm hooks or persistent mod data.
- Added Workshop artwork, a dedicated shotgun mold icon, validation, packaging, deployment,
  audit, balance, design, and testing documentation.
