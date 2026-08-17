# Changelog

## Unreleased

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
