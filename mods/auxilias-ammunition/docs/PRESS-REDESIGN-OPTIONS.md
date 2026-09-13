# Tabletop press redesign options

These three images are visual concepts for review, not four-face game tiles. No
runtime sprite, item ID, crafting rule, or installed furniture is changed by
this proposal.

## Shared brief

- Hand-operated tabletop tool in dark stained wood and forged iron.
- Compact square bed and centered load path. No long handle, wheel, or linkage
  protrudes from one side of the bed.
- Broad open working gap and few large features so the press still reads at the
  approximately 50-pixel width of the placed tile.
- A small **centered** front tooling slot or iron inset distinguishes front from
  back without upsetting left/right symmetry.

| Option | Concept image | Shape and four-face tradeoff |
| --- | --- | --- |
| 1. Twin-post screw | [Image 1](../source-assets/concepts/press-redesign-01-twin-post-screw.png) | Two matching wooden posts, iron bridge, central vertical screw, equal-length T grip. Most stable silhouette across all rotations; slower screw-operated look. |
| 2. Centered lever frame | [Image 2](../source-assets/concepts/press-redesign-02-center-lever.png) | Two matching uprights and open arched bridge, short lever on the front/back centerline, slim central ram. Retains the preferred manual-lever character while removing the old off-axis connecting block. The grip must remain within the bed footprint when viewed from above. |
| 3. Top handwheel | [Image 3](../source-assets/concepts/press-redesign-03-top-wheel-v2.png) | Matching iron posts and a horizontal wheel directly above the central ram. No side projection and nearly rotation-invariant silhouette; the thin wheel may flatten visually at final tile size, so its rim and spokes need a small-sprite check. |

Option 2 best preserves the original lever concept; option 1 is the least risky
choice for four equal-scale game faces.

## Four-face tile plan

Build **one** centered 3D model, then turn that model around the bed center under
one fixed 30-degree-elevation orthographic camera and unchanged lighting. Use
south = 0 degrees, east = -90, north = 180, west = +90, matching the existing
`auxammo_press_01_0..3` tile order. Keep the same render resolution, pixel scale,
128x256 tile canvas, and bed anchor on every face. Never resize or recenter a
face to fit its individual alpha box.

| Face | Intended visual read |
| --- | --- |
| South | Centered front tooling slot/inset visible; for option 2, the short grip faces the viewer. |
| East | Side profile of the open frame and center ram; option 2's grip projects diagonally but stays over the bed. |
| North | Rear iron bridge and supports visible; the front inset is hidden. |
| West | Mirror of the east face in overall width and height, with corresponding occlusion. |

The bed's projected width, depth, center, and tabletop contact height must match
across all four faces. The frame top must keep the same world height. A lever or
front detail can change the visible alpha bounding box through normal occlusion;
that does not justify per-face scaling. The front mark should remain legible at
roughly 2-3 pixels in the final tile, without becoming an asymmetric protrusion.
Reuse the existing `Facing`/relative-face offsets and `IgnoreSurfaceSnap` tile
properties so both placement and rotation select the intended face.

For the selected option, first build a plain greybox with only the bed, supports,
actuator, and ram. Render all four faces at the **final in-game pixel size** and
review them on a table before adding grain, rivets, and forge texture. After the
shape is approved, finish the materials, run the four-face footprint checks, and
then inspect placement and rotation in the client. This catches silhouette and
occlusion errors before detailed modeling work.

The concept images were generated with built-in imagegen. Their prompts share
this brief: isolated three-quarter orthographic game-prop concept, antique dark
red-brown wood and weathered forged iron, square tabletop base, centered
mechanism, bilateral supports, no side projection, no text or ammunition. The
option-specific subjects are a central screw with a symmetric T grip, a short
front/back centered lever, and a centered horizontal top wheel, respectively.
