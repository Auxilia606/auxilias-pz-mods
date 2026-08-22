# Ammunition icon sources

The `Item_AuxAmmo*.png` files are the 128×128 source-of-truth inventory icons. Run
`tools/sync-icons.ps1 -Mod auxilias-ammunition` from the repository root to install their
32×32 runtime copies.

The component set uses a shared brief: Project Zomboid-inspired hand-painted realism,
warm upper-left lighting, transparent backgrounds, centered silhouettes, and restrained
rust-orange highlights. Each projectile, casing family, shot component, and primer must
remain identifiable without text at 32×32. The fired shotgun mold retains its original
high-resolution source as `AuxAmmoShotgunMold-source.png`.
