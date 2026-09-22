# Ammunition icon sources

The nine `Item_AuxAmmo*.png` masters contain native 32px sprites enlarged four
times. Their visual source is the editable Blender model and its matching render,
recorded in `render-sources.json`. Three book icons remain vanilla.

After editing `.blend` assets, follow `../../docs/MODELING.md` to render/export,
then run `tools/build-icons.py` and the root
`tools/sync-icons.ps1 -Mod auxilias-ammunition`.
The build step uses a compact palette, binary alpha and transparent margins;
sync uses nearest-neighbor sampling and is the only runtime-icon writer.

`generate_body_icons.py` delegates to that build step for compatibility. It no
longer draws the retired independent body/powder artwork. Do not rerun old copies
of the former icon or press geometry generators over the authored source.
