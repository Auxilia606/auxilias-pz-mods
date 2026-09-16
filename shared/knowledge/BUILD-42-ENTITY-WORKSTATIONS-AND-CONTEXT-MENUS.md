# Build 42 entity workstations and world context menus

These findings were checked against the installed Project Zomboid Build 42.20.4
scripts and a live single-player client in September 2026. Recheck the engine paths
when `config/project-zomboid.json` changes. The ammunition press is the observed
example; the engine rules below can guide other mods.

## What makes a placed station open

An item icon, a `CraftRecipe` station tag, and a matching entity script do not by
themselves prove that a placed world object has a right-click workstation option.
The vanilla world-menu path is:

1. `media/lua/client/Context/World/ISContextEntity.lua` considers eligible
   entities among the gathered world objects. When
   `ISEntityUI.CanOpenWindowFor(player, object)` succeeds, it adds one option
   named `object:getEntityDisplayName()` with the object as its callback
   parameter.
2. In the default path used by this press,
   `media/lua/client/Entity/ISEntityUI.lua` checks the **world object's current**
   `UiConfig` component, enabled UI, and usable XUI window style. A custom XUI
   can-open function can take a different path. The window and
   `ISCraftBenchPanel` need their corresponding component/panel configuration.
3. The entity's `CraftBench Recipes` value and the recipe's `Tags` must match for
   the recipes to be listed in the bench.

Compare both the item and entity definitions with a vanilla analogue. Blacksmith
workstation entity scripts declare `UiConfig`, `CraftBench`, and `SpriteConfig`.
The tabletop Key Duplicator's tiles declare `CustomItem`; its moveable item
script has no item-side UI/bench components, while its entity script declares
them. This comparison shows that an
item script's component list alone is insufficient evidence for a placed object;
it does not prescribe one component layout for every custom station.

## Saved moveables can keep an older component set

In one 42.20.4 save, the ammunition press tile still had its `CustomItem` property
but only one component and no `UiConfig` after the mod's item/entity definitions
changed. A fresh-item script probe and a successful server load did not expose
that state. Inspect the *placed object* after loading the affected save.

For that press, a narrow, repeatable repair in
`mods/auxilias-ammunition/workshop/Contents/mods/AuxiliasAmmunition/42.20/media/lua/shared/AuxiliasAmmunition_PressWorld.lua`
checks both one of four press sprite names and the exact `CustomItem` ID. It adds
only missing `UiConfig`/`CraftBench` components from the current item component
scripts via `ScriptManager.instance:FindItem`, `getComponentScriptFor`,
`ComponentType.*:CreateComponentFromScript`, and `GameEntityFactory.AddComponent`.
It scans on `LoadChunk` and near the player on `OnGameStart`; the server flags a
changed object for hot save. The saved press then had both components and opened
its CraftBench window. This is a verified repair for that object, not proof that
every possible saved or multiplayer object has been migrated.

## Adding an icon to the existing world-menu option

Vanilla `ISContextEntity.lua` adds its entity option without an icon. The option
has an `iconTexture` field (`media/lua/client/ISUI/ISContextMenu.lua`), which the
menu renderer draws at the left of the label. Vanilla also uses full
`getTexture("media/textures/...png")` paths for menu icons.

`ISWorldMenuElements` run in priority order. `ISMenuElement.new()` defaults to
`zIndex = 1000`; a mod element at `1001` can find and decorate the vanilla entity
option after it is created. Match the precise object and option callback parameter,
then set `option.iconTexture`. This leaves the vanilla option and its open-window
callback intact. The ammunition implementation is
`mods/auxilias-ammunition/workshop/Contents/mods/AuxiliasAmmunition/42.20/media/lua/client/AuxiliasAmmunition_PressContextIcon.lua`.
The existing `Item_AuxAmmoPress.png` rendered beside the press label in the
42.20.4 client, and clicking that option still opened the bench.

## Single-click opening is not automatic for every entity

In Build 42.20.4, `media/lua/server/ISObjectClickHandler.lua` handles a completed
left click with `doClick`. Its native entity-window branch requires a
`SpriteConfig:getMultiSquareMaster()` object, then checks the game mode, pause
state, player state, distance, obstruction, and destroy cursor before calling
`ISEntityUI.CanOpenWindowFor` and `OpenWindow`. A one-tile moveable may have a
working right-click entity menu yet not enter this left-click branch. Furnace
entity scripts have `SpriteConfig`, but copying that declaration alone does not
prove a moveable will get a multi-square master.

For the ammunition press, a client-only listener on
`OnObjectLeftMouseButtonDown/Up` recognizes only its four sprites and exact
`CustomItem`, requires the same press at mouse-down and mouse-up, and applies
the vanilla interaction guards before using `ISEntityUI.OpenWindow`. Unlike a
right-click context menu, the left-click event passes one picked object. If a
moveable sits on a table, that object may be the table; search its square's
object list for the matching press. This was needed before the saved press
opened with one left click in a 42.20.4 client. The existing right-click entry
still opened the same window. The listener does not replace the generic click
handler or change the station's saved tile structure. A click from outside
interaction range remains an acceptance check.

## Debugging order

1. Confirm the game loaded the current installed Workshop tree; compare its files
   with the repository source and restart the client after deploying Lua/scripts.
2. Right-click the **placed tile**, not the inventory item. Unpause the game:
   `ISMenuContextWorld.lua` skips world-menu work when game speed is zero.
3. Inspect the tile sprite and `CustomItem`, then the placed object's actual
   components. A script definition or headless load is not a substitute.
4. Check `UiConfig`, the XUI entity style/window/panel, `CraftBench Recipes`, and
   recipe `Tags` separately. Opening a bench verifies UI wiring, not ingredient
   consumption or multiplayer authority.
5. For an icon, check the menu option's `iconTexture` and the texture path in a
   client. A headless server's texture warning does not settle client rendering.

The exact press diagnosis, client observation, and remaining acceptance gaps are
recorded in `mods/auxilias-ammunition/docs/TESTING.md`. Tile facing and tabletop
rotation findings are in `shared/knowledge/ASSET-PRODUCTION.md`.
