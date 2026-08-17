# Crossbow model pipeline

The five 3D assets are generated from `source-assets/blender/generate_assets.py` with Blender 5.2 LTS. The script is the source of truth; generated FBX, textures, icons, poster, and the `.blend` file are committed outputs.

## Coordinate frame

Project Zomboid firearm models use:

- X for left/right width.
- Y for the forward/muzzle direction.
- Z for height.
- The trigger/action close to `(0, 0, 0)`.

Installed vanilla long-gun meshes occupy approximately Y `-0.18` to `0.50`. The crossbows deliberately use the same origin convention so the existing `Rifle` animation does not attach the character at the center or butt of the weapon.

Blender exports with `-Y` forward and `Z` up. The FBX files carry centimeter unit metadata, so every game model block uses `scale = 0.01`. The model blocks live in `module Base`, while each item uses an unqualified `WeaponSprite` name and `AttachmentType = Rifle`; these details are required by Build 42's equipped-model lookup.

The game-export copy receives a baked 180-degree X-axis correction. Blender's own FBX importer restores the authored axes from metadata, while Project Zomboid otherwise reads both the longitudinal and height axes reversed. Every asset is also collapsed to one FBX material, matching the vanilla firearm meshes; per-part colors remain encoded in the shared UV texture atlas. Multiple material slots caused Build 42 to omit non-primary weapon parts in game.

| Asset | Width X | Length Y | Height Z |
|---|---:|---:|---:|
| Light Crossbow | 0.254 | 0.363 | 0.086 |
| Crossbow | 0.285 | 0.363 | 0.086 |
| Heavy Crossbow | 0.320 | 0.363 | 0.084 |
| Metal Bolt | 0.032 | 0.277 | 0.032 |

All three equipped models use the vanilla sawn-off double-barrel shotgun hand envelope (approximately `0.357` long and `0.076` high) as their common size reference. Their limbs remain wider than a firearm by design, while length, rear overhang, and vertical bulk stay compact to reduce arm and torso clipping.

The tier silhouettes intentionally avoid pulleys, windlasses, pistol grips, foregrips, cheek pads, and decorative braces. Every model is built around a low tiller, bolt rail, lock, prod, string, and compact trigger. Each prod uses seven tapered sections in one monotonic rearward sweep from socket to tip; there is no reversed tip segment or decorative recurve that can read as a hook at game scale. Its top-view chord stays narrow (`0.009`, `0.010`, and `0.012`) independently of span, sweep, and vertical thickness, producing a slim curved-band silhouette instead of a broad crescent. Light Crossbow uses a wooden prod and cord binding, Crossbow adds a steel prod and metal fittings, and Heavy Crossbow uses an iron tiller with the thickest steel prod.

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
- Isometric, top, and side PNG renders for all three crossbows.

The renders use the same generated texture atlas and UV coordinates referenced by the game model scripts. They are not diffuse-color-only previews.

## Item icons

The same Blender source renders seven transparent 128×128 item icons: three crossbows, intact and broken bolts, Bolt Shaft, and Bolt Head. Icons use a consistent isometric camera, controlled canvas margins, stronger game-scale contrast, and a dark silhouette line. The intact bolt is a short medieval quarrel with a forged bodkin point, socket, three radial leather vanes, cord whippings, and a dark rear nock. Its tighter icon framing keeps the narrow shaft readable without clipping. Generation rejects fully transparent icons, clipped artwork, unexpected dimensions, and unreasonable canvas coverage; results are recorded in `work/model-validation/report.json`.

The intact bolt also receives a dedicated `AuxiliaCrossbowBolt_placed.png` validation render. It rolls the authored model slightly onto its lower vanes and renders it against a ground plane, providing a repeatable proxy for the in-game Place Item view. Because the FBX uses the weapon coordinate frame, its model definition uses a `world` attachment with a 90° X-axis correction and a ground-contact pivot. This lays the bolt's long axis across the ground without suppressing Project Zomboid's randomized within-tile offsets or Z rotation. **Place Item** remains intentionally controlled by the player's cursor and rotation keys.

## Visual acceptance

- Each limb is one continuous tapered mesh from socket to tip, with no floating segments.
- The string touches both limb tips and the central latch.
- The tiller, rail, lock, prod socket, limbs, and string visibly connect.
- Light, standard, and Heavy models have distinct material treatment and progressively wider, thicker limbs while sharing one compact length.
- No model is mirrored, rotated onto its side, or centered on the butt after FBX re-import.
- Equipped and aimed views in both left- and right-facing directions must be checked interactively in Project Zomboid after changing dimensions or the origin. Reloading and dropped-item checks are part of the later practical test.

The Build 42.20.2 client check loads and aims all three weapons in an isolated debug scenario. Direct-window screenshots in both aim directions are used to confirm complete single-material rendering, compact torso clearance, forward-facing limbs, correct top/bottom orientation, and two-handed alignment for Light, standard, and Heavy models.
