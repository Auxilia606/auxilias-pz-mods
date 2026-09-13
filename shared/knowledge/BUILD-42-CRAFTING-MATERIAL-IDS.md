# Build 42 crafting material IDs used by mods

Inspected the installed Project Zomboid script and foraging data while the repository target
was Build 42.20.4 (2026-09-13). Recheck these IDs and tags when the target changes.

- The ordinary forageable stone is `Base.Stone2`, not `Base.Stone`. It appears in
  `media/lua/shared/Foraging/Categories/Stones.lua` and carries `base:stone` in the generated
  item scripts.
- `Base.Limestone` is also forageable and carries `base:stone` and `base:limestone`.
  A recipe using `tags[base:stone]` can also accept other tagged stones such as flint. Use an
  explicit item alternative when only ordinary stone and limestone should qualify.
- `Base.Charcoal`, `Base.CharcoalCrafted`, and `Base.Coke` carry `base:charcoal` in the
  generated item scripts. The installed generated item scripts do not define `Base.Coal`.
  `Base.Coke` is the available coal-derived item; avoid referencing an unverified coal ID.
- Vanilla stone-breaking recipes use `HammerStoneStanding` and a kept hammer tool. Vanilla
  mortar-and-pestle recipes use `MixingMortarPestle` and the `base:mortarpestle` tool tag.

Sources in the installed game include `media/scripts/generated/items/normal.txt`,
`media/scripts/generated/items/weapon.txt`,
`media/scripts/generated/entities/blacksmith/craftRecipes/recipes_stonemasonry_i.txt`, and
`media/scripts/generated/recipes/recipes_medical.txt`.
