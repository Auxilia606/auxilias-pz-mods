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
- For vanilla-style inventory work, inspect native sprites rather than relying on
  enlarged web images. The installed `UI2.pack` uses a `PZPK` version-1 header,
  little-endian page/entry metadata, and length-prefixed PNG atlases. Sprite entries
  include trimmed rectangles plus offsets and original canvas dimensions; restore
  those offsets when extracting a reference.
- A September 18, 2026 inspection of the target game's rifle, handle and forged
  spearhead sprites found 32×32 canvases, binary alpha, and respectively 11, 7 and
  5 visible RGB colors. This is a useful style reference for similar equipment,
  not a claim that every vanilla texture shares those restrictions. A pixel master
  enlarged from the native grid should be synchronized with nearest-neighbor
  sampling; bicubic resizing introduces extra colors and translucent edge blur.

## Models and textures

- Model scripts bind an FBX mesh and texture name separately. Keep those declarations aligned
  with the actual `models_X` and texture paths and validate every model block.
- When several single-material FBX files use the same palette and UV layout, one shared atlas
  is preferable to identical per-model PNG copies. Separate atlases remain appropriate when
  the imagery or UV layout truly differs.
- Re-import generated FBX files and compare dimensions, UV layers, material count, and model
  bounds. A successful export alone does not prove the game-facing file is sound.
- Keep validation renders and editable Blender sources outside the installable tree.
- When rebaking an already packed Blender image, save the new pixels to PNG, reload
  that PNG into a fresh image datablock, replace its material references, and pack it
  before saving. In Blender 5.2, rebaking and calling `pack()` on the existing image
  retained the previous packed payload in a reopened crossbow source. Compare the
  packed bytes with the external PNG and verify the reopened source before exporting.
- `AttachmentType` selects the character-model transform used by hotbar slots; a model's
  `world` attachment controls placed-world presentation and does not correct its position on
  the character. Match the attachment category to the model silhouette and test both normal
  and backpack replacement transforms. In Build 42.20, `Rifle` suits narrow long guns while
  `Shovel` includes the axial roll needed to keep a broad head or prod close to the back.

### Loose world-item rotation axes (Build 42.20.4 inspection)

`ItemModelRenderer.renderMain` maps saved `worldXRotation`, `worldZRotation`,
`worldYRotation` to renderer X, Y, Z respectively. Thus placement UI Y is renderer
Z, not the Y component in a model's `world` attachment. Its `init` method applies
the inverse of `translation(offset) * rotateXYZ(attachment angles)` before the
mesh transform. For an attachment `(0,-90,0)`, the equivalent of placement Y+90
is `(0,-90,-90)`, not simply adding 90 to the attachment's Y value. A source/FBX
round trip does not verify this game presentation transform. These findings came
from the installed `ItemModelRenderer` and `ModelInstanceRenderData` bytecode
while correcting sideways ammunition props after user-provided client evidence.

## Moveable tile furniture

- Build 42's furniture cursor reads the placed sprite's tile properties, not an entity's
  `SpriteConfig` faces. Four-direction moveables need `Facing` plus linked face offsets;
  `IsoWorld.LoadTileDefinitions` can derive offsets from matching `GroupName` and
  `CustomName`, but explicit offsets make a custom tileset's links auditable.
- A tabletop moveable may be snapped to its parent table's facing during placement when
  `IgnoreSurfaceSnap` is absent. Rotating a single-sprite moveable picks it up and places
  it again, so the same snap can undo a requested rotation. Give freely rotating tabletop
  tools `IgnoreSurfaceSnap` on every face.
- In Build 42.20.4, moveable tiles can declare `CustomItem` alongside a matching entity
  script. Vanilla's tabletop Key Duplicator does this: its moveable item has no
  `UiConfig` or `CraftBench`, while its entity script defines the UI, bench, and sprite
  components. The item's component list alone therefore cannot establish whether the
  placed world object will open an entity window. Inspect that object's components and
  right-click behavior in a client, including after save/reload.
- A placed moveable already stored in a save may retain its original component set after
  item or entity scripts change. On Build 42.20.4, a saved custom ammunition press had
  one component and no `UiConfig` despite a current item script with both `UiConfig` and
  `CraftBench`. Loading the script on a dedicated server and instantiating a fresh item
  did not detect this. If an update needs old placed objects to gain components, repair
  them on chunk load and check nearby loaded squares at game start; keep the repair
  scoped to the custom sprite and `CustomItem`, and make it idempotent.
- For the entity-window conditions, a scoped saved-object repair, and adding an icon to
  the vanilla right-click option, see `BUILD-42-ENTITY-WORKSTATIONS-AND-CONTEXT-MENUS.md`.

## Workshop artwork

- Treat `preview.png` plus the root and release-line copies of mod `poster.png` and `icon.png`
  as distribution derivatives of one high-resolution source and verify their hashes when the
  project requires identical files. A release-line `mod.info` resolves these image paths from
  its own directory, so the images must be copied beside both root and versioned metadata.
- Review at 512, 128, 64, and 32 pixels. The 32-pixel pass catches weak silhouettes and lost
  accents that remain invisible at authoring size.
- Related mods should share composition rules rather than duplicate the exact subject: camera
  angle, work surface, key-light direction, material palette, contrast, and accent color form
  the family identity.
- Auxilia's current generation brief is: a dark worn survivor workbench, stylized-realistic
  Project Zomboid presentation, soft upper-left light, aged wood and blackened metal, one
  restrained rust-orange interaction accent, generous safe margin, and no embedded text.
