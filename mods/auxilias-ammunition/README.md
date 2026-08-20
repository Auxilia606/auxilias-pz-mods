# Auxilia's Ammunition

Current version: **1.0.0**
Target: **Project Zomboid Build 42.20** (audited against 42.20.2)

Auxilia's Ammunition turns Build 42's existing pottery, kiln, furnace, charcoal,
foraging, farming, metalworking, and Hand Press systems into a late-game ammunition
production loop. It adds no skill, workstation, firearm override, or runtime framework.

## Production loop

1. Shape reusable projectile molds at a Pottery Bench and fire them in a Kiln.
2. Smelt renewable/foraged metals and cast projectiles at a Furnace.
3. Form casings, hulls, and primers at the vanilla Hand Press.
4. Process compost, limestone, and charcoal into an ammo-only survival propellant.
5. Press batches of ten rounds using projectile + casing + propellant + primer.

The final outputs are the nine vanilla ammunition items, so vanilla guns and mods that
consume vanilla ammo continue to work without patches. Factory primers remain a rare loot
shortcut. High skill levels automatically reveal recipes so existing saves are not locked
out if their manuals were generated before the mod was added.

## Installation

Copy the contents of `workshop` into a Project Zomboid Workshop staging directory, or
subscribe to the published Workshop item. Enable **Auxilia's Ammunition** when creating or
loading a world. Servers and every connecting client must use the same version.

## Compatibility and scope

- Supports `9mm`, `.38 Special`, `.357 Magnum`, `.45 Auto`, `.44 Magnum`, `5.56mm`,
  `.30-30`, `.308`, and shotgun shells.
- Does not override `Base` ammunition or firearms.
- Does not recover spent casings in v1.0.0; no firing event hooks are installed.
- Uses one server-side Lua file only for procedural loot injection.
- Other mods can consume the vanilla output. Adding recipes for their custom calibers is
  intentionally left to compatibility patches.

## Documentation

- [Vanilla ammunition audit](docs/VANILLA-AMMO-AUDIT.md)
- [System design](docs/DESIGN.md)
- [Balance tables](docs/BALANCE.md)
- [Testing and known limits](docs/TESTING.md)
- [1.0.0 release validation report](docs/reports/RELEASE-VALIDATION-1.0.0.md)
- [Changelog](CHANGELOG.md)

Build a release candidate with `tools/package.ps1`. The archive and its SHA-256 sidecar are
written to `dist` after validation and an archive-content audit.
