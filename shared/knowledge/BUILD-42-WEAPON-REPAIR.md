# Build 42 weapon repair semantics

Inspected 2026-09-21 against the installed Project Zomboid 42.20.4 build targeted by
`config/project-zomboid.json`. The catalog counts below include weapon parts, broken
variants, toys, and debug definitions; they are useful for script coverage rather than
as a count of naturally obtainable combat weapons.

## Repair families

`media/scripts/generated/items/weapon.txt` contains 409 weapon definitions. Of those,
172 carry both `base:repairwithtape` and `base:repairwithglue`, 14 carry only the tape
tag, one carries only the glue tag, 15 carry only `base:repairwithepoxy`, and 207 carry
none of the three generic repair tags. None of the 22 definitions with `Ranged = true`
uses a generic repair tag.

Generic material repairs are defined in
`media/scripts/generated/recipes/recipes_fixing.txt`:

- Scotch tape, zip ties, ordinary glue, and epoxy with rags call
  `RecipeCodeOnCreate.genericFixing`.
- Duct tape and wood glue call `genericBetterFixing`.
- Epoxy with fiberglass tape calls `genericEvenBetterFixing`.
- The damaged item is kept in place with `mode:keep` and `IsDamaged`; the recipe has
  no output item.

Long- and short-blade definitions do not use the generic structural repair tags.
Sharpenable blades instead have a separate sharpness state. Blade, spear, axe, hammer,
and long-tool recipes can also dismantle and reassemble components while inheriting
condition, head condition, and sharpness as appropriate. Saw recipes replace blades.

Functional firearms normally use the legacy definitions in
`media/scripts/generated/fixing.txt`. These consume another same or compatible firearm
and use Aiming as the repair skill. This is distinct from the tag-driven crafting
recipes and is unsuitable as the default repair path for an expensive crafted weapon.

## Generic crafting-repair calculation

The installed `zombie.scripting.logic.RecipeCodeOnCreate` bytecode gives generic,
better, and even-better repairs quality values of 1, 2, and 3. Before integer rounding,
a successful repair restores this fraction of the currently missing condition:

```text
quality * 10 / max(previousRepairs, 1)
    + min(Maintenance * 5, 25) percent
```

The condition gain has a minimum of one point. Because of that floor, repeated
successful repairs can eventually return an item to `ConditionMax`; repairs do not
permanently lower the maximum condition.

The failure threshold is derived from:

```text
25 - quality * 5 - Maintenance * 5 + previousRepairs * 2
```

Maintenance zero receives an additional 10-point penalty, and the final threshold is
clamped to 0–95. Failure consumes the recipe materials, reduces condition by one, and
does not grant the successful repair. Every attempt increments `HaveBeenRepaired`,
including a failure, so the effective material cost per restored condition rises over
the lifetime of the item.

## Modding guidance

Use a dedicated craft recipe with a kept `IsDamaged` input when a mod needs specific
materials, tools, skills, or a workstation but still wants vanilla repair behavior.
Call one of the public `RecipeCodeOnCreate.generic*Fixing` callbacks. This preserves the
original item identity and state while retaining vanilla repeated-repair economics.

Adding `base:repairwithtape` exposes duct tape, Scotch tape, zip ties, epoxy with
fiberglass tape, and epoxy with rags. Adding `base:repairwithglue` exposes both ordinary
and wood glue. Do not add these broad tags when the item is intended to have only a
tier-specific repair path.

For firearm-style mod weapons, check ammunition explicitly in `OnTest`: Build 42's
crafting input tests do not treat loaded ammunition as non-empty. A kept repair target
preserves ammunition selection and other item state, but the recipe should reject a
loaded weapon when servicing it loaded would be unsafe or confusing.
