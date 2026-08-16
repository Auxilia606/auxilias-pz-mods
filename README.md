# Auxilia's Crossbow

Current version: **0.1.0**

An original crossbow mod for Project Zomboid 42.20.

The first playable test build adds three non-modern, craftable crossbows:

- Improvised Crossbow — short-ranged, light, and comparatively fragile.
- Reinforced Crossbow — a better wooden hunting weapon.
- Heavy Arbalest — a slow, heavy, historically inspired steel-prod crossbow.

All three use recoverable Metal or Stone Bolts. An unloaded crossbow can switch ammunition material from its inventory context menu, after which the normal reload and unload controls use that material. Metal Bolts have a 70% intact recovery chance; easier-to-source Stone Bolts have a 45% intact recovery chance. Both require vanilla Chicken or Turkey Feathers for fletching.

## Repository layout

- `workshop/Contents/mods/AuxiliasCrossbow` — the installable Project Zomboid mod.
- `source-assets/blender` — reproducible Blender source and asset generator.
- `docs` — balance notes, test procedure, and deferred multiplayer concerns.
- `tools` — validation and local deployment helpers.

The Blender generator also re-imports every exported FBX and produces multi-angle validation renders. See `docs/MODELING.md` for the coordinate convention, measured bounds, and visual acceptance checklist.

## Target

- Project Zomboid stable 42.20
- Single-player first
- English and Korean translations

Multiplayer compatibility should be considered when designing new systems so that
future support is not needlessly blocked. Dedicated multiplayer implementation,
empirical testing, and an official multiplayer-support claim are the lowest
development priority and are deferred until the single-player work is complete.

See `docs/TESTING.md` for installation and the debug test-kit workflow.

## Recipe balance

Crafting times, tools, workstations, materials, skill gates, and XP awards are calibrated against the installed stable 42.20.2 vanilla recipes. The comparison includes every Auxilia crafting recipe and records each previous and adjusted value in the [vanilla recipe alignment report](docs/VANILLA-RECIPE-ALIGNMENT.md).

## Package

Run `tools/package.ps1` to validate the mod and create a versioned release ZIP plus a SHA-256 checksum in `dist`. The ZIP contains `workshop.txt`, `preview.png`, and `Contents` at its root, ready to extract into a Project Zomboid Workshop folder.

## Verification status

The 0.1.0 package was loaded by the installed Project Zomboid 42.20.2 dedicated server. The server reached `SERVER STARTED` with no Auxilia's Crossbow registry, script, model, or Lua errors, and its original five crafting recipes appeared in the game's generated recipe index. Follow-up interactive playtesting confirmed all three crossbows in game and verified bolt generation. The final vanilla-aligned, material-specific ammunition build also passed an isolated 42.20.2 server load: both ammo registries, all new items, and all eleven current recipes were accepted exactly once without an Auxilia-related error or warning. Ammunition switching, player-speed-adjusted crafting duration, and exact recovery behavior remain interactive acceptance checks. See `docs/SMOKE-TEST.md` and `docs/TESTING.md`.

## License

This repository is licensed under the [MIT License](LICENSE).

Project Zomboid and related trademarks belong to The Indie Stone. Auxilia's
Crossbow is an unofficial community mod and is not affiliated with or endorsed
by The Indie Stone.
