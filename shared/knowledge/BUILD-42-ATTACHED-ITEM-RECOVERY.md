# Build 42 attached-item recovery

This note records static findings from the locally installed Project Zomboid
42.20.4 files and bytecode. It describes engine contracts that may be useful to
more than one mod; it is not a substitute for an in-game visual or multiplayer
acceptance test.

## Character-hit events

`IsoZombie.Hit` triggers `OnHitZombie(zombie, wielder, bodyPart, weapon)`. The
shipped `DamageModelDefinitions.lua` confirms that signature. The reported body
part is a simulated coarse region such as `Head`, `Torso_Upper`, or
`Torso_Lower`, not an exact projectile collision point.

The base `IsoGameCharacter.Hit` method also triggers
`OnWeaponHitCharacter(wielder, target, weapon, damage)`. Animals inherit this
path in 42.20.4, so it is a better target-specific hook than
`OnWeaponHitXp`. The installed `CombatManager` only emits `OnWeaponHitXp` in the
non-client, non-server branch, which makes that callback unsuitable as the sole
multiplayer recovery hook.

## Attaching a real item to a zombie

The shipped `media/lua/shared/Items/OnBreak.lua` is the vanilla precedent for a
weapon fragment visibly remaining in a zombie. It selects a Human attached-item
location, calls `zombie:setAttachedItem(location, item)`, sends
`sendAttachedItem` on the server, and reports `EventAttachItem`.

Human attached locations are registered in
`media/lua/shared/NPCs/AttachedLocations.lua`. Relevant location-to-model
attachment mappings include:

| Location ID | Model attachment |
|---|---|
| `JawStab` | `knife_head` |
| `Knife Shoulder` | `knife_shoulder` |
| `Knife Stomach` | `knife_stomach` |
| `Stomach` | `stomach` |
| `Knife in Back` | `knife_in_back` |
| `MeatCleaver in Back` | `meatcleaver_in_back` |

An attached inventory item's StaticModel must define the corresponding model
attachment. `ModelManager` resolves the character and item attachment with that
same attachment name; an item with only a `world` attachment will exist in the
attached-item collection but will not render correctly on the character.

Item-side attachment rotations are only reusable when the two meshes share the
same effective local basis. Do not infer that basis from imported world-space
bounds alone: the inspected vanilla forged hunting-knife FBX stores its long mesh
axis locally on Z and supplies a node transform, while the custom Bolt stores its
long mesh axis directly on Y with an identity node transform. The engine composes
the item attachment and mesh transform separately. For a projectile, also verify
endpoint semantics rather than merely making its pointed end match another mesh:
the point must face into the character and the tail must face out. A correction
that preserves the same axis line but swaps those endpoints can look like a prop
laid across the skin.

In 42.20.4, the character attachment transform and same-named item attachment
transform are multiplied directly; the item transform is not inverted under the
default runtime setting. The inspected vanilla embedded blade models consistently
use item offset `0 0.15 0` for `knife_shoulder`, `knife_stomach`, and `stomach`,
including meshes of different lengths. Treat this as model-origin registration,
not a length-dependent penetration value. Random pose variants should normally keep
that registration offset and vary only rotation unless a separately verified mesh
origin requires a translation correction.

`IsoZombie.DoZombieInventory` rebuilds ordinary zombie inventory during death,
then adds attached items to the new inventory. `IsoDeadBody` copies that
inventory and the attached-item collection. Consequently, attaching the actual
recoverable item provides both the live visual and corpse loot without creating
a second recovery item. If all suitable visual locations are occupied,
`IsoZombie.addItemToSpawnAtDeath(item)` is the non-visual fallback that survives
the same inventory rebuild.

Auxilias Crossbow deliberately uses only `addItemToSpawnAtDeath` for zombie Bolt
recovery. Repeated 42.20.4 client tests showed that the available Human blade
anchors made this projectile appear offset or laid sideways even after correcting
its item transform. The live attachment, alternate embedded models, and sync calls
were therefore removed; this engine note remains as cross-mod research rather than
the current Crossbow implementation.

## Animal boundary

The inspected animal corpse path does not expose the same ordinary loot
container or the Human attached-location contract. Do not assume that adding an
item to a live animal inventory will transfer it to `IsoDeadBody`. A safe
fallback is to keep the recovery result in that animal's ModData and create the
world item at its square from authoritative `OnCharacterDeath` processing.
That preserves target identity and delays recovery until death, but it places
the item beside the carcass rather than inside a corpse container.

## Verification boundary

Static inspection establishes the event signatures, server sync call, model
attachment requirement, and zombie death transfer path. A client test must
still tune item-side offsets and rotations, confirm each coarse region, verify
that looting removes the expected item without duplication, and observe the
same result from a second multiplayer client.
