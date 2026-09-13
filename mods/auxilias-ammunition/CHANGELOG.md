# Changelog

## 1.1.0 (release candidate)

- Added a hand-operated tabletop ammunition press as the common station for body
  pressing, primer forming, final assembly, and old-part conversion. Placement and
  crafting behavior still require in-game acceptance.
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
  within the bed footprint. All four faces use the same model, scale, and anchor.
- Removed pottery molds, kiln firing, and charcoal fuel from current body production; saved molds
  remain defined and can be salvaged through their published recipe IDs.
- Combined projectile and casing manufacture into four cartridge-body recipes, with one
  body item per caliber family and preserved vanilla ten-round outputs.
- Reused the former casing recipe IDs for one-to-one conversion of matching components
  already held in saves; retained all published item and recipe IDs.
- Replaced compost-based propellant processing with portable crushing of stone and grinding
  of charcoal or coke into two abstract powders, then blending ammo-only field powder.
- Updated improvised primers, English and Korean crafting text, documentation, and static
  validation for the redesigned chain. Runtime acceptance remains pending.

- Replaced complete-ammunition placeholder world models with dedicated meshes for small and
  heavy pistol projectiles, rifle projectiles, shot charge, and empty shotgun hulls.
- Matched world-model quantity semantics to crafting counts: projectile and hull models now
  show one counted component, while a shot charge remains a multi-pellet one-shell charge.
- Added a reproducible Blender component-model pipeline, shared atlas, validation renders,
  FBX round-trip checks, and static guards against restoring the placeholder mappings.
- Installed the Workshop poster and mod-list icon beside the Build 42.20 metadata so the game
  no longer renders white placeholders when it selects the versioned `mod.info`.
- Fixed all Build 42 crafting recipe translations so the crafting UI shows localized names
  instead of internal `AuxAmmo*` IDs.
- Replaced reused vanilla component art with dedicated projectile, shot-charge, casing,
  hull, and primer icons that remain distinct at the 32×32 inventory size.
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
