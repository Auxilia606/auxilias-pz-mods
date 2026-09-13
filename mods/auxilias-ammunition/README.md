# Auxilia's Ammunition

Current version: **1.1.0** (release candidate; redesigned crafting has not completed in-game acceptance)
Target: **Project Zomboid Build 42.20** (vanilla balance audited against 42.20.2; v1.0.0 runtime tested on 42.20.3)

Auxilia's Ammunition turns Build 42's existing pottery, kiln, furnace, charcoal,
foraging, metalworking, and Hand Press systems into a late-game ammunition
production loop. It adds no skill, workstation, firearm override, or runtime framework.

## Production loop

1. Shape reusable molds at a Pottery Bench and fire them in a Kiln.
2. Cast a caliber-family cartridge body from iron and copper at a Furnace. Each body
   represents its projectile and casing together; shotgun bodies also use ripped sheets.
3. Crush ordinary stone or limestone into mineral powder, grind charcoal or coke into
   carbon powder, and combine the two on any surface into ammo-only field powder.
4. Form primers at the vanilla Hand Press, then press batches of ten rounds using body +
   field powder + primer.

The final outputs are the nine vanilla ammunition items, so vanilla guns and mods that
consume vanilla ammo continue to work without patches. Factory primers remain a rare loot
shortcut. High skill levels automatically reveal recipes so existing saves are not locked
out if their manuals were generated before the mod was added.

Cartridge bodies, primers, and the fired shotgun mold use dedicated icons so components
that frequently share an inventory remain distinguishable at 32×32. Legacy projectile,
shot charge, casing, and hull items retain their IDs and icons for existing saves.
Run the repository-level `tools/sync-icons.ps1 -Mod auxilias-ammunition` after changing a
128×128 master in `source-assets/icons`.

The four old-part conversion recipes are grouped under **Saved Ammo Parts** so the normal
ammunition crafting list stays focused on current production.

The legacy projectiles, shot charge, and empty shotgun hull retain dedicated ground models
instead of vanilla complete-ammunition meshes. Their reproducible Blender source, shared
texture atlas, FBX round-trip checks, and regeneration command are documented in
[the component model pipeline](docs/MODELING.md).

## Installation

Copy the contents of `workshop` into a Project Zomboid Workshop staging directory, or
subscribe to the published Workshop item. Enable **Auxilia's Ammunition** when creating or
loading a world. Servers and every connecting client must use the same version.

## Compatibility and scope

- Supports `9mm`, `.38 Special`, `.357 Magnum`, `.45 Auto`, `.44 Magnum`, `5.56mm`,
  `.30-30`, `.308`, and shotgun shells.
- Does not override `Base` ammunition or firearms.
- Does not recover spent casings; no firing event hooks are installed.
- Uses one server-side Lua file only for procedural loot injection.
- Other mods can consume the vanilla output. Adding recipes for their custom calibers is
  intentionally left to compatibility patches.

## Documentation

- [Vanilla ammunition audit](docs/VANILLA-AMMO-AUDIT.md)
- [System design](docs/DESIGN.md)
- [Balance tables](docs/BALANCE.md)
- [Testing and known limits](docs/TESTING.md)
- [Component model pipeline](docs/MODELING.md)
- [1.0.0 release validation report](docs/reports/RELEASE-VALIDATION-1.0.0.md)
- [Changelog](CHANGELOG.md)

Build a release candidate with `tools/package.ps1`. The archive and its SHA-256 sidecar are
written to `dist` after validation and an archive-content audit.
