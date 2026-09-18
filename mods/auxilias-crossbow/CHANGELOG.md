# Changelog

## Unreleased

- Let the existing single and five-bolt Metal/Stone assembly recipes accept clean Denim or Leather Strips in the feather input slot; recipe and bolt IDs remain intact.
- Slimmed both broken-bolt icons to match the intact bolt family's shaft and head thickness; retained the short fragments and checked the final native 32px sprites side by side.
- Curved all three braced prods to remove the near-T empty silhouette; solved the loaded curves against the existing nut with conserved measured string and limb lengths. Extended only the fore-end by 20 mm in model space.
- Lengthened both canonical bolts and the crafting shaft by 20 mm, updated matching broken fragments, and retained shared full-size loaded meshes with about 30 mm point overhang. Refreshed eight affected icons against the revised models.
- Added direct mesh-ring mechanical measurements and four adversarial validation cases; retained the before/after review and all sixteen source/FBX audit results in docs/DESIGN-REFRESH-2026-09-19.md.

- Replaced all ten item icons with vanilla-style pixel sprites matched to the current models; retained full-resolution ImageGen originals and prompts, added reproducible palette/framing preparation, and preserved sharp native 32px output with nearest-neighbor synchronization.
- Preserved condition and selected bolt material when upgrading an unloaded Crossbow, and blocked loaded weapons from upgrade inputs so their bolt cannot be consumed unnoticed.
- Added five-item Bolt Shaft, Metal Bolt, and Stone Bolt batch recipes at unchanged per-item material cost, with modest time and XP savings.
- Reduced secondary-skill XP from the three Crossbow construction recipes; the Heavy Crossbow now auto-unlocks at Maintenance 4 and Blacksmith 6.
- Accepted Stone Drill alongside Hand Drill for both Crossbow upgrades.
- Refined the Metal/Stone bolt family to match the edited crossbows: tapered shafts, shaped fletching, ridged bindings, a necked bodkin and knapped stone facets; all six loaded models use the same updated parts with checked stock/groove clearance.
- Replaced oversized broken-bolt shafts and separate splinter rods with shorter integral fractures that share the intact bolts' exact heads and shaft thickness. Added canonical shaft and head models for crafting components, replacing the vanilla model placeholders without changing item IDs.
- Made the Blender file the editable source for all three crossbows, with named parts, linked body meshes across nine weapon states, canonical loaded/loose bolt meshes, and an export-only pipeline that preserves authored edits.
- Refined the wooden stocks, replaced top-only UV projection with per-face mapping, added a packed 512px material atlas and calibrated preview lighting, and simplified the front bindings while preserving the tested limb/string geometry and game attachment frame.
- Added FBX triangle/UV/winding comparison, collapsed-UV checks, source/export hashes, and loaded-bolt identity checks to the model audit.
- Restored Build 42's aimed-firearm path for the crosshair, ranged target selection, hit resolution, and multiplayer shot synchronization. Same-tick muzzle-light removal hides the firearm flash without disabling ballistics; the engine's bright tracer remains because its per-ammunition controller is not exposed to ordinary mod Lua.
- Corrected every relaxed and loaded crossbow's dropped-world transform so the broad prod rests top-side-up above the floor instead of standing on edge with one limb embedded in the ground.
- Redesigned both broken-bolt icons as shortened recoverable head-side fragments with compact V-shaped fractures, and replaced the world models' long lateral branch with two short break splinters so damage no longer resembles brown fletching.
- Unified the prod, string, bolt, and tiller groove on one power axis and moved loaded bolts forward so the string tube contacts the rear nock face instead of penetrating the bolt mesh.
- Rebuilt all three fore-ends against fifteenth-century museum construction: the tiller now terminates at an embedded prod root, both limbs rise gently to the shared string/bolt axis, and a transverse bridle pass, exposed hemp/leather ties, and a full-height front rivet replace the modern-looking top-mounted seat.
- Refined all three crossbows against real medieval references: removed the raised block rail and exposed sear bar, replaced the cube catch with an antler-like transverse string nut, lengthened the under-tiller trigger into a two-part tickler, changed the standard prod to a dark composite silhouette, limited broad iron lock plates to the Heavy model, and kept Heavy on a dark hardwood tiller instead of solid iron.
- Replaced the separate 58%-scale loaded-bolt proxy with one canonical compact quarrel geometry shared exactly by loose world items and all three loaded crossbows. Retuned each prod's cocked curvature so both Metal and Stone points project about 30 mm beyond the bow while their nocks remain tangent to the drawn string.
- Installed the Workshop poster and mod-list icon beside the Build 42.20 metadata so the game
  no longer renders white placeholders when it selects the versioned `mod.info`.
- Routed the relaxed and cocked strings through the limb-tip centerlines so they visibly exit the terminal nocks instead of resting on top of the prods, and corrected the cord specification for Blender's radius-based curve bevel; also changed back-slot attachment to the broad-head orientation so the prod lies flat against the character instead of protruding rearward.
- Consolidated ten identical per-model textures into one shared crossbow atlas and updated
  every model declaration and asset check to use it.
- Reworked the Workshop cover alongside Auxilia's Ammunition so both releases share the
  same worn-workbench composition, lighting, material palette, and rust-orange accent.
- Prevented Build 42's firearm-only muzzle light and bright bullet tracer from being created for crossbow shots. Crossbows now use the aimed-hand ranged path plus a client-side ballistics update instead of the firearm-effects path.
- Removed the spear-and-knife animation from every Bolt assembly and recovery recipe. Assembly and recovery now use the compact small-part hand animation, while only actual Stone head knapping uses the stone-working animation.
- Replaced the broken-bolt recovery recipe's full-size vanilla spear prop with the actual compact broken Bolt and a material-appropriate removal tool: Pliers for Metal heads and a sharp knife for Stone heads.
- Corrected the English Stone head recipe's `Knap` spelling, identified the Nail-shaped head as Metal, and aligned the Heavy Crossbow's documentation with its hardwood tiller, steel prod, and iron fittings.
- Kept the ten independent 128×128 icon masters while installing 32×32 runtime copies, preventing equipped crossbows from overlapping adjacent hotbar slots.
- Fixed a Build 42 client crash when firing a Stone Bolt after switching ammunition types. Both bolt items now self-reference their registered `AmmoType`, ensuring the engine initializes bullet-tracer configuration for the non-default Stone Bolt path.
- Removed `base:ammo` from both Crossbow Bolt materials so vanilla Gather Gunpowder no longer accepts them as propellant-bearing cartridges.
- Replaced every 3D-render-derived inventory image with a separate ten-icon hand-painted set and added a dedicated Stone Bolt Head icon instead of reusing Sharp Flint Flake artwork.
- Changed the Blender pipeline to install and validate dedicated icon sources without regenerating them from the FBX scene.
- Audited all eleven recipes and their shared vanilla tags; confirmed Twine consumes one drainable use per assembled bolt and found no further unrelated recipe-input collisions.
- Rebuilt all three crossbows as separate relaxed and cocked models with fixed string and limb lengths, physically solved catch positions, and clearly exposed strings above the rail.
- Added ammo-state model switching so loading bends the limbs and draws the string, while firing or unloading immediately restores the relaxed geometry; a release latch prevents delayed ammo synchronization from re-cocking the visual after a shot.
- Added generated physics checks for string-length conservation, limb-length conservation, rearward cocked bend, and valid catch placement.
- Deferred public Steam Workshop publication until the 1.0.0 completeness and quality gate.
- Replaced the placeholder Workshop preview, mod poster, and icon with dedicated three-tier crossbow key art.
- Added GitHub Actions validation, audited package artifacts, and tag-driven releases.
- Added structured bug and balance feedback forms for the 0.2.x stabilization cycle.
- Documented the 0.2.1 release gates and the maintenance-focused 0.3.0 roadmap.

## 0.2.0 — 2026-08-17

- Completed the final single-player integration procedure covering ammunition state, crafting, firing, recovery, balance, loot, and English/Korean presentation.
- Added visually distinct Stone Bolt and Broken Stone Bolt icons, FBX world models, chipped-stone heads, and pale feather fletching while preserving the original item IDs.
- Added a disabled inventory-context status row that explicitly shows the unloaded crossbow's currently selected Metal or Stone ammunition.
- Replaced overlay deployment with a staged, clean, SHA-256-verified tree swap that removes stale files and restores the previous installation on failure.
- Expanded static validation to cover every core Lua integration, material-specific item/model mapping, non-empty translations, and English/Korean key parity.
- Made release packaging compare every archived file's length and SHA-256 hash with the current workshop source before producing its checksum.
- Rebuilt the Metal Bolt as a compact medieval quarrel with a pointed bodkin head, socket, three separated leather vanes, cord whippings, and a rear nock.
- Shortened the Metal Bolt from 32.5 cm to approximately 28 cm (about 77% of the crossbows' compact length) while preserving icon readability.
- Corrected the Metal Bolt's dropped-world orientation with a 90° world-axis rotation and ground-contact pivot, retaining randomized Drop offsets and direction while making the weapon-axis FBX rest flat instead of standing upright.
- Disabled Blender's unnecessary headless `.blend` preview cache to prevent malformed `.thumbnails` directories on Windows.
- Narrowed only the prods' top-view front-to-back chord, preserving weapon span, curvature, and vertical strength so each reads as a slim curved band rather than a broad crescent.
- Matched the wood atlas to installed vanilla wooden firearms, kept gunmetal in the vanilla neutral-gray range, and reduced preview-only metallic glare.
- Rebuilt the tiller as a continuous taper that narrows and lifts over the support hand, using the measured sawn double-barrel action and fore-end envelope.
- Replaced the hooked, zigzag prod profiles with smooth seven-section sweeps and reduced the oversized central prod collars.
- Verified Light Crossbow, Crossbow, and Heavy Crossbow while aiming both left and right against captured vanilla sawn-shotgun and hunting-rifle poses.
- Reframed the weapon progression as Light Crossbow, Crossbow, and Heavy Crossbow while preserving the existing internal item IDs for save compatibility.
- Rebuilt all three models to the vanilla sawn-off double-barrel shotgun length and removed pistol grips, foregrips, braces, stirrups, windlass parts, and other decorative mechanisms.
- Gave the Heavy Crossbow a compact forged-iron tiller and thicker steel prod instead of an oversized arbalest silhouette.
- Reworked weapon construction into a linear Light → standard → Heavy upgrade path with vanilla-aligned tools, workstations, materials, skills, times, and XP.
- Rebuilt all three crossbows around the vanilla long-gun coordinate frame.
- Replaced detached bow segments with continuous tapered limbs and connected strings.
- Added distinct wooden, wood-and-iron, and forged-iron material treatments.
- Joined every exported asset into one triangulated, single-material mesh with UV-mapped texture atlases.
- Added automated FBX round-trip, dimension, UV, material, and multi-angle render validation.
- Fixed Build 42 equipped-model lookup, FBX unit scale, omitted multi-material parts, and reversed longitudinal/height export axes for all three crossbows.
- Verified all three rebuilt models in an aimed Project Zomboid 42.20.2 client debug scenario using game-native screenshots.
- Fitted all three equipped models to the same compact length, rear overhang, and vertical envelope to reduce torso and arm clipping.
- Reworked all item icons for stronger small-size contrast and consistent framing.
- Added dedicated Bolt Shaft and Bolt Head icons instead of reusing vanilla Handle and Nails artwork.
- Reworked Standard Bolt crafting into shaft carving, head shaping, and one-at-a-time assembly.
- Added Flint Knapping and Primitive Forge Blacksmith paths for producing Bolt Heads.
- Split Stone and Metal Bolt Heads, completed bolts, broken bolts, and recovery outcomes into distinct material paths.
- Added an unloaded-crossbow ammunition selector so normal reload and unload actions preserve the chosen bolt material.
- Required vanilla-tagged Chicken or Turkey Feathers for fletching and removed the Duct Tape substitute.
- Recalibrated every crafting duration and XP award against stable 42.20.2 carving, weapon assembly, knapping, blacksmithing, and reclamation recipes.
- Kept Heavy Crossbow construction at an Advanced Forge with Charcoal and Steel Bar stock while removing materials and tools that only served the discarded oversized mechanisms.
- Replaced the two-broken-bolts-to-one-bolt recipe with one-to-one metal head recovery.
- Kept bolt recipes skill-gated without requiring a magazine or schematic.

## 0.1.0 — 2026-08-16

- Added Improvised Crossbow, Reinforced Crossbow, and Heavy Arbalest.
- Added craftable Standard Crossbow Bolts and broken-bolt salvaging.
- Added tiered Woodwork, Carving, Maintenance, and Blacksmith requirements.
- Added tier-specific range, damage, durability, noise, and reload speeds.
- Added 70% intact bolt recovery and 30% broken-bolt recovery from hit targets.
- Added rare survivor-bag and barricaded-safehouse loot.
- Added English and Korean translations.
- Added original low-poly Blender models, item icons, poster, and reproducible asset source.
- Added a debug-mode test kit.
- Verified loading on Project Zomboid 42.20.2 through dedicated-server startup.
