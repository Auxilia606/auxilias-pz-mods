# Dedicated item icons

These ten transparent 128×128 PNG files are the authored inventory-icon source of truth. They are intentionally independent from the FBX meshes and their palette textures. The game receives 32×32 downsampled copies because Build 42's hotbar draws item textures at native size; installing the masters directly makes a weapon overlap neighboring slots.

`source-assets/blender/generate_assets.py` downsamples this set into the mod during asset generation, then validates source and runtime dimensions, alpha coverage, and canvas margins. `tools/sync-icons.ps1` performs the same runtime sync without rebuilding the 3D assets. Neither path renders inventory icons from the 3D scene.

The set uses a shared visual brief: a compact hand-painted survival-game inventory sprite, muted earth colors, a crisp dark-brown painted outline, restrained upper-left highlights, transparent background, one centered object, no cast shadow, no text, and a silhouette that remains legible at 128×128. Each source subject was based on the corresponding Auxilia item, while the Stone Bolt Head was authored as a compact knapped projectile point distinct from the broad vanilla Sharp Flint Flake.
