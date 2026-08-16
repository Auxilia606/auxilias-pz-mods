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

| Asset | Width X | Length Y | Height Z |
|---|---:|---:|---:|
| Improvised Crossbow | 0.445 | 0.541 | 0.245 |
| Reinforced Crossbow | 0.545 | 0.605 | 0.235 |
| Heavy Arbalest | 0.635 | 0.660 | 0.288 |

## Regenerate and validate

From the repository root, run:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python 'source-assets\blender\generate_assets.py'
```

Generation fails if a crossbow leaves its expected size range, if an FBX imports as more than one mesh, if UV or material data is lost, or if an FBX round trip changes its dimensions. The ignored `work/model-validation` directory receives:

- `report.json` with topology, bounds, UV, material, and FBX round-trip results.
- Isometric, top, and side PNG renders for all three crossbows.

The renders use the same generated texture atlas and UV coordinates referenced by the game model scripts. They are not diffuse-color-only previews.

## Item icons

The same Blender source renders seven transparent 128×128 item icons: three crossbows, intact and broken bolts, Bolt Shaft, and Bolt Head. Icons use a consistent isometric camera, controlled canvas margins, stronger game-scale contrast, and a dark silhouette line. Generation rejects fully transparent icons, clipped artwork, unexpected dimensions, and unreasonable canvas coverage; results are recorded in `work/model-validation/report.json`.

## Visual acceptance

- Each limb is one continuous tapered mesh from socket to tip, with no floating segments.
- The string touches both limb tips and the central latch.
- The stock, grip, rail, prod socket, and tier-specific mechanisms visibly connect.
- Improvised, Reinforced, and Heavy models have distinct silhouettes and increasing dimensions.
- No model is mirrored, rotated onto its side, or centered on the butt after FBX re-import.
- Equipped, aimed, reloading, and dropped-item views must still be checked interactively in Project Zomboid after changing dimensions or the origin.

The 2026-08-16 Build 42.20.2 client check loaded and cycled all three weapons in an isolated debug scenario. It confirmed that the FBX assets resolve without load errors, retain long-gun scale, follow the character's aim direction, and no longer stand vertically through the character.
