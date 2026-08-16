# Auxilia's Crossbow

Current version: **0.1.0**

An original crossbow mod for Project Zomboid 42.20.

The first playable test build adds three non-modern, craftable crossbows:

- Improvised Crossbow — short-ranged, light, and comparatively fragile.
- Reinforced Crossbow — a better wooden hunting weapon.
- Heavy Arbalest — a slow, heavy, historically inspired steel-prod crossbow.

All three use recoverable Standard Bolts. A successful hit places either an intact bolt or a broken bolt in the target's inventory, so it can be recovered from zombie and animal corpses. The current break chance is 30%.

## Repository layout

- `workshop/Contents/mods/AuxiliasCrossbow` — the installable Project Zomboid mod.
- `source-assets/blender` — reproducible Blender source and asset generator.
- `docs` — balance notes, test procedure, and deferred multiplayer concerns.
- `tools` — validation and local deployment helpers.

## Target

- Project Zomboid stable 42.20
- Single-player first
- English and Korean translations

See `docs/TESTING.md` for installation and the debug test-kit workflow.

## Package

Run `tools/package.ps1` to validate the mod and create a versioned release ZIP plus a SHA-256 checksum in `dist`. The ZIP contains `workshop.txt`, `preview.png`, and `Contents` at its root, ready to extract into a Project Zomboid Workshop folder.

## Verification status

The package has been loaded by the installed Project Zomboid 42.20.2 dedicated server. The server reached `SERVER STARTED` with no Auxilia's Crossbow registry, script, model, or Lua errors, and all five crafting recipes appeared in the game's generated recipe index. Follow-up interactive playtesting confirmed all three crossbows in game and verified bolt generation. See `docs/SMOKE-TEST.md`.
