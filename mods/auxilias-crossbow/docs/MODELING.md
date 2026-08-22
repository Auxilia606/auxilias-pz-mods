# Crossbow model pipeline

The ten 3D assets are generated from `source-assets/blender/generate_assets.py` with Blender 5.2 LTS: relaxed and cocked variants of all three crossbows plus four intact/broken bolt models. The script is the source of truth for generated FBX files, the shared model texture, validation renders, and the `.blend` file. Inventory artwork has a separate source of truth under `source-assets/icons`. The Workshop cover source lives under `source-assets/workshop` and is synchronized independently with `tools/sync-workshop-art.ps1`; Blender's promotional render is retained only as a geometry and material reference under `work/model-validation`.

## Coordinate frame

Project Zomboid firearm models use:

- X for left/right width.
- Y for the forward/muzzle direction.
- Z for height.
- The trigger/action close to `(0, 0, 0)`.

Installed vanilla long-gun meshes occupy approximately Y `-0.18` to `0.50`. The crossbows deliberately use the same origin convention so the existing `Rifle` animation does not attach the character at the center or butt of the weapon.

Blender exports with `-Y` forward and `Z` up. The FBX files carry centimeter unit metadata, so every game model block uses `scale = 0.01`. The model blocks live in `module Base`, while each item uses an unqualified `WeaponSprite` name and `AttachmentType = Rifle`; these details are required by Build 42's equipped-model lookup.

The game-export copy receives a baked 180-degree X-axis correction. Blender's own FBX importer restores the authored axes from metadata, while Project Zomboid otherwise reads both the longitudinal and height axes reversed. Every asset is also collapsed to one FBX material, matching the vanilla firearm meshes; per-part colors remain encoded in the single shared `AuxiliaCrossbowAtlas.png` UV texture. Multiple material slots caused Build 42 to omit non-primary weapon parts in game.

| Asset | Width X | Length Y | Height Z |
|---|---:|---:|---:|
| Light Crossbow (relaxed / cocked) | 0.249 / 0.238 | 0.363 | 0.087 |
| Crossbow (relaxed / cocked) | 0.279 / 0.264 | 0.363 | 0.087 |
| Heavy Crossbow (relaxed / cocked) | 0.314 / 0.295 | 0.363 | 0.088 |
| Metal Bolt | 0.032 | 0.277 | 0.032 |
| Stone Bolt | 0.032 | 0.279 | 0.037 |
| Broken Metal Bolt | 0.051 | 0.200 | 0.023 |
| Broken Stone Bolt | 0.048 | 0.217 | 0.033 |

All three equipped models use the vanilla sawn-off double-barrel shotgun hand envelope (approximately `0.357` long and `0.076` high) as their common size reference. Their limbs remain wider than a firearm by design, while length, rear overhang, and vertical bulk stay compact to reduce arm and torso clipping.

The tier silhouettes intentionally avoid pulleys, windlasses, pistol grips, foregrips, cheek pads, and decorative braces. Every model is built around a low tiller, bolt rail, lock, prod, string, and compact trigger. Each prod is sampled from a circular arc with a fixed arc length: the relaxed and cocked versions change curvature and tip position without stretching or shortening either limb. Its top-view chord stays narrow (`0.009`, `0.010`, and `0.012`) independently of span, bend, and vertical thickness, producing a slim curved-band silhouette instead of a broad crescent. Light Crossbow uses a wooden prod and cord binding, Crossbow adds a steel prod and metal fittings, and Heavy Crossbow uses an iron tiller with the thickest steel prod.

The relaxed string runs straight from tip to tip above the rail. The cocked string uses the exact same total length and forms two visible segments from the bent tips to the central catch. The catch position is solved from the fixed string length rather than chosen artistically. Generated measurements permit at most `0.00001` units of string-length drift and `0.0002` units of sampled limb-length drift. Current string deltas are `0.0`, `0.00000001`, and `0.00000001` units for Light, standard, and Heavy respectively.

At runtime `AuxiliaCrossbow_ModelState.lua` selects the cocked model whenever the equipped weapon contains its one bolt, selects the relaxed model when empty, and forces the relaxed model at both the weapon-swing hit point and attack-finished events so the string releases on the firing frame. A fired-weapon latch keeps the relaxed model authoritative until the client observes the empty weapon, preventing delayed ammo synchronization from briefly redrawing the string. The implementation follows the same Build 42 `setWeaponSprite` plus `resetEquippedHandsModels` mechanism used by vanilla fishing rods.

## Vanilla firearm hand and color references

The compact hand section was checked against six installed vanilla firearm meshes: sawn double-barrel shotgun, sawn pump shotgun, sawn shotgun, hunting rifle, varmint rifle, and lever-action rifle. The exact `JS_2000_Sawn` support-hand region (`Y = 0.060..0.150`) is approximately `0.016` wide and occupies `Z = 0.001..0.034`. Each crossbow now uses one continuous tapered tiller: the rear/action width is `0.024..0.028`, the lock width is `0.020..0.024`, and the support-hand body narrows to `0.016..0.020` while lifting its lower surface above `Z = 0`. This preserves a readable shoulder stock without placing a deep rectangular body through the supporting palm.

Wood and metal colors were sampled from the installed `ShotgunDoubleBarrelSawn`, `HuntingRifle`, `VarmintRifle`, and `LeverActionRifle` textures. The common orange-brown gunstock pixels average approximately sRGB `121/58/7`; darker walnut areas are around `80/35/10`, and neutral gunmetal has a median value near `60..62`. The generated atlas targets those ranges directly. Blender preview materials use reduced metallic reflection so validation renders do not wash the game texture into white.

## Regenerate and validate

From the repository root, run:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python 'source-assets\blender\generate_assets.py'
```

The headless generator disables the `.blend` file preview before saving. This preview is unnecessary for a generated source file and avoids Blender 5.2 creating malformed `.thumbnails` cache paths beside the repository on Windows.

Generation fails if a crossbow leaves its expected size range, if an FBX imports as more than one mesh or one material, if UV data is lost, or if an FBX round trip changes its dimensions. The ignored `work/model-validation` directory receives:

- `report.json` with topology, bounds, UV, material, and FBX round-trip results.
- Isometric, top, and side PNG renders for all six relaxed/cocked crossbow states.

The renders use the same generated texture atlas and UV coordinates referenced by the game model scripts. They are not diffuse-color-only previews.

## Item icons

Ten transparent 128×128 hand-painted masters live under `source-assets/icons`: three crossbows, material-specific intact and broken bolts, Bolt Shaft, Metal Bolt Head, and Stone Bolt Head. They use consistent framing, muted earth colors, high small-size contrast, and a dark painted silhouette line, but are not renders of the 3D meshes. The Stone Bolt Head is a compact purpose-knapped projectile point rather than the vanilla Sharp Flint Flake artwork. Build 42's hotbar draws item textures at native size, so the installed copies are downsampled to its expected 32×32 canvas and remain inside a single slot.

The Blender pipeline downsamples these authored sources into the mod instead of rendering inventory art from scene geometry. Generation then rejects missing, fully transparent, clipped, incorrectly sized, or implausibly covered masters, verifies every runtime copy is 32×32, and records the result in `work/model-validation/report.json`. Static validation also verifies that all ten runtime icons retain alpha and remain mutually distinct.

Both intact bolts receive dedicated `_placed.png` validation renders. The pipeline rolls each authored model slightly onto its lower vanes and renders it against a ground plane, providing a repeatable proxy for the in-game Place Item view. Because the FBX files use the weapon coordinate frame, their model definitions use `world` attachments with a 90° X-axis correction and ground-contact pivots. This lays each bolt's long axis across the ground without suppressing Project Zomboid's randomized within-tile offsets or Z rotation. **Place Item** remains intentionally controlled by the player's cursor and rotation keys.

## Visual acceptance

- Each limb is one continuous tapered mesh from socket to tip, with no floating segments.
- The relaxed string is straight between the tips; the cocked string touches both tips and the central catch without changing total length.
- The cocked limbs bend rearward and slightly inward while retaining the relaxed limb arc length.
- The tiller, rail, lock, prod socket, limbs, and string visibly connect.
- Light, standard, and Heavy models have distinct material treatment and progressively wider, thicker limbs while sharing one compact length.
- No model is mirrored, rotated onto its side, or centered on the butt after FBX re-import.
- Equipped and aimed views in both left- and right-facing directions must be checked interactively in Project Zomboid after changing dimensions or the origin. Reloading must visibly change to the cocked model, firing must visibly return to the relaxed model, and unloading must also return to relaxed. Dropped-item checks are part of the later practical test.

The Build 42.20.2 client check loads and aims all three weapons in an isolated debug scenario. Direct-window screenshots in both aim directions are used to confirm complete single-material rendering, compact torso clearance, forward-facing limbs, correct top/bottom orientation, and two-handed alignment for Light, standard, and Heavy models.
