# Crossbow model pipeline

`source-assets/blender/AuxiliasCrossbowAssets.blend` is the editable source of truth,
authored in Blender 5.2 LTS. It contains nine crossbow states (relaxed, Metal loaded,
Stone loaded for each of three tiers), four intact/broken loose bolts, and three
crafting components (shaft, Metal head, Stone head). Edit this
file directly; `tools/export_assets.py` only evaluates, exports and validates copies.
It never rebuilds geometry or saves the source. The former `generate_assets.py`
entry point delegates to the exporter for compatibility.

Inventory artwork remains independently authored under `source-assets/icons`.
Workshop artwork is synchronized separately by `tools/sync-workshop-art.ps1`.

## Editing the Blender source

- `01 - Crossbows - editable parts` contains the nine named export collections.
  The file opens with the standard empty crossbow visible. Toggle collection
  visibility to inspect another tier/state; the assets retain their shared game origin.
- Each collection contains named body, groove, limb, string, lock, trigger and binding
  parts. Common body meshes are linked between the three states of a tier. Edit their
  mesh data to keep the states synchronized; keep their object transforms identical.
- `02 - Canonical bolts` owns the loose-bolt meshes. Loaded instances share those mesh
  datablocks and use translation only, so a bolt cannot silently change size on loading.
- Broken bolts share the actual intact head/socket or stone head/binding meshes. Their
  shorter shafts have an integral uneven fracture instead of separate splinter rods.
- `03 - Crafting components` contains centered, translation-only linked copies of the
  canonical shaft and heads. These replace the Small Handle, Nails and Chipped Stone
  model placeholders for the existing component items.
- Small binding parts retain an editable Decimate modifier. Export evaluates it on a
  temporary copy. Planar body faces remain editable instead of being permanently triangulated.
- Limb and string meshes store cross-section ring indices in `mechanical_rings`.
  Export remeasures actual world-space centerlines, radii, symmetry and nock seating,
  in addition to checking fingerprints and transforms. Intentional changes require
  updating the measured Blender reference. Stored lengths or fingerprints alone
  cannot bypass the actual mesh length-conservation checks.
- The packed `AuxiliaCrossbowAtlas` image is the runtime texture source. Its external
  copy is `source-assets/blender/textures/AuxiliaCrossbowAtlas.png`. The separate
  `Atlas materials - bake workspace` scene preserves editable material swatch nodes.
  After rebaking an already packed image, save the updated PNG, load it into a fresh
  image datablock, replace material references and repack; verify a reopened file uses
  the new pixels. Blender can otherwise retain the previous packed payload.

The three tiers share the compact mechanical layout. Light has a more tapered carved
wooden butt and a wooden prod; standard uses darker prod/lock reinforcement; Heavy
combines dark wood with dark steel and restrained edge wear. The stock's rear surfaces
were refined while preserving the support-hand region and weapon origin. The front
joint and fore-end moved forward by 0.020 in the braced-silhouette revision.
Side and end faces now have noncollapsed UVs. Grain follows each part's long direction.
The atlas is 512×512, retains the seven material regions, and is shared by all sixteen
models. Preview lighting uses a 100 W key and 45 W fill at exposure 0; it is an inspection
studio, not a simulation of the game's lighting.

## Coordinate frame

Project Zomboid firearm models use:

- X for left/right width.
- Y for the forward/muzzle direction.
- Z for height.
- The trigger/action close to `(0, 0, 0)`.

Installed vanilla long-gun meshes occupy approximately Y `-0.18` to `0.50`. The crossbows deliberately use the same origin convention so the existing `Rifle` animation does not attach the character at the center or butt of the weapon.

Blender exports with `-Y` forward and `Z` up. The FBX files carry centimeter unit metadata, so every game model block uses `scale = 0.01`. The model blocks live in `module Base`, while each item uses an unqualified `WeaponSprite` name; these details are required by Build 42's equipped-model lookup. The items use `AttachmentType = Shovel` only for the hotbar back slot because its broad-head attachment rolls the crossbow prod flat against the back. Held aiming still uses `SwingAnim = Rifle` and the existing two-handed rifle animation set.

The game-export copy receives a baked 180-degree X-axis correction. Blender's own FBX importer restores the authored axes from metadata, while Project Zomboid otherwise reads both the longitudinal and height axes reversed. Every asset is also collapsed to one FBX material, matching the vanilla firearm meshes; per-part colors remain encoded in the single shared `AuxiliaCrossbowAtlas.png` UV texture. Multiple material slots caused Build 42 to omit non-primary weapon parts in game.

Dropped crossbows do not reuse the vanilla long-gun side-resting transform. That transform makes model X vertical, which is harmless for a narrow firearm but stands a 25–31 cm crossbow prod on edge and sends one limb below the floor. Every relaxed and loaded crossbow model instead uses `world` rotation `0 -90 0`, placing the authored X/Y top plane parallel to the floor with positive Z facing up. A `0.026` first-axis offset clears the lowest tiller and tickler geometry while retaining the existing longitudinal centering.

| Asset | Width X | Length Y | Height Z |
|---|---:|---:|---:|
| Light Crossbow (relaxed / Metal loaded / Stone loaded) | 0.242 / 0.213 / 0.213 | 0.341 / 0.364 / 0.364 | 0.059 / 0.063 / 0.063 |
| Crossbow (relaxed / Metal loaded / Stone loaded) | 0.270 / 0.246 / 0.246 | 0.341 / 0.364 / 0.364 | 0.060 / 0.063 / 0.063 |
| Heavy Crossbow (relaxed / Metal loaded / Stone loaded) | 0.303 / 0.283 / 0.283 | 0.342 / 0.364 / 0.364 | 0.061 / 0.063 / 0.063 |
| Metal Bolt | 0.013 | 0.145 | 0.012 |
| Stone Bolt | 0.013 | 0.145 | 0.014 |
| Broken Metal Bolt | 0.010 | 0.097 | 0.010 |
| Broken Stone Bolt | 0.007 | 0.097 | 0.013 |
| Bolt Shaft | 0.005 | 0.115 | 0.005 |
| Metal Bolt Head | 0.010 | 0.036 | 0.010 |
| Stone Bolt Head | 0.004 | 0.029 | 0.013 |

All three equipped models use the vanilla sawn-off double-barrel shotgun hand envelope (approximately `0.357` long and `0.076` high) as their common size reference. Their limbs remain wider than a firearm by design, while length, rear overhang, and vertical bulk stay compact to reduce arm and torso clipping.

The tier silhouettes intentionally avoid pulleys, permanently attached windlasses, pistol grips, foregrips, cheek pads, attached bolt racks, and decorative braces. Every model is built around a continuous wooden tiller, a shallow two-lip bolt groove, an antler-like transverse string nut, a long under-tiller tickler, the prod, and the string. The standard model uses flush dark-horn reinforcement around the nut; only the late Heavy model retains compact blackened-iron side plates and a cross pin. The Heavy model uses dark hardwood rather than an implausible solid-iron tiller.

Each prod is sampled from a fixed three-dimensional limb length: the relaxed and cocked versions change rearward curvature and tip position without stretching or shortening either limb. Its top-view chord stays narrow (`0.009`, `0.010`, and `0.012`) independently of span, bend, and vertical thickness, producing a slim curved-band silhouette instead of a broad crescent. The root is centred at `Z = 0.018` inside the full-height rectangular wooden fore-end; the tiller stops only `0.007`, `0.007`, or `0.008` beyond that joint instead of continuing beneath the bow. Both limbs then rise `0.016` toward their nocks, placing the string and bolt power axis `0.004` above the fore-end top.

This layout follows surviving fifteenth-century construction rather than a modern top-mounted limb pocket. The Count Ulrich V crossbow has a horizontal fore-end cutout for the bow, a transverse bridle hole, and a full-height vertical rivet against splitting; period composite bows were tied through that hole with looped hemp binding. The authored models represent the same load path with an embedded root, a visible transverse cord pass, paired exposed bridle strands, and a front rivet while leaving the central bolt gutter clear. Light uses a wooden prod and plain hemp, standard uses a dark bark-wrapped composite silhouette with hemp and leather, and Heavy uses a late-medieval steel prod with heavier hemp/leather binding. See [The Crossbow of Count Ulrich V](https://resources.metmuseum.org/resources/metpublications/pdf/The_Crossbow_of_Count_Ulrich_V_of_Wurttemberg_The_Metropolitan_Museum_Journal_v_44_2009.pdf) and [A Deadly Art: European Crossbows, 1250–1850](https://resources.metmuseum.org/resources/metpublications/pdf/A_Deadly_Art_European_Crossbows_1250_1850.pdf).

The empty crossbows are braced: their strings remain installed and taut. The relaxed prods have rearward tip sweeps of 0.026, 0.032 and 0.038, creating a shallow arch with a separate straight string chord. This removes the former near-straight T silhouette. Strings run through the limb-tip centerlines, with measured vertical nock margins of 0.0023, 0.0029 and 0.0039. Actual tube radii are 0.0012, 0.00135 and 0.0016. Each cocked curvature is solved to reach the existing nut while conserving string and sampled 3D limb length. Allowed drifts remain 0.00001 and 0.0002, with at least 0.0005 surrounding vertical tip material. Export measures these constraints directly from the mesh. See [the braced-silhouette review](DESIGN-REFRESH-2026-09-19.md) for historical references, before/after views and the coupled bolt edit.

Each cocked model includes the same canonical bolt used by the loose world item. The drawn string, bolt axis and groove share one Z = 0.034 power axis. The front surface of the string tube is tangent to the back of the nock. Both complete bolts now measure about 0.145 m in the compact game envelope: their bare middle shafts gained 0.020 m, matching the fore-end extension. Head size, shaft thickness and fletching remain unchanged. Loading applies translation only at scale 1.0; measured loaded/world dimension differences remain below 0.000001. The nut station is retained, and both point types still project about 0.030 m beyond the prod. These are game-envelope dimensions, not claimed measurements of a historical full-size crossbow.

At runtime `AuxiliaCrossbow_ModelState.lua` selects the Metal- or Stone-Bolt cocked model whenever the equipped weapon contains its one bolt, selects the relaxed model when empty, and forces the relaxed model at both the weapon-swing hit point and attack-finished events so the bolt disappears and the string returns to its straight braced position. A fired-weapon latch keeps the relaxed model authoritative until the client observes the empty weapon, preventing delayed ammo synchronization from briefly redrawing the loaded state. The implementation follows the same Build 42 `setWeaponSprite` plus `resetEquippedHandsModels` mechanism used by vanilla fishing rods.

## Vanilla firearm hand and color references

The compact hand section was checked against six installed vanilla firearm meshes: sawn double-barrel shotgun, sawn pump shotgun, sawn shotgun, hunting rifle, varmint rifle, and lever-action rifle. The exact `JS_2000_Sawn` support-hand region (`Y = 0.060..0.150`) is approximately `0.016` wide and occupies `Z = 0.001..0.034`. Each crossbow now uses one continuous tapered tiller: the rear/action width is `0.024..0.028`, the lock width is `0.020..0.024`, and the support-hand body narrows to `0.016..0.020` while lifting its lower surface above `Z = 0`. This preserves a readable shoulder stock without placing a deep rectangular body through the supporting palm.

The earlier palette study sampled installed `ShotgunDoubleBarrelSawn`, `HuntingRifle`,
`VarmintRifle`, and `LeverActionRifle` textures. The authored atlas retains a muted
wood/iron palette with directional grain and restrained wear. Its baked color detail
is present in the game texture as well as the preview. Moderate studio lighting and
a shared matte material keep the material regions distinguishable.

## Export and validate

From the repository root, run:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --factory-startup --disable-autoexec --python-exit-code 1 --python 'mods\auxilias-crossbow\tools\export_assets.py'
& .\tools\validate.ps1
```

Use `-- --verify-only --no-render` after the exporter path to compare existing game
assets with the authored source without replacing them. Use `-- --no-render` to skip
only preview rendering during an export. Run tools/test_asset_mechanics.py with
the same Blender command prefix for the baseline and four adversarial geometry checks. The target release directory is read from
`config/project-zomboid.json`. Export never saves the source; a SHA-256 check enforces it.

Export fails for an invalid weapon envelope, zero-area geometry, collapsed UV
triangles, a broken canonical-bolt link, or an unremeasured limb/string edit. Every
FBX must re-import as one mesh/material/UV layer, and every triangle's position,
winding and UV coordinates must match within 0.000001. All sixteen files are
validated in staging before the installable tree is updated. The ignored
`work/model-validation` directory receives:

- `report.json` with source/FBX/atlas hashes, topology, bounds, UVs and round-trip results.
- Isometric, top, side, and front PNG renders for all nine relaxed/Metal-loaded/Stone-loaded crossbow states.
- Isometric renders of the four canonical loose bolts and three crafting components.

The renders use the same generated texture atlas and UV coordinates referenced by the game model scripts. They are not diffuse-color-only previews.

## Item icons

Ten transparent 128×128 pixel masters live under `source-assets/icons`: three crossbows, material-specific intact and broken bolts, Bolt Shaft, Metal Bolt Head, and Stone Bolt Head. Each stores a native 32×32 sprite enlarged four times. Their full-resolution ImageGen originals are kept in `source-assets/icons/generated`, with prompts alongside the masters. Current model renders supplied shape references; the inventory images were authored separately. They use a shared muted 24-color material palette, binary transparency and simple pixel clusters based on inspected vanilla icons. Build 42's hotbar receives native 32×32 textures.

Broken-bolt artwork shows the recoverable head-side fragment at about two thirds of the intact icon's span. The compact fracture is integral to the wood, matching the world models; the icons have no detached chip or fletching. The world models retain the intact bolt's shaft thickness and head size and measure about 67% of its complete length.

Use `tools/prepare-icon-masters.ps1` with PowerShell 7 to rebuild pixel masters from
the retained ImageGen originals, then `tools/sync-icons.ps1` to install them using
nearest-neighbor sampling. The model exporter does not rewrite icons. Static
validation verifies that all ten runtime icons are 32×32, retain alpha and remain
mutually distinct. See [the icon review](ICON-REFRESH-2026-09-18.md).

Loose bolts now have tapered carved shafts, slim shaped fletching, ridged hemp wraps,
a necked forged bodkin or a faceted lenticular stone point. The two lower vanes are
raised slightly around the shaft and the heads widen beyond the fore-end. Export
checks the underside against the stock (including head-edge crossings at its front)
and the vanes against the groove lips, with at least 0.15 mm clearance. The exact
nock contact plane is retained; the longer bolt and revised limb/string coordinates
were remeasured together for the braced-silhouette revision.

The existing four loose-bolt world attachments are retained. Earlier
`_placed.png` images are historical placement evidence; the current exporter writes
`_iso.png` inspection renders. The `world` attachment's 90° X-axis correction and
ground-contact pivot lay the bolt across the floor while preserving randomized
within-tile offsets and Z rotation. **Place Item** remains controlled by the player's
cursor and rotation keys. The three new component attachments use the crossbows'
authored-top-up world rotation, center their length, and clear their lowest surface
by 0.2–0.4 mm. Placement and the smaller crafting props must still be checked in the client.

## Visual acceptance

- Each limb is one continuous tapered mesh from socket to tip, with no floating segments.
- The relaxed string is straight between the tips; the cocked string touches both tips and the central catch without changing total length.
- The string tube seats directly into both limb-tip surfaces with no spacer, air gap, or visible deep intersection from top, side, or isometric views.
- The cocked limbs bend rearward and inward while retaining the relaxed three-dimensional limb length and the same shallow rise toward both nocks.
- The tiller, shallow bolt groove, string nut, long two-part tickler, embedded prod root, bridle, limbs, and string visibly connect.
- No tall rectangular rail, block-shaped string catch, exposed sear bar, solid-iron tiller, or attached bolt rack remains in the silhouette.
- The groove and loaded bolt remain visually continuous across the prod centre; paired bridle strands remain outside the central channel.
- The tiller terminates at the prod joint, the root remains inside the fore-end, and both nocks rise to the power axis just above the wood instead of placing the whole bow on a raised block.
- Standard horn reinforcement and Heavy iron side plates remain flush with the wooden tiller, and the long tickler visibly joins the underside of the lock area.
- In each cocked model, the loaded bolt lies centered in the groove, its rear nock face touches the drawn string, and the correct metal or stone head/fletching combination remains visible.
- The loaded Metal or Stone Bolt retains exactly the same dimensions as its corresponding loose world model on all three crossbows; only translation changes, and the point projects about 30 mm beyond the prod.
- The limb centres, string centreline, and loaded bolt centreline share the declared power axis; the string touches only the rear nock face and never penetrates the bolt mesh.
- Light, standard, and Heavy models have distinct material treatment and progressively wider, thicker limbs while sharing one compact length.
- No model is mirrored, rotated onto its side, or centered on the butt after FBX re-import.
- In the back hotbar slot, the broad prod lies close and approximately parallel to the character's back instead of projecting rearward like a rifle-mounted crossbar.
- Equipped and aimed views in both left- and right-facing directions must be checked interactively in Project Zomboid after changing dimensions or the origin. Reloading must visibly add the selected Metal or Stone Bolt and change to the cocked model, firing must visibly remove the bolt and return to the relaxed model, and unloading must also return to relaxed. Dropped-item checks are part of the later practical test.

The Build 42.20.2 client check loads and aims all three weapons in an isolated debug scenario. Direct-window screenshots in both aim directions are used to confirm complete single-material rendering, compact torso clearance, forward-facing limbs, correct top/bottom orientation, and two-handed alignment for Light, standard, and Heavy models.
