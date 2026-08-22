# Project Zomboid asset production patterns

These findings were confirmed by inspecting installed Build 42 Workshop mods and are the
default asset conventions for this monorepo.

## Inventory and recipe icons

- Script `Icon = Name` values resolve to `media/textures/Item_Name.png`.
- A recipe normally inherits recognition from its ingredients and result item; give custom
  intermediate items dedicated icons when several of them coexist in the crafting inventory.
- Keep high-resolution masters outside the installable Workshop tree and generate the small
  runtime texture. Auxilia uses 128×128 masters and 32×32 runtime copies.
- Compare related icons as a set at the final 32×32 size. Silhouette, length, grouping, and
  material color must carry the distinction; fine engraving and text do not survive.
- Use real PNG alpha. A painted white or checkerboard background is not transparency.

## Models and textures

- Model scripts bind an FBX mesh and texture name separately. Keep those declarations aligned
  with the actual `models_X` and texture paths and validate every model block.
- When several single-material FBX files use the same palette and UV layout, one shared atlas
  is preferable to identical per-model PNG copies. Separate atlases remain appropriate when
  the imagery or UV layout truly differs.
- Re-import generated FBX files and compare dimensions, UV layers, material count, and model
  bounds. A successful export alone does not prove the game-facing file is sound.
- Keep validation renders and editable Blender sources outside the installable tree.

## Workshop artwork

- Treat `preview.png`, mod `poster.png`, and mod `icon.png` as distribution derivatives of one
  high-resolution source and verify their hashes when the project requires identical files.
- Review at 512, 128, 64, and 32 pixels. The 32-pixel pass catches weak silhouettes and lost
  accents that remain invisible at authoring size.
- Related mods should share composition rules rather than duplicate the exact subject: camera
  angle, work surface, key-light direction, material palette, contrast, and accent color form
  the family identity.
- Auxilia's current generation brief is: a dark worn survivor workbench, stylized-realistic
  Project Zomboid presentation, soft upper-left light, aged wood and blackened metal, one
  restrained rust-orange interaction accent, generous safe margin, and no embedded text.
