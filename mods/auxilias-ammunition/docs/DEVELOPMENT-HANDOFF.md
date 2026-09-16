# Development handoff: ammunition redesign

Read this before changing the 1.1.0 candidate. It records conclusions from the
Build 42.20.4 investigation, not a claim that every recipe has passed in-game
acceptance. The target build comes from `config/project-zomboid.json`; current
source, rather than old test logs or memory, is authoritative for implementation.

## Current contract and source of truth

| Concern | Current source / rule |
|---|---|
| Item definitions and published IDs | `workshop/Contents/mods/AuxiliasAmmunition/42.20/media/scripts/auxilias_ammunition_items.txt` |
| Recipe quantities, tools, station tags | `workshop/Contents/mods/AuxiliasAmmunition/42.20/media/scripts/auxilias_ammunition_recipes.txt` |
| Entity, XUI window, and tiles | `auxilias_ammunition_press.txt`, `auxilias_ammunition_press_xuiSkin.txt`, and `media/auxammo_press_01.tiles.txt` under the same release-line tree |
| Saved press component repair | `media/lua/shared/AuxiliasAmmunition_PressWorld.lua` in that tree |
| Right-click press icon | `media/lua/client/AuxiliasAmmunition_PressContextIcon.lua` in that tree |
| Single left-click entry | `media/lua/client/AuxiliasAmmunition_PressLeftClick.lua` in that tree |
| Quantities and intended progression | `docs/BALANCE.md` and `docs/DESIGN.md` |
| Actual test evidence and pending checks | `docs/TESTING.md` |
| Cross-mod Build 42 engine findings | `../../../shared/knowledge/BUILD-42-CRAFTING-MATERIAL-IDS.md` and `../../../shared/knowledge/BUILD-42-ENTITY-WORKSTATIONS-AND-CONTEXT-MENUS.md` |

The current validator expects 12 items, 19 recipes, 13 recipes with the
`AuxAmmoPress` station tag (four body batches and nine final rounds), and nine
vanilla ammunition outputs. `tools/validate.ps1` guards those relationships;
update it when intentionally changing the contract. The four body recipes still
use historical `AuxAmmoCast*Projectiles` / `AuxAmmoCastShotCharges` IDs although
their outputs are now combined cartridge bodies. `MineralSalts` and
`SurvivalPropellant` also retain published IDs despite changed display concepts.
Do not rename IDs for tidiness. The `tiledef=auxammo_press_01 7713` registration
in both `mod.info` files is likewise tied to saved furniture. The old primer,
separate casing/projectile, and fired-mold concepts are removed from this design.

## Recipe and resource traps

- Use the IDs in the installed target build. Forageable ordinary stone is
  `Base.Stone2`; wood charcoal is `Base.CharcoalCrafted`. The carbon recipe
  explicitly accepts `Base.CharcoalCrafted`, `Base.Charcoal`, and `Base.Coke`.
  It has no Reloading gate or Reloading XP; its kept mortar/pestle is a tool.
- `Base.CompostBag` has four uses (25% each); `Base.Fertilizer` has eight
  (12.5% each). In these `CraftRecipe` inputs, `item 2 [Base.X]` requests two
  drainable **uses**, not two full bags. The separate compost and fertilizer
  recipes each yield one `NitrogenousMix` and keep the mortar/pestle. Both need
  Farming 3, with no manual. Partial-bag consumption still needs live acceptance.
- Picked-up animal dung is an actual vanilla compostable inventory item; it and
  rotten food feed the vanilla composter. The mod consumes the resulting compost
  bag, not dung directly. The field-powder recipe then consumes mineral powder,
  carbon powder, and one nitrogenous mix. This is an abstract game resource,
  not a real-world chemical process.
- Read `docs/BALANCE.md` for exact batches and the nine final recipes. A server
  recipe export proves parsing/registration; it does not prove crafting UI
  filtering, material consumption, partial-use behavior, or firearm use.

## Press interaction and the failure we diagnosed

The player crafts `Mov_AmmoPress`, places it on a table, then clicks its
**world tile** to open the CraftBench. The item and entity scripts provide
`UiConfig` and `CraftBench` (`Recipes = AuxAmmoPress`), the Base XUI skin enables
the `ES_AmmoPress` window and CraftBench panel, and all press recipes carry the
matching tag. The four tile faces have `CustomItem`, face offsets, and
`IgnoreSurfaceSnap` so the placed tool can rotate on a tabletop.

When the menu was absent on an earlier saved press, adding the script components
was not enough: the already-placed object retained its old one-component state.
`PressWorld.lua` now checks the exact sprites and `CustomItem`, adds only absent
native components on chunk load/game start, and flags server-side changes for
save. The affected saved object gained `UiConfig`/`CraftBench` and its menu and
recipe list opened in a 42.20.4 client. `PressContextIcon.lua` runs after the
vanilla entity menu element, finds only that press's option, and reuses the item
texture at the left of its label. The icon and option click were also checked in
the same client. See the shared workstation note for engine call paths.

The vanilla furnace's single left-click route requires a multi-square master,
which this one-tile moveable does not have. `PressLeftClick.lua` therefore
recognizes a completed click on this press only, applies the vanilla range and
player-state guards, then calls the same native `ISEntityUI.OpenWindow` used by
the right-click option. The left-click picker can return the table beneath a
press; resolve the matching press from that clicked object's square, checking
both sprite and `CustomItem`. A 42.20.4 client opened the CraftBench window by
one left click and by the existing right-click option. Do not change the
press's tile footprint or replace the global vanilla click handler to obtain
this shortcut.

If the menu disappears again, first check that the game loaded the current
installed copy, then inspect the placed tile and its components. Do not infer
placed-object state from a fresh item or a clean server startup. Test world
menus while unpaused. Inspect any new icon in a graphical client.

## Asset and deployment traps

The press art is generated from `source-assets/blender` and `tools/build-press-*`;
edit the generator/source, not only the packed runtime output. All four faces
must share one camera scale and bed anchor. Face offsets plus
`IgnoreSurfaceSnap` are both needed for the observed tabletop rotation. The
128x128 icon master is synchronized to the 32x32 runtime texture by
`tools/sync-icons.ps1`; the right-click menu reuses that runtime image.

One observed “obsolete recipe / missing nitrogenous mix” report came from an
older user-local Workshop copy, not the then-current repository source. After
changing scripts or Lua, run the root deploy tool for this mod and restart the
client before judging the UI. Keep a release candidate reproducible:

```powershell
& './tools/validate.ps1'
& './tools/deploy.ps1' -Mod 'auxilias-ammunition'
& './tools/package.ps1' -Mod 'auxilias-ammunition' -Force
```

The deploy and package tools compare file hashes against the source Workshop
tree. Use `docs/TESTING.md` for client/server acceptance. In particular, actual
body and ammo consumption, partial drainable bags, press recovery and
save/reload, all nine firing paths, and multiplayer behavior remain open
checks; a visible bench window is not evidence that these passed.
