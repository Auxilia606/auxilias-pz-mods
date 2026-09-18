# Dedicated item icons

These ten transparent 128×128 PNG files are pixel masters for the inventory icons. Each represents a 32×32 native sprite enlarged exactly four times. They are independent of the FBX meshes and model atlas. The game receives 32×32 copies because Build 42's hotbar draws item textures at native size; installing the masters directly makes a weapon overlap neighboring slots.

The full-resolution original artwork is retained in `generated/`. It was created with the built-in ImageGen tool, one call per icon, using the current model renders as shape references and locally inspected vanilla icons as style references. The complete prompt set is `generation-prompts.json`. Vanilla reference artwork is not included in the mod or its authored assets.

Run `tools/prepare-icon-masters.ps1` with PowerShell 7 to frame the generated artwork, reduce it to the native 32px grid, quantize it to a shared 24-color wood/metal/stone/cord palette and binary transparency, and store the four-times-enlarged masters. Run `tools/sync-icons.ps1` to install the 32px textures using nearest-neighbor sampling. The Blender exporter does not generate or synchronize icons.

The style follows vanilla's small pixel clusters, muted materials and restrained highlights. Crossbows depict the actual relaxed models, including wooden stocks, tier-specific prods and the long underside trigger. Metal bolts have brown fletching and gray bodkins; Stone bolts have light fletching and knapped points. Broken bolts depict only the recoverable head-side fragment, at about two thirds of the intact icon's span, with an integral compact fracture and no detached chip or fletching.

Eight icons were refreshed for the braced-crossbow and longer-bolt revision; the two head icons retain their existing artwork. See `../../docs/DESIGN-REFRESH-2026-09-19.md` for the current preview and measured scope, and `../../docs/ICON-REFRESH-2026-09-18.md` for the original vanilla-style audit.

Both broken-bolt icons were subsequently narrowed after native-size review. Their pre-edit generated inputs are retained in `generated/history/2026-09-19-before-slimming/`; the current prompt entries record the edit and those input snapshots.
