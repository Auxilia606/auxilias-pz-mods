# Auxilia's Crossbow

> 이 프로젝트는 [Auxilia Project Zomboid 모노레포](../../README.md)의 독립 배포 모드다.

Current version: **0.2.1**

An original crossbow mod for Project Zomboid 42.20.

The first playable test build adds three non-modern, craftable crossbows:

- Light Crossbow — short-ranged, light, and comparatively fragile.
- Crossbow — a sturdier wood-and-iron hunting weapon.
- Heavy Crossbow — a slow, powerful compact crossbow with a dark hardwood tiller, steel prod, and reinforced iron fittings.

All three use recoverable Metal or Stone Bolts. An unloaded crossbow can switch ammunition material from its inventory context menu, after which the normal reload and unload controls use that material. Metal Bolts have a 70% intact recovery chance; easier-to-source Stone Bolts have a 45% intact recovery chance. Both can be fletched with vanilla Chicken or Turkey Feathers, or with clean Denim or Leather Strips cut from clothing.

## Repository layout

- `workshop/Contents/mods/AuxiliasCrossbow` — the installable Project Zomboid mod.
- `source-assets/blender` — editable Blender source, packed atlas, and texture copy.
- `docs` — balance notes, test procedure, and deferred multiplayer concerns.
- `tools` — validation and local deployment helpers.

The reusable development process behind this repository is documented in
[`shared/knowledge/MOD-DEVELOPMENT-WORKFLOW.md`](../../shared/knowledge/MOD-DEVELOPMENT-WORKFLOW.md). It generalizes
the project's research, vertical-slice implementation, layered validation, clean
deployment, evidence recording, and release workflow for use in other Project Zomboid
mods.

`tools/export_assets.py` reads the authored `.blend`, exports evaluated copies, re-imports every FBX, and produces multi-angle validation renders without rebuilding or saving the source. See `docs/MODELING.md` for the editing workflow, coordinate convention, and visual acceptance checklist.

The model set includes nine crossbow states, four intact/broken bolts, and dedicated
shaft/Metal-head/Stone-head crafting components. Loaded, loose, broken and component
models share their corresponding canonical meshes. The September 17 bolt refinement
passed Blender and package checks; its updated geometry and new crafting props still
need a fresh in-game visual check. See [the bolt-family review](docs/BOLT-FAMILY-REVIEW-2026-09-17.md).

All ten item icons now follow the inspected vanilla inventory style: muted pixel
sprites, native 32×32 sizing, and shapes matched to the current models. See the
[icon preview and reference review](docs/ICON-REFRESH-2026-09-18.md).

## Target

- Project Zomboid stable 42.20
- Single-player first
- English and Korean translations

Multiplayer compatibility should be considered when designing new systems so that
future support is not needlessly blocked. Dedicated multiplayer implementation,
empirical testing, and an official multiplayer-support claim are the lowest
development priority and are deferred until the single-player work is complete.

See `docs/TESTING.md` for installation and the debug test-kit workflow. The focused
0.2.1 release-candidate pass is in `docs/RELEASE-TEST-0.2.1.md`.

Post-release bug and balance reports follow the evidence and release gates in
`docs/STABILIZATION.md`. The next feature release is scoped in `docs/ROADMAP.md`.

## Distribution status

Versions before 1.0.0 are development and test builds distributed through GitHub and
the local Workshop deployment workflow. Public Steam Workshop publication is deferred
until the 1.0.0 quality gate so the first Workshop release represents the intended
complete mod rather than an early playable milestone.

## Recipe balance

Crafting times, tools, workstations, materials, skill gates, XP awards, and repairs are calibrated against installed vanilla recipes. The [vanilla recipe alignment report](docs/VANILLA-RECIPE-ALIGNMENT.md) records the original calibration and current adjustments. Bolts can be assembled singly or in batches of five; the Heavy Crossbow recipe auto-unlocks at Maintenance 4 and Blacksmith 6. Each unloaded Crossbow tier has its own repair recipe. Repeated repairs use Build 42's diminishing material efficiency but can still restore the weapon completely; the Heavy Crossbow must be repaired at an Advanced Forge.

## Package

From the monorepo root, run `tools/package.ps1 -Mod auxilias-crossbow` to validate the mod and create a versioned release ZIP plus a SHA-256 checksum in `dist/auxilias-crossbow`. The ZIP contains `workshop.txt`, `preview.png`, and `Contents` at its root, ready to extract into a Project Zomboid Workshop folder.

GitHub Actions repeats validation and package auditing for every change to `master` and
for every pull request. A namespaced semantic-version tag such as `auxilias-crossbow/v0.2.1` creates a
GitHub release from the audited ZIP and checksum. A `master` update also backfills a
missing release for the current tagged version without replacing an existing release.

## Verification status

The latest [crossbow and linked-item design review](docs/DESIGN-REFRESH-2026-09-19.md) shows the revised braced/loaded silhouettes, matched bolt lengths, independent icons and measured asset checks. The new dimensions still need an in-game pose and placement review; older client checks below do not validate this revision.

The 0.1.0 package and earlier post-release development milestones were loaded by the installed Project Zomboid 42.20.2 server or client without an Auxilia-related registry, script, model, or Lua error. Both ammunition registries, all earlier items, and the original eleven recipes were accepted exactly once. The project owner completed the final single-player integration procedure on 2026-08-17, covering ammunition switching and preservation, crafting, firing, recovery, balance, loot, and English/Korean presentation. On 2026-08-23, the project owner also passed the Build 42.20.3 client, existing-save, and multiplayer compatibility checks, including aimed-firearm targeting, Metal/Stone Bolt behavior, muzzle-light suppression, vanilla firearm lighting, and remote shot synchronization. The asset pipeline round-trips separate Metal and Stone Bolt models plus fixed-length relaxed/cocked states for all three crossbows. It also validates ten dedicated hand-painted item icons independently from the 3D models. See `docs/SMOKE-TEST.md` and `docs/TESTING.md`.

## License

This repository is licensed under the [MIT License](../../LICENSE).

Project Zomboid and related trademarks belong to The Indie Stone. Auxilia's
Crossbow is an unofficial community mod and is not affiliated with or endorsed
by The Indie Stone.
