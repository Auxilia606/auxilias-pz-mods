# Build 42.20.2 vanilla ammunition audit

This report separates files observed in the installed Build 42 data from design inferences.
The audit was performed before implementation; no Build 41 recipe API was assumed.

## Active ammunition and firearm contracts

The generated item scripts define nine loose-round items used by vanilla firearms:

| Caliber | Vanilla full type |
|---|---|
| 9mm | `Base.Bullets9mm` |
| .45 Auto | `Base.Bullets45` |
| .44 Magnum | `Base.Bullets44` |
| .38 Special | `Base.Bullets38` |
| .357 Magnum | `Base.Bullets357` |
| 5.56mm | `Base.556Bullets` |
| .30-30 | `Base.3030Bullets` |
| .308 | `Base.308Bullets` |
| Shotgun | `Base.ShotgunShells` |

Firearm scripts refer to those ammunition types. The mod therefore outputs these exact
items and does not redefine them. Vanilla's `AmmoType` Java class is mapping support; the
installed classes expose no primer, casing, or ammunition-manufacturing subsystem.

## Active crafting patterns reused

- `media/scripts/recipes_ammunition.txt` contains gunpowder gathering and box pack/unpack
  recipes, but no active cartridge-manufacturing chain.
- Build 42 production recipes use `craftRecipe`, structured `inputs`/`outputs`, station
  `Tags`, `SkillRequired`, `xpAward`, `NeedToBeLearn`, and station-specific timed actions.
- The vanilla Hand Press entity advertises `CraftBench Recipes = HandPress`; its recipes
  use `Tags = HandPress` and `timedAction = UseHandPress`.
- Pottery uses `PotteryBench`; kiln firing uses `KilnSmall;KilnLarge` and
  `Making_With_Kiln`.
- Smelting and casting use `Furnace;AdvancedFurnace`; charcoal production uses the
  `WoodCharcoal` station tag.
- The internal perk identifier displayed as Foraging is `PlantScavenging`.

## Renewable or repeatable vanilla inputs

Observed vanilla sources include `Base.Limestone` in
`media/lua/shared/Foraging/Categories/Stones.lua`, `Base.IronOre` in
`ForestRarities.lua`, `Base.CopperScrap` in `CraftingMaterials.lua`, and compost/rag
entries in foraging and ordinary world systems. Clay, logs, charcoal, farming compost,
and animal/food waste already participate in Build 42's survival economy. The mod connects
these resources rather than creating a mining or farming framework.

`Base.GunPowder` is a ten-use drainable also consumed by explosive and trap recipes.
Producing it renewably would change unrelated vanilla economies, so this mod creates
`AuxiliasAmmunition.SurvivalPropellant`, which is accepted only by its ammunition recipes.

## Hidden remnants, not an active system

The install contains:

- `media/models_X/WorldItems/BulletMold.FBX`
- `media/textures/WorldItems/BulletMold.png`
- `media/models_X/WorldItems/ShotGunShellstMold.FBX`
- `media/textures/WorldItems/ShotgunShellsMold.png`
- `Base.ShotGunShellsMold_Ground` in `media/scripts/generated/models_items.txt`
- old translation keys such as `MakeShotgunShells` and `MakeShotgunShellsMold` in some
  language files

No active item plus recipe chain connects these remnants. The shotgun ground model is
reused directly. The bullet mesh/texture is exposed through one model definition because
vanilla has no corresponding active model definition. This is a factual reuse of shipped
assets, not evidence of a supported hidden ammunition API.

## Explicitly absent from v1

Searches of active scripts and classes found no stable spent-casing recovery contract.
Implementing recovery would require firearm event hooks, per-shot classification, and MP
authority decisions. v1 therefore does not patch firearms, emit casings, or persist casing
state. The renewable casing recipe is the supported closed-loop path.
