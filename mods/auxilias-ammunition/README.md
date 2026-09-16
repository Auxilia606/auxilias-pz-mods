# Auxilia's Ammunition

Current version: **1.1.0** (release candidate; redesigned crafting has not completed in-game acceptance)
Target: **Project Zomboid Build 42.20** (current candidate checked on 42.20.4;
historical v1.0.0 balance/runtime evidence uses earlier builds)

Auxilia's Ammunition combines Build 42's charcoal, foraging, and metalworking systems
with a small hand-operated tabletop ammunition press. It adds no skill or firearm
override; production uses the game's native crafting system.

## Production loop

1. Craft the movable tabletop ammunition press, place it on a suitable surface, and
   left-click its tile to open the CraftBench directly, or right-click it and choose
   **Tabletop Ammunition Press**.
2. Press a caliber-family cartridge body from iron and copper in that window. Each body
   represents its projectile and casing together; shotgun bodies also use ripped sheets.
3. Crush ordinary stone or limestone into mineral powder and grind wood charcoal,
   charcoal, or coke into carbon powder with a mortar and pestle; grinding requires no
   skill level. Prepare nitrogenous mix from two uses of a compost bag (50%) or two
   uses of NPK fertilizer (25%), then blend all three components into ammo-only field
   powder. Rotten food and collected animal dung feed the vanilla composter.
4. Press batches of ten rounds using cartridge bodies and field powder.

The final outputs are the nine vanilla ammunition items, so vanilla guns and mods that
consume vanilla ammo continue to work without patches. High skill levels also reveal
recipes without manuals.

The press, cartridge bodies, and nitrogenous mix use dedicated icons so frequently
handled items remain distinguishable at 32×32.
Run the repository-level `tools/sync-icons.ps1 -Mod auxilias-ammunition` after changing a
128×128 master in `source-assets/icons`.

To rebuild the tabletop press art, open the saved press `.blend` in Blender 5.2 and run
`source-assets/blender/render_runtime_press.py`, then run `tools/build-press-art.py` and
`tools/build-press-tiles.py` with Python and Pillow. The first script renders four views;
the next applies one scale and bed anchor to four 128×256 source tiles, writes a
four-face preview and icon; the last writes the game's binary texture pack and tile
definitions. The `tiledef=auxammo_press_01 7713` registration in
both `mod.info` files must remain stable once the station appears in saved worlds.

## Installation

Copy the contents of `workshop` into a Project Zomboid Workshop staging directory, or
subscribe to the published Workshop item. Enable **Auxilia's Ammunition** when creating or
loading a world. Servers and every connecting client must use the same version.

## Compatibility and scope

- Supports `9mm`, `.38 Special`, `.357 Magnum`, `.45 Auto`, `.44 Magnum`, `5.56mm`,
  `.30-30`, `.308`, and shotgun shells.
- Does not override `Base` ammunition or firearms.
- Does not recover spent casings; no firing event hooks are installed.
- Uses server Lua for procedural loot, shared Lua to restore native components on
  previously placed presses, and client Lua to display the press icon in its
  right-click menu.
- Other mods can consume the vanilla output. Adding recipes for their custom calibers is
  intentionally left to compatibility patches.

## Documentation

- [Vanilla ammunition audit](docs/VANILLA-AMMO-AUDIT.md)
- [System design](docs/DESIGN.md)
- [Balance tables](docs/BALANCE.md)
- [Testing and known limits](docs/TESTING.md)
- [Development handoff and confirmed pitfalls](docs/DEVELOPMENT-HANDOFF.md)
- [1.0.0 release validation report](docs/reports/RELEASE-VALIDATION-1.0.0.md)
- [Changelog](CHANGELOG.md)

Build a release candidate with `tools/package.ps1`. The archive and its SHA-256 sidecar are
written to `dist` after validation and an archive-content audit.
