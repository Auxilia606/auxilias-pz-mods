# Build 42 ranged-weapon ballistics and firearm effects

## Verified target

These findings come from the installed Project Zomboid 42.20.2 scripts and
`projectzomboid.jar` bytecode inspected on 2026-08-23.

Project Zomboid 42.20.3 revision `70207f62e0` was rechecked on 2026-08-23. The
official hotfix scope was multiplayer connection/player-limit handling, memory and
world-streaming optimization, and lighting-update fixes; it did not announce a
ranged-weapon, ammunition-registry, crafting, or Lua-event contract change. Both
Auxilia mods loaded cleanly on an isolated 42.20.3 dedicated server, and the project
owner completed the 42.20.3 client and multiplayer acceptance checks. The aimed-firearm
path, Metal/Stone ammunition switching and recovery, crossbow muzzle-light suppression,
vanilla firearm muzzle light, and remote shot synchronization all passed without an
Auxilia-related error. The 42.20.2 findings below therefore remain valid for 42.20.3.

## `IsAimedFirearm` is a behavior gate

`IsAimedFirearm` does not control only firearm presentation. Build 42 checks it in
`CombatManager` for ballistics target selection, `BallisticsController` updates,
`fireWeapon()`, shot statistics, weapon-condition behavior, and multiplayer shot
notification. `IsoPlayer` also uses it to select the firearm aiming path.

Do not turn this flag off on a ranged weapon merely to hide firearm effects. A Lua
call to `IsoPlayer.updateBallistics()` does not reproduce the engine call sites and
leaves targeting, hit resolution, UI, and networking on inconsistent paths.

## Bullet tracers are configured per ammunition registry but not exposed to mod Lua

`IsoBulletTracerEffects` owns a configuration entry for each resolved `AmmoType`.
The visible projectile, trail, and persistent path have independent alpha options:

- `ProjectileAlpha`
- `ProjectileTrailAlpha`
- `ProjectilePathAlpha`

Internally, a non-firearm projectile could keep normal firearm ballistics while
hiding all three tracer layers by setting these values to zero for its dedicated
ammunition types. Build 42.20.2 does not expose the `IsoBulletTracerEffects` class
used by `CombatManager` to ordinary mod Lua, however. `LuaManager.Exposer` exposes
the separate `FBORenderTracerEffects` implementation, which is not the controller
called by the current firearm path.

Do not call `IsoBulletTracerEffects.getInstance()` from a client mod: the Lua global
is `nil` and causes `attempted index: getInstance of non-table: null`. The engine
loads tracer configuration files directly from its base `media/effects` directory,
so placing a similarly named file in a normal mod's `media/effects` tree is not a
reliable override either. Until the engine exposes a supported controller or item
property, preserving the aimed-firearm path means accepting its visible tracer.

The ammo type must still be resolved during item loading; otherwise effect creation
can dereference a missing configuration entry.

## Muzzle light is independent of the flash model

When `CombatManager` processes an aimed firearm shot, it calls
`EffectsManager.startMuzzleFlash()` before `fireWeapon()`. Build 42 creates a
short-lived radius-18 `IsoLightSource` even when the weapon has no muzzle-flash
model key. Clearing `MuzzleFlashModelKey` therefore hides the model but does not
stop nearby tiles from lighting up.

`OnWeaponSwingHitPoint` runs before that light is added. The regular `OnTick` event
runs after the combat update and before rendering. A client mod can therefore
snapshot existing cell lights at the shot event and expire only a newly added
radius-18 source at the shooter's tile during `OnTick`. Preserve the snapshot and
match the exact source characteristics so unrelated world lights and ordinary
firearms are not changed.
