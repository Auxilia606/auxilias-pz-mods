# Auxilia's Crossbow

Current version: **0.2.0**

An original crossbow mod for Project Zomboid 42.20.

The first playable test build adds three non-modern, craftable crossbows:

- Light Crossbow — short-ranged, light, and comparatively fragile.
- Crossbow — a sturdier wood-and-iron hunting weapon.
- Heavy Crossbow — a slow, powerful compact crossbow built primarily from forged iron.

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

Post-release bug and balance reports follow the evidence and release gates in
`docs/STABILIZATION.md`. The next feature release is scoped in `docs/ROADMAP.md`.

## Distribution status

Versions before 1.0.0 are development and test builds distributed through GitHub and
the local Workshop deployment workflow. Public Steam Workshop publication is deferred
until the 1.0.0 quality gate so the first Workshop release represents the intended
complete mod rather than an early playable milestone.

## Recipe balance

Crafting times, tools, workstations, materials, skill gates, and XP awards are calibrated against the installed stable 42.20.2 vanilla recipes. The comparison includes every Auxilia crafting recipe and records each previous and adjusted value in the [vanilla recipe alignment report](docs/VANILLA-RECIPE-ALIGNMENT.md).

## Package

Run `tools/package.ps1` to validate the mod and create a versioned release ZIP plus a SHA-256 checksum in `dist`. The ZIP contains `workshop.txt`, `preview.png`, and `Contents` at its root, ready to extract into a Project Zomboid Workshop folder.

GitHub Actions repeats validation and package auditing for every change to `master` and
for every pull request. A matching semantic-version tag such as `v0.2.0` creates a
GitHub release from the audited ZIP and checksum. A `master` update also backfills a
missing release for the current tagged version without replacing an existing release.

## Verification status

The 0.1.0 package and every post-release development milestone were loaded by the installed Project Zomboid 42.20.2 server or client without an Auxilia-related registry, script, model, or Lua error. Both ammunition registries, all current items, and all eleven recipes were accepted exactly once. The project owner completed the final single-player integration procedure on 2026-08-17, covering ammunition switching and preservation, crafting, firing, recovery, balance, loot, and English/Korean presentation. The 0.2.0 asset pipeline additionally round-tripped distinct Metal and Stone Bolt models and verified all nine generated item icons. See `docs/SMOKE-TEST.md` and `docs/TESTING.md`.

## License

This repository is licensed under the [MIT License](LICENSE).

Project Zomboid and related trademarks belong to The Indie Stone. Auxilia's
Crossbow is an unofficial community mod and is not affiliated with or endorsed
by The Indie Stone.
