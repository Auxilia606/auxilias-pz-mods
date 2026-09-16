# Ammunition icon sources

The `Item_AuxAmmo*.png` files are the 128×128 source-of-truth inventory icons. Run
`tools/sync-icons.ps1 -Mod auxilias-ammunition` from the repository root to install their
32×32 runtime copies.

The component set uses a shared brief: Project Zomboid-inspired hand-painted realism,
warm upper-left lighting, transparent backgrounds, centered silhouettes, and restrained
rust-orange highlights. Each cartridge body and powder component must remain
identifiable without text at 32×32.

The body, carbon, and nitrogenous-mix icons are generated reproducibly by
`generate_body_icons.py` (Pillow). The ammunition bodies show a paired projectile
and casing or shot and hull. The carbon icon uses a dark fragment pile so it remains
distinct from crushed mineral powder and the field-powder jar. The nitrogenous mix
sits in a shallow olive-filled bowl so it does not look like either powder pile.
Rerun the generator before `tools/sync-icons.ps1` if changing their artwork.
