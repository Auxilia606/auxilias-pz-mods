# Build 42 crafting material IDs used by mods

Inspected the installed Project Zomboid script and foraging data while the repository target
was Build 42.20.4 (2026-09-13). Recheck these IDs and tags when the target changes.

- The ordinary forageable stone is `Base.Stone2`, not `Base.Stone`. It appears in
  `media/lua/shared/Foraging/Categories/Stones.lua` and carries `base:stone` in the generated
  item scripts.
- `Base.Limestone` is also forageable and carries `base:stone` and `base:limestone`.
  A recipe using `tags[base:stone]` can also accept other tagged stones such as flint. Use an
  explicit item alternative when only ordinary stone and limestone should qualify.
- `Base.Charcoal`, `Base.CharcoalCrafted` (display name Wood Charcoal), and `Base.Coke`
  carry `base:charcoal` in the generated item scripts. Vanilla's dome-kiln recipe uses
  an explicit `item 8 [Base.CharcoalCrafted;Base.Charcoal]` alternative; explicit item
  alternatives document the exact accepted item IDs without relying on a category tag.
  The installed generated item scripts do not define `Base.Coal`. `Base.Coke` is
  the available coal-derived item; avoid referencing an unverified coal ID.
- Vanilla stone-breaking recipes use `HammerStoneStanding` and a kept hammer tool. Vanilla
  mortar-and-pestle recipes use `MixingMortarPestle` and the `base:mortarpestle` tool tag.
- `Base.CompostBag` is a drainable with `UseDelta = 0.25` (four uses, 25% each) and
  `ReplaceOnDeplete = Base.EmptySandbag`; `Base.Fertilizer` is a drainable with
  `UseDelta = 0.125` (eight uses, 12.5% each) and no depletion replacement. They carry
  `base:compost` and `base:fertilizer` tags respectively. Vanilla dung items are
  `Base.Dung_*` food items with `IsDung = true` and `base:iscompostable`; the pickup action
  moves those actual items into inventory. Rotten food and dung can yield compost through
  a vanilla composter, and `ISGetCompost` fills a `Base.CompostBag`.
- In Build 42 `CraftRecipe`, the amount in `item N [Base.X]` represents uses when X is a
  partial-use drainable and the input has no `ItemCount`, `mode:keep`, or `mode:destroy`.
  The installed `InputScript` and `CraftRecipeData` classes implement this behavior;
  vanilla recipes such as baking with flour and fixing with duct tape use the same syntax.
  Use separate recipe inputs when different drainables need different use counts; do not
  rely on per-alternative `N:Base.Item` consumption without an in-game check.
- The installed `Base.HandDrill` has `base:drillmetal` and `base:drillwoodpoor` tags,
  while `Base.StoneDrill` has `base:drillwoodpoor` but no `base:drillmetal`. A recipe
  that should accept exactly these two tools can list them as explicit item alternatives.
- The installed Build 42.20.4 `RipDenimClothing` recipe uses scissors or a sharp knife
  on denim or leather clothing and maps the result to `Base.DenimStrips` or
  `Base.LeatherStrips`. Both are normal items in `media/scripts/generated/items/normal.txt`;
  their dirty variants are separate IDs. Use an explicit item list when a recipe should
  accept only clean strips.
- The installed `InputScript.doesItemPassIsOrNotEmptyAndFullTests` bytecode applies
  `IsEmpty` to containers, drainables, radios, weapon parts, and fluid containers,
  but does not inspect a `HandWeapon`'s current ammunition count. Use a recipe
  `OnTest` callback when an upgrade must reject a loaded firearm-style weapon.

Sources in the installed game include `media/scripts/generated/items/normal.txt`,
`media/scripts/generated/items/weapon.txt`,
`media/scripts/generated/entities/blacksmith/craftRecipes/recipes_stonemasonry_i.txt`,
`media/scripts/generated/entities/blacksmith/workstations/entity_dome_kiln_craftRecipe.txt`, and
`media/scripts/generated/recipes/recipes_medical.txt`. The drainable and compost findings
also use `media/scripts/generated/items/drainable.txt`,
`media/scripts/generated/items/food.txt`,
`media/lua/shared/TimedActions/ISPickupDung.lua`,
`media/lua/shared/TimedActions/ISGetCompost.lua`,
`media/scripts/generated/recipes/recipes_baking.txt`,
`media/scripts/generated/recipes/recipes.txt`, and the installed
`projectzomboid.jar` classes `InputScript` and `CraftRecipeData`.
