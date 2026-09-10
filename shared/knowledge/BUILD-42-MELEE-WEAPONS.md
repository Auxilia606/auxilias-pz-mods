# Build 42 weapon taxonomy and melee combat

Inspected 2026-09-11 against installed Project Zomboid 42.20.4, the exact target
in `config/project-zomboid.json`. These are installed script and Java bytecode
observations, not a claim that an NPC has passed live combat acceptance.

The official [Build 42.20 feature overview](https://projectzomboid.com/blog/features-overview-build-42-20/)
listed stable and unstable as 42.20.4 when checked. It describes the separate
weapon handle/head conditions and blade sharpness, and the revised firearm aiming
system. Exact values below come from the installed build, not older wiki tables.

## Evidence and reproduction

Local installation used:
`C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid`.

- `media/scripts/generated/items/weapon.txt`: 409 item definitions, including
  craftable weapons, broken parts, explosives, firearms, toys and debug entries.
  A definition is not evidence that an item naturally spawns in loot.
- `media/lua/shared/Items/OnBreak.lua`: replacement items, broken heads and shafts.
- `projectzomboid.jar`, inspected using `javap -p -c`: `zombie.inventory.types.HandWeapon`,
  `zombie.inventory.InventoryItem`, `zombie.inventory.types.WeaponType`,
  `zombie.scripting.objects.WeaponCategory`, `zombie.scripting.objects.Item`,
  `zombie.CombatManager`, `zombie.characters.IsoGameCharacter`, and
  `zombie.ai.states.SwipeStatePlayer`.

Example read-only command (substitute the installed path):

```powershell
javap -p -c -classpath 'C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid/projectzomboid.jar' zombie.inventory.types.HandWeapon
```

Do not import the game catalog or decompiled engine into a mod. Query the actual
equipped `HandWeapon` at runtime so changes, repairs and other mods remain visible.

## Classification: skill category is different from attack animation

| Skill category in scripts | Runtime constant | Catalog memberships | Typical characteristics |
| --- | --- | ---: | --- |
| `base:blunt` | `WeaponCategory.BLUNT` | 96 | Long blunt weapons, bats, crowbars and heavy tools; reach and knockback vary. |
| `base:smallblunt` | `WeaponCategory.SMALL_BLUNT` | 98 | Hammers, nightsticks and short improvised tools; usually one hand, shorter reach. |
| `base:axe` | `WeaponCategory.AXE` | 45 | Hand axes, full axes, cleavers; chopping damage, sharpness, sometimes separate heads. |
| `base:longblade` | `WeaponCategory.LONG_BLADE` | 14 | Machetes, swords and katana; strong cutting damage, sharpness and breakage. |
| `base:smallblade` | `WeaponCategory.SMALL_BLADE` | 59 | Knives and short points; close reach, usually single target, low pushback. |
| `base:spear` | `WeaponCategory.SPEAR` | 29 | Spears, forks and points; generally long reach and thrusting, often a larger close-range gap. |
| `base:unarmed` | `WeaponCategory.UNARMED` | 1 | `Base.BareHands`, supporting shove/stomp behavior. |

`base:improvised` occurs on 129 definitions as an additional category. It is not
a seventh melee skill, and these counts overlap with the main categories.

Use `weapon:isOfWeaponCategory(WeaponCategory.AXE)` and the equivalent constants;
the installed `HandWeapon` API does not have the legacy `getCategories()` method.
`weapon:getScriptItem():containsWeaponCategory(...)` is another inspected API.
Namespaced lowercase script category strings are not Java enum names.

Items with attributes can also have an engine-created `ComponentType.Script`
component (`EntityScriptInfo`). Its saved payload is the original item/script
identity, recreated by `instanceItem(fullType)`. A serializer must not reject a
normal Axe merely because it has both Attributes and matching Script metadata.
Only matching original item identity is reconstructible this way; unrelated
components or a rebound script require their own persistence support.

Do not classify by display name, `DisplayCategory`, or `SubCategory` alone:

- `Base.MeatCleaver` is **axe** category in this build.
- `Base.GardenFork` has spear category, `SubCategory=Swinging`, and `SwingAnim=Spear`.
- `WeaponType` is the engine's animation/handling classification. Its
  `getWeaponType(HandWeapon)` checks `SwingAnim=Stab`, `Heavy`, and `Throw`, then
  ranged/two-hand flags and the spear animation. Its `KNIFE` result does not mean
  the item necessarily belongs to the short-blade skill.

## Actual representative values

All IDs below have the `Base.` prefix. Damage and critical chance are raw script
values, not guaranteed damage or final kill probability. Reach is in game world
units. `Swing/min` is `Swingtime` / `MinimumSwingtime`, **not measured seconds**.
`Hands` distinguishes `TwoHandWeapon` from the stronger `RequiresEquippedBothHands`.

| Item | Skill | Min–max reach | Damage | Crit % / multiplier | Swing/min; animation | Hands | Weight / endurance mod | Hit cap | Condition max / lower chance 1-in |
| --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- |
| BaseballBat | Blunt | 0.61–1.25 | 0.8–1.1 | 40 / 2 | 3/3; Bat | Two | 2 / 1 | 2 | 15 / 20 |
| Crowbar | Blunt | 0.61–1.25 | 0.6–1.15 | 20 / 2.5 | 3/3; Bat | Two | 2 / 1 | 3 | 15 / 70 |
| Hammer | Small blunt | 0.61–1.1 | 0.5–1 | 20 / 3 | 3/3; Bat | One | 1.5 / 1 | 1 | 10 / 30 |
| Nightstick | Small blunt | 0.61–1.2 | 0.6–1.1 | 25 / 2 | 2/2; Bat | One | 1.5 / 1 | 2 | 15 / 20 |
| HandAxe | Axe | 0.61–1.1 | 0.7–1.5 | 15 / 5 | 4/3; Bat | One | 1.5 / 1 | 2 | 10 / 15 |
| Axe | Axe | 0.61–1.2 | 0.8–2 | 20 / 5 | 3/3; Bat | Two | 3 / 1 | 2 | 13 / 35 |
| WoodAxe | Axe | 0.61–1.35 | 1.3–3 | 50 / 12 | 0.5/0.5; Heavy | Both required | 3 / 3 | 3 | 15 / 40 |
| MeatCleaver | Axe | 0.61–1 | 0.4–0.8 | 15 / 5 | 4/4; Bat | One | 1 / 1 | 2 | 10 / 15 |
| Machete | Long blade | 0.61–1.23 | 2–3 | 20 / 5 | 4/4; Bat | One | 2 / 1 | 2 | 13 / 25 |
| Katana | Long blade | 0.61–1.4 | 8–8 | 35 / 6 | 3/3; Bat | Two | 2 / 1 | 3 | 10 / 15 |
| KitchenKnife | Small blade | 0.61–0.9 | 0.3–0.7 | 25 / 4 | 2/2; Stab | One | 0.7 / 1 | 1 | 10 / 2 |
| HuntingKnife | Small blade | 0.61–0.9 | 0.6–1.2 | 50 / 3 | 2/2; Stab | One | 1 / 1 | 1 | 10 / 15 |
| SpearCrafted | Spear | 0.98–1.4 | 1–1.4 | 20 / 5 | 2/2; Spear | Two | 2 / 1 | 2 | 5 / 2 |
| SpearLong | Spear | 0.98–1.48 | 1.2–1.7 | 20 / 5 | 2/2; Spear | Two | 2.7 / 1 | 2 | 10 / 10 |
| GardenFork | Spear | 0.61–1.37 | 1–1.5 | 30 / 10 | 2/2; Spear | Two | 2 / 1 | 2 | 10 / 15 |
| Sledgehammer | Blunt | 0.7–1.35 | 2–3 | Unspecified / 2 | 2/4; Heavy | Both required | 6 / 4 | 3 | 10 / 40 |

Endurance modifier defaults to 1 in `HandWeapon`; most rows do not explicitly set
the field. `Sledgehammer` additionally sets `CantAttackWithLowestEndurance=true`,
`AlwaysKnockdown=true`, `BaseSpeed=0.9`, and `PushBackMod=1`. These do not make it
an efficient default fighting weapon. `WoodAxe` having `Swingtime=0.5` does not
justify scheduling attacks every half second; it uses the heavy animation.

`Base.BareHands` has raw damage 0.2–0.4, maximum reach 1.1, endurance modifier 1.7,
`SwingAnim=Shove`, and a raw hit cap of 3. The engine imposes additional unarmed
and sandbox restrictions; these numbers are not permission to deal fist damage
directly or hit three zombies automatically.

## Range, facing and the real impact point

The planner should use the equipped weapon's `getMinRange()` and `getMaxRange(actor)`
to choose an approach distance and recognize dangerous crowding. Spears are the
clearest reason not to use one global contact radius. A garden fork demonstrates
why the exact item, not only its category, matters.

`getMaxRange(actor)` only adds the aiming-skill range modifier for ranged weapons.
For melee, `getRangeMod(actor)` separately returns 1.2 at Blunt, Axe or Spear skill
7 or above, otherwise 1.0. Do not assume the actor overload already includes that
melee bonus. Native collision additionally checks orientation, target geometry
and intervening obstacles. An isolated NPC requires the bridge described below.

`MinAngle`, `HitAngleMod`, `WeaponLength` and animation stance vary independently.
Rotate toward the intended target. A distance check is a planning aid, not a
substitute for line-of-sight, walls/doors, vertical separation, or a current
collision check at the actual animation impact moment.

`SwipeStatePlayer` receives `AttackAnim` and `AttackCollisionCheck` animation events.
The latter invokes `CombatManager.attackCollisionCheck` **only for a local
IsoPlayer**. `PlaySwingSound` has the same local-player gate. A live isolated NPC
probe confirmed that `AttemptAttack` enters the native swipe state and animates,
but this alone produces no collision processing. `CombatManager` has no supported
Lua exposure/getter; assigning the NPC a local-player slot would violate the
isolated companion design.

An NPC-only animation-node variant can preserve the original impact/sound timing
and emit a `SetVariable` pulse consumed by Lua. That pulse can invoke the exposed
native `target:Hit(weapon,actor,damage,shove,rangeFactor,false)` after a fresh
zombie-only range/arc/geometry check. Damage must never be based on a fixed Lua
timer. `BaseSpeed`, animation type, skill, injuries and character state are reasons
the literal script swing values are not a universal cooldown.

For single-player NPCs, native `CombatManager.pressedAttack` resets and rolls
critical chance on every accepted attack. Its remote-player gate applies only
in a network client. Preserve this flag; `Hit` applies its critical multiplier,
weapon-level, rear/floor, one-handed and global damage modifiers, health/death,
hit reactions, blood, and normal character hit events. Preapplying those modifiers
or re-emitting those events would double-count them.

## Shoves, floor attacks and close kills

- Shoving is a distinct native action for a standing target that is too close;
  it uses the bare-hands path while retaining the equipped weapon. Knockback and
  knockdown can create space for the next weapon swing.
- Floor aim is distinct from standing aim. The engine distinguishes a floor
  weapon attack from a shove/stomp and checks the target's body geometry. Do not
  repeatedly execute a standing swing against a prone target, or stomp at spear
  distance. Nearby standing threats should take precedence over finishing a body.
- The native collision manager has a separate NPC floor branch: for an NPC
  aiming at the floor with a non-ranged weapon, `Rand.Next(2)` selects a head hit
  half the time and bypasses the local player's private animated-bone tests.
  A head hit uses `HEAD_HIT_DAMAGE_SPLIT_MODIFIER` (default 3), Head-through-Neck
  clothing defense and `setHitHeadWhileOnFloor`. Apply that pre-Hit multiplier
  once; it is separate from the floor and critical modifiers already inside Hit.
  The native NPC branch does not select the local player's leg-hit penalty.
- `KitchenKnife` and `HuntingKnife` declare `CloseKillMove=Jaw_Stab`, tiny
  `PushBackMod=0.01`, no ordinary knockback, and hit cap 1. The native close-kill
  and critical paths inspect the target, weapon animation and surrounding threat
  conditions. A knife being in range is not a guaranteed jaw-stab kill.
- Spear handling has native thrust/critical logic, including target position and
  proximity to other targets. `SoundMap=SpearStab ...` supplies special-move audio
  on the crafted/forged spears. Do not implement a guaranteed scripted instant kill
  or manufacture a spear charge by skipping the engine's movement/attack state.
- `CombatManager` respects `SandboxOptions.multiHitZombies`: a raw `MaxHitcount`
  of 2 or 3 is an upper bound only when the game's conditions allow it. An NPC
  collision adapter must respect that sandbox cap and the item's cap after
  checking each target's current arc, reach and safe geometry. A radius alone
  is insufficient. Native standing armed shove caps at three; stomp caps at one.

## Endurance, muscle strain and condition

The inspected `CombatManager` attack path calls `processWeaponEndurance` and
`IsoGameCharacter.addCombatMuscleStrain`, and also applies melee endurance loss
on hits. These calculations already include item weight, endurance modifier,
character/weapon fatigue modifiers, traits and handling penalties. The local-player
gate also skips them for an isolated NPC, and `Hit` does not perform them. An NPC
adapter must reproduce the missing endurance stages once and call the exposed
native strain function once, including on a missed swing. It must not duplicate
the separate effects already owned by `Hit`.

An `IsoPlayer` constructed directly for an NPC has an empty perk list, so Fitness
and Strength initially read as zero. Normal creation calls
`applyTraits(java.util.List<CharacterTrait>)`, which seeds Fitness 5 and Strength
5 before adding trait and descriptor XP boosts. The exposed Lua equivalent
`actor:applyTraits(ArrayList.new())` performs that native baseline initialization
without adding or clearing traits. Call it once on a newly constructed actor;
repeated calls add levels rather than setting a baseline. Fitness 0 has a fatigue
modifier of 1 and recovery modifier of 0.7; Fitness 5 uses 0.85 and 1.2. Strength
0 also has a 0.75 hitting/shoving modifier, compared with 1 at Strength 5.

Native NPC endurance recovery is active in single player. Standing still with
acceptable encumbrance recovers endurance using the game's immobile recovery
rate, sandbox multiplier, Fitness recovery modifier and tiredness. Walking only
recovers at one quarter of the base rate while the Endurance moodle is below
level 2; at level 2 or higher it instead spends endurance. A retreat that keeps
an exhausted companion walking cannot restore its combat reserve. Let it stop
once safe spacing is available rather than assigning stamina directly.

The ordinary pre-Hit damage stages use current min/max damage, weapon damage and
character hitting modifiers, improper two-hand handling, arm pain, traits,
per-target multihit falloff, panic/stress and endurance/tired moodles. Stomp
replaces the weapon calculation with `Rand(0.7,1) + Strength*0.2`, multiplied by
shoe stomp power or 0.5 barefoot. Armor reduction uses the target's actual body-part
clothing defense and zombie armor sandbox factors. Do not substitute catalog
damage or a fixed per-category damage amount.

`HandWeapon.muscleStrainMod(actor)` returns
`(1 - weaponSkill * 0.075) * weapon:getStrainModifier()`. The script strain modifier
defaults to 1. The character calculation also scales with strength, hit count,
the sandbox muscle-strain setting and hand use. Correct two-hand use distributes
strain to both arms; one-handing a two-hand weapon adds a penalty. Shoves apply
both-arm strain and stomps apply right-leg strain through separate native branches.
This is distinct from the current endurance reserve: an actor can regain breath
while still carrying muscle pain.

An NPC planner should recover or make space when exhausted instead of continually
requesting attacks, and preserve actual body state so native pain/injury effects
still apply. The engine also has an explicit lowest-endurance restriction for
some weapons. Do not infer stamina cost from damage alone: the wood axe's modifier
is 3 and the sledgehammer's is 4 despite other weapons having similar reach.

`ConditionLowerChanceOneIn` is a base durability parameter, not the exact lifespan
in swings. Maintenance, damage checks and item structure affect breakage.
`hasSharpness()/getSharpness()` and `hasHeadCondition()/getHeadCondition()` expose
additional state. `HandWeapon.getMaxDamage()` adjusts applicable blade damage
using current sharpness, so raw catalog damage must not replace runtime damage.
Weapons such as the axe and hammer declare separate head condition; blade and
head/handle deterioration should use native `damageCheck` and its normal OnBreak
handlers. The exposed holder-aware overload allows an NPC adapter to preserve
the native condition, sharpness, component and maintenance calculations.

`OnBreak.HandleHandler` can remove the original item and place/equip a replacement
shaft or club. The planner must re-read both hands and the inventory after attacks,
reject broken items, and rebuild the weapon profile rather than retaining an old
weapon reference. Do not automatically restore item condition or recreate the
original weapon after a break.

## Other weapon families and the melee scope boundary

The same file contains pistols, revolvers, bolt-action rifles, lever-action rifles,
semi/automatic long guns, pump/tactical shotguns and double-barrel/sawn-off shotguns.
They use `Ranged=true`, `IsAimedFirearm=true`, ammunition registries, magazines or
internal rounds, distinct reload types and the Build 42 ballistics/aiming system.
Examples include `Pistol` (9 mm), `Revolver` (.357), `HuntingRifle` (.308),
`L92_Carbine` (.357 lever action), `L94_Rifle` (.30-30 lever action),
`AssaultRifle` (5.56, Auto/Single), `JS3T_Shotgun` and `DoubleBarrelShotgun`.
Their aiming, recoil, reload, ammunition and noise decisions need a separate
planner. See `BUILD-42-RANGED-WEAPON-EFFECTS.md` for the earlier ballistics audit.

Throwable explosives and distraction devices use `SwingAnim=Throw`,
`PhysicsObject`, timers, sensors or remote triggers; not all declare `Ranged=true`.
For example, `Aerosolbomb` is a `base:weapon` without that ranged field. Therefore
`instanceof(item, 'HandWeapon') and not item:isRanged()` alone is **not a melee
filter**. Reject throwing/physics weapons, aimed firearms, ranged weapons and
unarmed placeholders, and require a supported melee skill category. Toy cap guns
and fake weapons also appear in the catalog and must not become useful combat
equipment just because they inherit `HandWeapon`.

No vanilla bow/crossbow family was found in the inspected weapon catalog. Modded
projectile weapons must also remain outside a melee-only planner.

## Historical adapter verification limits

Auxilia's Survivors was retired and removed on 2026-09-12. The following describes
its historical adapter, whose code and fixtures are no longer distributed.
The engine contracts elsewhere in this document are retained independently.

The experimental bridge used zombie origins for standing range/cone checks,
a body-orientation estimate for prone approach/contact and a conservative
0.6-unit stomp limit. The estimate did not guarantee a head hit: floor contacts
used the native NPC's 50% head roll and head/neck protection, while other contacts
used the ordinary Hand_L-through-Neck defense distribution. Native damage range
scaling still used zombie-origin distance. Standing contacts sorted by current
distance, like the installed `MeleeTargetComparator`, with selection breaking ties.
This matters when another zombie moves closer during a swing: selection made at
request time must not override the nearer threat at contact. Floor contacts retained
selected-target priority; the private animated-bone collision and full native floor
sorting were not reproduced. Both respected the sandbox/item hit cap. Private
spiked-armor retaliation, attacker/weapon cosmetic blood and the inaccessible
`knockbackAttackMod` field assignment were not
reproduced. It called the shipped `xpUpdate.onWeaponHitXp` function for vanilla
weapon XP because Lua's `triggerEvent` overloads accept at most four payloads,
while native `OnWeaponHitXp` needs five. Other mods' separate listeners for that
five-argument event were therefore not invoked by the bridge; native Hit's normal
character events still ran. It did not request running charges. These were explicit
differences from the complete player collision path, not evidence of exact engine parity.

Static inspection establishes data and engine contracts. Live tests still need
to confirm NPC attack animation entry, visible impact timing, actual zombie
damage/reaction, interrupted attacks, shove/floor transitions, retreat/recovery,
weapon break replacement, and save/load behavior in this exact build. A Lua mock
or a successful `pcall` does not prove those engine interactions occurred.
