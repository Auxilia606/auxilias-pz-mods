# Authored ammunition assets

`source-assets/blender/AuxiliasAmmunitionPress.blend` is the editable press source.
`source-assets/blender/AuxiliasAmmunitionParts.blend` owns the eight new world props.
Edit these files in Blender or with targeted Blender API operations. Exporters
read/evaluate temporary copies and never reconstruct geometry or save the source.
The former press/icon generators are compatibility wrappers, not model rebuilders.

## Parts source

Each `AuxAmmo<ItemId>` collection contains named, separately editable mesh parts at
the common game origin. Only the small pistol collection is initially visible;
toggle collection viewport visibility to inspect another asset. Dimensions are
compact game-prop proportions, not manufacturing specifications.

- Small and heavy pistol bodies pair an open brass casing with a separate blunt
  metal tip. The heavy set is broader/shorter and turned to a different diagonal.
- Rifle bodies use a longer necked casing and pointed loose tip.
- Shotgun bodies pair an open rust-red hull with three loose shot shapes.
- Mineral and carbon powders use low pale/dark mounds with fine scattered grains.
- Nitrogenous mixture sits in a shallow earthenware bowl with a visible warm rim.
- Field powder uses an opaque green jar, ochre lid and paper identification band.

The packed `AuxAmmoPartsAtlas` image is a 256px shared texture. Its external copy is
`textures/AuxAmmoPartsAtlas.png`; both must match byte-for-byte. Each mesh has one
atlas material and one noncollapsed UV layer. If editing packed pixels, save PNG,
reload into a new image datablock, replace references and repack before saving.

All eight sources are centered in X/Y and rest at authored Z=0. Separate loose
pieces also rest on that plane. The game FBX copy receives the repository's baked
180-degree X correction and exports with -Y forward / Z up. Script scale is 0.01;
the `world` attachment uses `rotate = 0 -90 -90` and `offset = 0 0 -0.0004`.
The initial borrowed `0 -90 0` rotation turned these props sideways in the client.
The corrected inverse attachment adds the same rotation as the user's +90-degree
Y adjustment in the game's placement UI. That UI's Y maps to renderer Z; it is
not the model script's Y. The offset maps to a +0.0004 renderer-Y floor clearance.
Script scale remains unchanged; final size and contact still require client acceptance.

## Press source

The existing bed, frame, pivots and camera setup are retained. The September 22
edit changes grip color, metal bump strength, ram/tooling contrast and the upper
plate's editable mesh into low octagonal tooling. The bed remains 0.323m square.
Studio worktop/stage collections are preview-only. Runtime press geometry is
rendered into four tiles, not shipped as an FBX.

All faces use the same orthographic camera, scale, light rig and anchor in
`render_runtime_press.py`. Do not crop/fit each face independently. The four
`auxammo_press_01` sprite IDs and tiledef registration are saved-game contracts.

## Export workflow

From the repository root, using Blender 5.2 and a Python environment with Pillow:

```powershell
$blender = 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe'
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python mods/auxilias-ammunition/tools/export-parts.py
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python mods/auxilias-ammunition/source-assets/blender/generate_ammo_press.py
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python mods/auxilias-ammunition/tools/render-press-previews.py
python mods/auxilias-ammunition/tools/build-press-art.py
python mods/auxilias-ammunition/tools/build-press-tiles.py
python mods/auxilias-ammunition/tools/build-icons.py
& ./tools/sync-icons.ps1 -Mod auxilias-ammunition
& ./tools/validate.ps1
& ./tools/package.ps1 -Mod auxilias-ammunition
```

The active release directory is read from `config/project-zomboid.json`.
`export-parts.py -- --verify-only --no-render` reimports existing distribution FBX
and compares all triangle positions, winding and UVs against the current source
within 1e-6. `--no-render` alone exports/audits without refreshing inspection views.
After changing geometry/materials, run with rendering before rebuilding icons.

The exporter validates all eight staged FBX files before replacing runtime files.
It rejects degenerate triangles, collapsed UVs, invalid bounds/ground plane,
atlas mismatch, source mutation, and changed FBX mesh/material/UV structure.
`parts-manifest.json` records source, atlas and export hashes plus measured results;
root validation catches stale exports after source edits. A Blender render is not
evidence of actual game placement or lighting.

## Icons

Nine item icons derive from the same authored model renders. `build-icons.py`
centers them within a 28px envelope, quantizes to at most 24 colors and uses binary
alpha. The 128px masters contain the 32px sprite enlarged four times. Only
`sync-icons.ps1` writes runtime icons, using nearest-neighbor sampling.
`build-press-art.py` now owns only the four tile images, avoiding competing icon
resamplers. Three books and all nine complete ammunition items retain vanilla art.

Inspect native 32px icons on dark/light backgrounds, not only enlarged views.
Preserve openings, powder/vessel distinctions and transparent margins. Source and
runtime pixels, margins, alpha, dimensions and distinct hashes are statically checked.
