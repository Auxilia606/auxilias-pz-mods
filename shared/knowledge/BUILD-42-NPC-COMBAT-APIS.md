# Build 42 NPC melee API observations

Inspected 2026-09-11 against the installed Project Zomboid 42.20.4
`projectzomboid.jar` and its shipped Lua, action groups, and animation definitions.
These combine static bytecode/Lua-exposure observations and the isolated live
test described below. The configured target remains
`config/project-zomboid.json`.

Research provenance: the Auxilia's Survivors experiment was retired and removed
on 2026-09-12. Descriptions of its adapter, generator, custom animation variables
and live runs below are historical evidence. Those implementations and fixtures
are no longer distributed; the native engine findings remain reusable.

## A native attack request is not a damage call

For an `IsoPlayer` marked with `setNpc(true)`, the useful public request is
`actor:AttemptAttack(1.0)`, after normal readiness, target, distance, facing, and
cooldown checks. The overload taking a float is inherited from
`IsoLivingCharacter`; it honors the `Attack` Lua hook and dispatches to
`IsoPlayer.DoAttack`. Calling the no-argument overload skips that inherited hook.

`IsoPlayer.DoAttack(float, String)` checks hand-to-hand action authorization, calls
`pressedAttack`, and **returns false even when an attack starts**. Treating this
return as success/failure is incorrect in this revision. The immediate observable
request state is `actor:isAttackStarted()`; animation state and actual hit events
are separate evidence.

`CombatManager.pressedAttack` performs the following native work:

- Rejects an already started attack and incompatible hit-reaction/fishing states.
- Checks hand models/item replacements and weapon readiness.
- Sets the initiating/started flags and chooses a possible `AttackType` from the
  equipped `WeaponType`.
- Calculates combat speed from the actor and equipped weapon.
- Calculates attack variables and chooses standing/prone targets, shove, close
  kill, floor aim, and the actual weapon for the attack.
- Sets critical/behind/attack variation state for the native animation.

The action-group transition into melee/shove/stomp enters `SwipeStatePlayer`.
For registered local players its `AttackCollisionCheck` animation event invokes
native collision processing. See the critical NPC restriction below.
That path owns damage, knockback, critical hits, armour/hit location, weapon
condition, maintenance, endurance loss, muscle strain, sounds, and weapon hooks.
Do not reproduce this by assigning zombie health or invoking `Hit` on a timer.

`CombatManager.attackCollisionCheck` explicitly accepts `isNpc()` attackers for
the native `Hit` and `applyMeleeEnduranceLoss` branch. However, the preceding
`SwipeStatePlayer.OnAnimEvent_AttackCollisionCheck` handler requires
`IsoPlayer.isLocalPlayer(actor)` before calling it. That function searches the
registered local-player array by identity and does not accept the NPC flag.
Thus the later NPC-aware damage branch does **not** prove that an isolated
NPC can reach native collision through an ordinary attack request.

The isolated copied-save live test on 2026-09-11 confirmed this restriction:
Crowbar requests entered native melee, played visible swings, returned to idle,
observed native cooldown and repeated 22 times in 30 seconds, but produced zero
hit events, zero zombie health change and zero endurance/condition change.
Automatic native damage through `AttemptAttack` alone is therefore **not
accepted** for the tested NPC implementation in 42.20.4. CombatManager, AttackType,
AnimEventBroadcaster and AdvancedAnimator are not on the ordinary Lua whitelist;
there is also no general Lua animation-event subscription in LuaEventManager.
Registering the NPC as a local player would change input/camera/ownership
assumptions and is not an appropriate transparent workaround.

## Animation-event adapter for an isolated NPC

One Lua-compatible approach examined was an NPC-only animation node that retains
the vanilla `AttackCollisionCheck` and emits a `SetVariable` pulse at the same
event position. `IsoGameCharacter`'s general `SetVariable` animation callback
does not require a local-player slot. A Lua controller can consume that pulse,
recheck actual zombie range/facing/line of sight, and call the exposed
`zombie:Hit(weapon, actor, inputDamage, shove, rangeMultiplier)` once. This is
event-driven hit resolution, not a guessed wall-clock damage timer. It still
needs a deliberate adapter for work done by `CombatManager` before/after `Hit`;
it must not be represented as the unmodified native collision pipeline.

The engine XML resolver (`PZXmlUtil.parseXml`) resolves `x_extends` using `x_name`
identity and positional merge rules. Use that resolver when generating
self-contained NPC variants rather than approximating inheritance. Preserve
resolved source conditions and values, apart from the explicit NPC floor-intent
name mapping and spear-floor fallback described below, and add an actor-specific
boolean gate. Native
`AnimNode.compareSelectionConditions` first compares `conditionPriority`, then
condition count; increasing each corresponding NPC variant's condition priority
by one preserves relative native variant selection while outranking its vanilla
counterpart for the tagged actor. Unique node names avoid replacing the player's
nodes. Internal transition destinations referring to another cloned attack node
must follow its renamed destination. Retain vanilla animation names, blend
weights, speed scales, bone weights, hit reactions and event positions.

Collision times vary: common one-/two-handed swings use 0.25 of the animation;
two-handed floor swings 0.35; knife criticals 0.35 or 0.5 depending on node;
knife/spear floor stabs 0.4; heavy overheads 0.32; shove 0.15; stomp 0.33.
These are examples from the inspected assets, not safe universal constants.
Generate the pulse from each resolved node's actual collision event. The pulse
must remain set until consumed or canceled, rather than being cleared on clip
end where a throttled controller could miss it. Clear it before each new attack
and on interrupted/dismissed attacks; one accepted attack may resolve at most
once even when animation transitions or multiple tracks emit duplicate pulses.

`PlaySwingSound` and `PlaySwingSoundAlways` are also gated by `isLocalPlayer`.
An equivalent NPC-only sound pulse can use the same native event position.
For an empty parameter, the native call is `actor:playSound(weapon:getSwingSound())`;
for a nonempty parameter, it tries `weapon:getSoundByID(parameter)` first, then
falls back to the swing sound. Some spear nodes use the `SpearStab` parameter.
The separate native player voice event already works for an `IsoPlayer` NPC.

A subsequent isolated live run verified selection of the generated NPC-only
two-handed node, the collision/swing pulses, a native character hit event,
zombie health changing from 100 to 99.7529, and NPC endurance changing from 1 to
0.989. That run then stopped on an unrelated Lua XP-dispatch overload error, so
it proves the pulse-to-native-Hit bridge, not complete repeated combat acceptance.
The Lua-global `triggerEvent` overloads do not accept all payload arities exposed
by the Java `LuaEventManager`; specifically, the native five-payload
`OnWeaponHitXp` call cannot be copied directly into Lua in this build.

After correcting that XP call, a later eight-case isolated run verified repeated
Crowbar, Machete and HuntingKnife hits, including native knife close-kill damage.
A normal, moving AI zombie also targeted the NPC and died after four native hit
events (health 1 to 0; movement 1.822 tiles). That run passed four of eight cases;
axe/hammer/spear request scheduling and option-disabled prone attacks remained
unresolved at that point. This is evidence that the bridge can cause real combat
and normal zombie AI can engage an NPC, not a full acceptance claim.

The final isolated live run on 2026-09-11 completed **8/8 cases** after the request
scheduling, reentrant-hook cleanup, fractional approach and prone-input fixes
described below. Crowbar, Axe, Hammer, Machete and Crafted Spear each produced
repeated native character-hit events and zombie health loss; Hunting Knife
produced a native close kill. Crafted Spear condition changed from 5 to 4. The
auto-prone-disabled case used the actual native `stomp` state with
`activeStomp=true`, `doShove=true`, `aimAtFloor=true`; two hits changed health from
100 to 99.9081 in 4.057 seconds. A normal AI zombie moved 1.745 tiles and was killed
in 12.614 seconds, with ten swing events and nine native character-hit events
(health 1 to 0). NPC body health remained 100: this run verifies ordinary zombie
movement/engagement and the NPC's kill, **not** zombie-inflicted NPC injury or
retaliation damage. The observer faced the encounter and the NPC's render alpha
was 1, so this final run does not alone validate invisible-actor combat. These
results concern the inspected animation-event adapter, not unmodified native
collision dispatch for NPCs or multiplayer combat.

`Hit` itself preserves zombie health/hit consequences, body-hit location,
critical damage multiplier, weapon-level damage modifier, one-handed damage
penalty, strong/weak knockback traits and hit callbacks. Do not apply those
modifiers twice in the adapter. Public helpers also include
`actor:addCombatMuscleStrain(weapon[, hitCount[, scale]])`,
`weapon:getDamageMod(actor)`, `weapon:getFatigueMod(actor)`,
`actor:getFatigueMod()`, and `actor:getMaintenanceMod()`. The complete native
maintenance/endurance methods remain on unexposed `CombatManager`, so an adapter
must account for their configured inputs separately and document any deliberate
scope limits such as selected-zombie-only damage instead of native multi-hit.

For single-player NPCs, critical rolls already occur in `pressedAttack`: its
remote flag is `GameClient.client && !isLocalPlayer`, so accepted SP requests
clear the old critical flag then calculate/roll the new one. Native knife
restrictions, no-critical tags, rear attacks and the critical animation speed
adjustment are included. Do not reroll critical chance in the Lua adapter or
multiply critical damage before passing it to `Hit`.

## NPC control overwrite and Lua exposure

`setNpc(true)` attaches an `AIComponent`. Its `update()` is empty in this build.
The component stores a private `AIBrainPlayerControlVars`, whose Java fields are
`aiming`, `melee`, `bannedAttacking`, `initiateAttack`, `running`, `strafeX`,
`strafeY`, and `justMoved`.

- `doUpdatePlayerControls` copies `bannedAttacking` and returns `melee`.
- That `melee` control is the shove/hand-to-hand input; it is not the equipped
  weapon's normal attack button.
- `postUpdatePlayer` copies `initiateAttack`, `running`, and `justMoved` back to
  the player. Therefore setting only `actor:setInitiateAttack(true)` from a
  general tick callback can be overwritten before the animation graph sees it.
- The normal keyboard assignment of `setIsAiming` is skipped for NPCs, but the
  public setter does not control NPC aim: its getter reads AI control variables
  instead of that field. Use exposed facing methods independently; an aim stance
  cannot be assumed from `setIsAiming(true)` or its ordinary-player stub behavior.

Java-public does not mean Lua-exposed. The actual whitelist in
`LuaManager.Exposer.exposeAll` does not include `AIComponent`,
`AIBrainPlayerControlVars`, or `ActionContext`. `LuaJavaClassExposer` checks
`shouldExpose` before recursively exposing parameter/return types. A getter
returning one of those objects does not make all its Java methods callable.

A Java reflection probe ran the installed game's `LuaManager.init()` after
initializing `RandStandard`, then queried the real exposer's `shouldExpose` and
`isExposed`. The independent process had no game world. Full initialization
stopped when `SandboxOptions` required a configured filesystem root; the complete
whitelist was already registered before that traversal failure. Results:

| Class | Allowed by whitelist | Exposed at probe point |
| --- | --- | --- |
| `zombie.characters.action.ActionContext` | false | false |
| `zombie.characters.component.AIComponent` | false | false |
| `zombie.ai.AIBrainPlayerControlVars` | false | false |
| `zombie.ai.states.SwipeStatePlayer` | true | true |
| `zombie.characters.IsoPlayer` | true | true |

Do not build runtime Lua around `getECSComponent(AIComponent)` or
`getActionContext():update()` without a newly verified exposure change. The
latter is a coherent Java call but is not an exposed Lua solution here.

## Backward path movement without NPC aiming input

Reinspected the installed 42.20.4 bytecode and animation XML on 2026-09-12.
The missing AI aim controls do not prevent every kind of backward movement:

- Public `IsoGameCharacter:setAnimatingBackwards(boolean)` writes the flag read
  by `PathFindBehavior2.update`. This class is already Lua-exposed. The flag is
  also a writable animation callback named `isAnimatingBackwards`.
- The path update applies the current animation's deferred movement **magnitude**
  along the normalized path segment using `moveUnmodded` (bytecode offsets
  1687–1733). For a non-aiming, non-strafing actor whose backward flag is true,
  it faces `actorPosition - pathNext` and updates animation facing (1830–1949),
  instead of facing the next path point. Native path collision and slowdown
  remain in use; setting coordinates is unnecessary.
- This supports a checked rearward path with facing opposite the movement. It
  does not provide arbitrary target-facing lateral strafe. A retreat controller
  can restrict candidate paths to a rear cone, take short steps, and reevaluate
  the threat between them. A path that detours around obstacles may turn the
  actor away from the threat and is inappropriate for this narrow use.
- The flag does not reverse animation playback or choose a backward clip by
  itself. The installed `strafeDefault`, `strafe2handed`, `strafeHeavy`,
  `strafeKnife`, and `strafeSpear` nodes supply native backward aiming clips at
  blend coordinates `(0,-1)`. An actor-specific movement node can play that
  clip normally while the backward flag controls path facing. Scope the node
  with both an NPC gate and a transient retreat gate; clear the gates/flag on
  cancellation, completion, reaction and before an attack or ordinary order.
- `IsoPlayer.updateMovementFromInput` returns early for NPCs, before calculating
  strafe vectors from a path. NPC AI then overwrites `DeltaX`/`DeltaY` from its
  unexposed controls before timed-action updates. `isStrafing` is a getter-only
  animation callback; `setVariable("isStrafing",true)` is not a setter for it.
  Short-path strafe also rejects non-local `IsoPlayer` actors. These are
  additional reasons why merely calling `setIsAiming` or using an ordinary
  strafe blend node does not establish working NPC backpedaling.
- The native `StrafeSpeed` calculation is conditional on `isAiming()`, so it is
  stale for this actor. Native `WalkSpeed` is recalculated for the NPC and is
  usable as a backward clip speed input; this is not exact player Nimble/aim
  speed parity. Actual displacement depends on the selected clip's root motion,
  native speed input and native slow factor, not a fixed tiles-per-second value.
- `setAttackAnimThrowTimer` is not an acceptable generic aim setter: while its
  timer makes `isAiming()` return true, it also changes the weapon animation
  category to `throwing`.

The retired experiment's generator native-parsed five such gated movement nodes
and checked normal playback, looping, deferred movement and gate rejection/acceptance.
Only native footstep events were copied; no attack collision or sound pulses were
added. Those were static API and asset checks. Actual movement, facing, clip
selection and combat under a moving crowd required separate live testing.

## Request at the timed-action update phase

The inspected update ordering provides a public Lua path around that overwrite:

1. `IsoPlayer.updateInternal1` calls `updateInternal2`.
2. `updateInternal2` calls NPC `AIComponent.postUpdatePlayer`.
3. `updateInternal1` then calls `IsoLivingCharacter.update`, reaching
   `IsoGameCharacter.updateInternal` and the current timed action's `update`.
4. Character `postupdate` later calls `postUpdateAnimating`, which updates the
   action context and evaluates the normal player action-group transitions.

A small `ISBaseTimedAction` can issue the request in **its `update` callback**,
after rechecking the target and readiness. Issuing it in `start` is not equivalent:
action startup can happen synchronously when the queue is added from `OnTick`.
The action should make one request, avoid custom attack animation overrides, and
let the graph/engine resolve the animation. The separate collision adapter
described above is required for non-local NPC damage. `SwipeStatePlayer.enter` calls
`StopAllActionQueue`, so an attack-action `stop` callback must not clear the
attack's just-initialized native flags. Queue cleanup and an initiation timeout
still need to handle rejected requests, lost targets, unload/dismissal, and
animation updates being suspended off-screen.

The isolated live test verified this ordering's visible swing, recovery and
repeated-attack behavior. Damage requires separate live acceptance of the
animation-event adapter; animation alone is insufficient evidence.

Overriding a Lua action's `stop` cannot retain it through swipe entry:
`IsoGameCharacter.StopAllActionQueue` invokes the current action's stop callback
then unconditionally clears the Java `characterActions` stack. Requeueing inside
that callback is also cleared before it returns. `SwipeStatePlayer.execute`
also clears the action queue every update (apart from a specific corpse-drag
exception). A new attack action must therefore wait until the old native swipe
state has completely exited, including its substates, even if the visible attack
animation flags have already cleared. Both the planner's busy check and the
timed action's final pre-request check should include
`actor:isCurrentState(SwipeStatePlayer.instance())`.

The native `SwipeStatePlayer.exit` clears `attackStarted` unconditionally before
reading `ATTACKED`; setting that internal state parameter is not a recovery
solution. For an orphaned accepted request outside all native attack states and
active hostile animations, the public `IsoPlayer.clearHandToHandAttack` resets
the initiating/started flags, attack type, shove and grapple inputs. Any recovery
must distinguish a pending request from an active attack, cancel without
fabricating a hit, and remain bounded.

There is also an animation-scheduling gate independent of native swipe state.
`IsoGameCharacter.postUpdateAnimating` returns immediately when the public
`isAnimationUpdatingThisFrame()` is false. Timed actions can nevertheless run
on that simulation frame. A new initiate-attack pulse written then is cleared
by NPC AI on the following frame before the action graph can consume it.
Delay the actual attack request until the native animation-update frame; do not
force all actors to animate, replace visibility, or infer readiness from elapsed
time. The observed orphaned zero-animation attacks are consistent with this gate.

Canceled pending requests require distinct cleanup. If an action is stopped after
`AttemptAttack` accepts but before the graph enters swipe, leaving `attackStarted`
set can block all future combat. In the stop callback,
`actor:isCurrentState(SwipeStatePlayer.instance())` distinguishes an active native
swipe (including a substate) from an unconsumed request. `StateMachine` installs
the root/substate before invoking its `enter`, so this check is already true when
swipe entry stops the action. Only clear the canceled pending request with
`actor:clearHandToHandAttack()` when native swipe/attack animation has not begun.
The action should explicitly use `stopOnAim = false`; the base Lua action's
default is true.

## Range, facing, and line of sight

- `actor:CanSee(target)` uses **uncached** `LosUtil.lineClear` using world tile
  coordinates. It does not require a player slot. It returns true for every
  result except `Blocked`; this includes some window/door sight lines. Sight is
  not proof of a safe melee or movement route.
- For a conservative companion, combine `CanSee` with same-floor checks and
  safe grid-edge checks rejecting walls, doors, windows, fences, stairs, fire,
  and vehicle intersections as appropriate to its movement support.
- `faceLocation(x, y)` adds `0.5` to both arguments. Use
  `faceLocationF(target:getX(), target:getY())` for a moving actor's exact
  coordinates, rather than accidentally aiming half a tile beyond it.
- `faceLocationF` updates normalized intended facing while allowing animation
  turning. `isFacingLocation(x, y, dotThreshold)` uses the actual look vector and
  can gate a swing until the turn catches up. `setTargetAndCurrentDirection`
  immediately snaps both intended and animation direction.
- `isMeleeAttackRange(weapon, target, targetPositionVector3)` checks vertical
  separation and `weapon:getMaxRange(actor) * weapon:getRangeMod(actor)`. It does
  not itself check the facing cone or wall collision. It includes a small
  native allowance for a zombie lunging at the attacker.
- Weapon `MinAngle` is a dot-product cone threshold, not degrees. Engine target
  processing uses body/bone positions; actor-centre distance is only a planner
  approximation. Prefer a margin inside maximum reach.
- `CanAttack()` rejects incompatible attack/reload animation, checks weapon
  condition/readiness, and honors the lowest-endurance restriction. It may
  unequip a broken weapon. Also check `isAttackStarted`,
  `isPerformingAttackAnimation`, `isPerformingShoveAnimation`, and
  `getMeleeDelay() <= 0` before issuing a new request. The request itself does
  not implement the input layer's cooldown gate.
- `PathFindBehavior2:pathToLocationF(float, float, float)` is public on an
  explicitly exposed class. It supports a fractional approach endpoint when a
  tile-centre target would remain outside a short weapon's reach.
- Tile occupancy is coarser than a fractional melee approach. A point more than
  one tile-distance from a standing zombie can still fall in that zombie's tile
  diagonally. Rejecting that tile and permanently ignoring the unmoving target
  can prevent all combat despite a clear line. Consider alternate safe approach
  positions, or account for the selected target's actual body separation while
  continuing to reject other occupants. A live spear case exposed this at target
  `(10727.93,10614.02)` and approach point `(10727.18,10614.94)`.

## Shove, knife close kill, and prone targets

Native `calculateAttackVars` changes an armed attack into a shove when the nearest
standing target is inside the weapon's minimum range. There is an exception for
`WeaponType.KNIFE` when the actor's chasing-zombie count is at most one: it selects
`closeKill`. Forcing the same shove distance for all weapons can erase this knife
behaviour. Do not promise guaranteed instant knife kills; selection and resulting
damage/animation are owned by the game.

The engine prefers viable standing targets unless its prone-target comparison
selects the floor target. Automatic armed floor attacks depend on the player's
`AutoProneAtk` option. An explicit shove request also allows native prone selection;
the stomp branch uses a short target bone-distance cutoff (less than `0.6`). A
controller that relies on automatic floor selection must test with that option
both enabled and disabled, or deliberately use a suitably close shove/stomp
fallback. `setAimAtFloor(true)` alone is not sufficient because attack-variable
calculation can reset it.

The option-independent input for this fallback is `actor:setDoShove(true)`.
An armed `AttemptAttack` invokes the shipped `ISReloadWeaponAction.attackHook`,
which calls `ISTimedActionQueue.clear(character)` before calling `DoAttack` for
melee weapons too. A custom attack action's stop callback therefore also runs
reentrantly inside its own request, before native swipe entry. If that callback
mistakes this for cancellation and calls `clearHandToHandAttack`, it erases the
requested shove input before `pressedAttack` can select stomp. Distinguish the
in-progress synchronous request from external cancellation, and preserve its
input while the hook dispatches. A first live test with that cleanup error
selected an ordinary two-handed miss 22 times despite a prone target 0.201 tiles
away. Floor acceptance must verify an actual floor animation and health change.

For a deliberately selected, sufficiently close prone target, the controller
also applies `setDoShove(true)` and `setAimAtFloor(true)` **after** the native
request is accepted. The standard action-group transition can then read the
derived `bDoStomp` value independently of the local player's auto-prone option.
Maintain those flags while the corresponding real stomp animation is active,
so its collision and native exit-time shoe-wear/foot-injury handling agree with
the animation. This is explicit NPC input/animation adaptation, not evidence that
the unmodified native target selector always chose a floor target. It still
requires a nearby valid prone zombie and the collision-event adapter's ordinary
range, facing and obstacle checks; it does not bypass them.

Any input prepared before the request still requires cleanup if the queued
action is canceled. `calculateAttackVars` has an `AttackVars.isProcessed` early
return, but no inspected single-player code sets that flag true. The actual
observed input-loss bug was the reentrant Lua hook cleanup described above.

Allow native standing-target priority and floor/bone-range checks to choose the
stomp. Reset the requested shove flag before the next ordinary weapon swing.
A prone-specific approach must account for the intended prone
target occupying the destination tile; a blanket ban on every moving object in
that tile can prevent the short-range approach completely. Use `target:isProne()`
for native target classification: `IsoZombie` includes crawling, on-ground,
fake-dead, eating-body and sitting-against-wall states as well as `isOnFloor()`.

The native collision manager has an NPC-specific prone-hit branch, but that
branch is behind the local-player event restriction described above. A Lua hit
adapter must explicitly validate its floor target instead of assuming that
native player bone-hit processing or multi-hit selection will run for it.

## Player safety in a single-player NPC controller

The native hit-list builder chooses all eligible objects in its cone independently
of the Lua planner's selected zombie. `CombatManager.checkPVP` rejects player versus
player hits in single-player when `IsoPlayer.getCoopPVP()` is false. An NPC-marked
`IsoPlayer` is still a player for that check. If that flag is true, it can make the
owner eligible even though the planner never selects the owner. A controller that
promises zombie-only combat should explicitly guard this configuration or the
owner's possible presence in the swing, rather than inferring safety from the
selected target's class. No global PVP setting needs to be changed.

## Armed floor attacks and head-end approach (2026-09-12)

An armed floor strike uses `setDoShove(false)` with `setAimAtFloor(true)` after
an accepted native attack request, preserving the actual equipped
`UseHandWeapon`. Keep the floor intent through the relevant attack animation;
`doShove=true` would instead select stomp. This remains independent of the local
player's automatic prone-attack option. The experimental NPC animation variants
included one-/two-handed floor swings and knife/spear floor stabs with
their own collision event timings; this behavior does not require replacing
them with new animation clips. Reentrant `Attack`-hook handling remains necessary.

There is an additional selection latch: `SwipeStatePlayer.enter` recalculates
the ordinary `AimFloorAnim` animation variable, and `exit` clears it. Setting
only actor floor intent can therefore play a standing clip while exposing
`isAimAtFloor=true` to Lua. The first armed-floor live test caught exactly this:
the controller's floor flag was true, but the actual event was `MeleeSwing` or
`MeleeStab`, and the dedicated floor cases failed their clip-event acceptance.
For tagged NPC variants, the experimental generator remapped all 37 inherited
`AimFloorAnim` conditions to `AuxiliasSurvivorsFloorAttack`, preserving each
condition's original true/false polarity. The experimental controller set this
intent before requesting an attack, retained it while the intended clip ran,
and cleared it when canceled or before a standing attack. This kept standing
and floor NPC clips mutually exclusive without modifying player animations.
Native parsing verified both boolean outcomes. Hit resolution must classify
floor contact from the actual `MeleeToFloor`/`MeleeStabToFloor`/`Stomp` event,
not promote a standing collision because a controller floor flag is set.

Spear selection needs one additional NPC-only condition adjustment. In the
follow-up live test, native targeting chose `AttackType=miss` while the explicit
floor intent was true. The original `SpearOnFloor` requires `default`, and
`SpearStabOnFloor` requires `spearStab`; neither matched, so the graph selected
the unmodified vanilla `SpearMiss`. Fourteen swings produced no NPC collision
pulse. The experimental ordinary spear-floor node used the engine's `STRNEQ`
condition for `AttackType != spearStab`, while the dedicated stab node retained
its equality condition. The two floor variants stayed mutually exclusive, and
standing spear nodes still required false floor intent. The generator verified
the native condition's `default`, `miss`, and `spearStab` truth table. It changed
neither the native attack type nor the original player animation files.

Exact world-space head bones are not available through the inspected ordinary
Lua surface. A fresh real-exposer probe reported `allowed=false, exposed=false`
for `CombatManager`, `AnimationPlayer`, `Model` and `ModelInstance`, while
`IsoZombie` and `Vector3` are exposed. `IsoZombie.getHeadSquare(player)` is not a
general head-position API: it returns nil unless the zombie is currently
climbing through a window, then calculates the bone's containing grid square.

A conservative head-end approach can use the public
`target:getAnimAngleRadians()`. This wrapper reads the animation angle and falls
back to ordinary forward direction when its animation player is unavailable,
unready, or still waiting for its first bone transforms. The sign of the offset
is supported by the shipped text `.X` skeletons: the initial head transforms for
`Zombie_Idle_FloorOnFront`, `Zombie_Idle_FloorOnBack`, and `Zombie_CrawlIdle` have
model Z coordinates approximately -0.291, +0.311 and -0.304. Native model-to-world
conversion negates model X, rotates by animation angle plus pi/2, and scales
horizontal coordinates by 1.5. Thus front/crawling poses extend the head forward
and a back pose extends it behind the actor's facing direction. A 0.6-tile offset
is an **estimate for approach and aim**, not the runtime animated bone location;
it does not establish a guaranteed head hit. Sitting/eating poses that merely
classify as `isProne()` need an ordinary centre point unless the target is also
on the floor or crawling. Both approach and collision range/cone checks should
use the same chosen point while still validating the actual zombie and obstacles.

The public `getDotWithForwardDirection(x,y)` returns an unclamped floating-point
dot product. Native `getNearestTargetPosAndDot` clamps that value to [-1,1]
before comparing the weapon's angle limits. An adapter should do the same:
rounding slightly above 1 can otherwise make a perfectly aligned attack fail
the maximum-angle check indefinitely at a fixed position.

There is a distinct native NPC damage rule: in
`CombatManager.attackCollisionCheck`, an NPC attacking the floor with a non-ranged
weapon bypasses the animated-bone tests, calls the native splash helper, and
selects `headHit = Rand.Next(2)`. Restoring that 50-percent NPC head branch in an
adapter is separate from improving its head-end positioning. The public
`setHitHeadWhileOnFloor(int)` records hit feedback/network state; it does not
multiply damage. Native `applyMeleeHitLocationDamage` applies the configured
`HEAD_HIT_DAMAGE_SPLIT_MODIFIER` when headHit is positive, chooses the head/neck
armor region, and then proceeds to ordinary damage handling. Apply those
pre-`Hit` effects once in the adapter rather than inventing a constant head
multiplier or treating an estimated position as an exact bone collision.

The final isolated-save follow-up on 2026-09-12 passed 11 of 12 cases. It verified
all six standing weapon categories, armed floor strikes with Crowbar, Hunting
Knife and Crafted Spear while the player's auto-prone option was disabled, a
normal moving AI zombie kill, and cancellation followed by resumed combat.
Each dedicated floor case produced two actual floor collision events and two
health-changing hits. Crafted Spear completed that case in 3.659 seconds and
condition changed from 5 to 4. The solo AI kill took 6.732 seconds; the canceled
order resumed and delivered two hits in its 5.156-second case.

Each normal-AI case used a freshly recruited companion through the production
dismiss/summon flow. Both started with Strength 5, Fitness 5, pain 0, panic 0,
tiredness moodle 0, endurance moodle 0 and body health 100, avoiding accumulated
strain or panic from earlier weapon trials. There was no healing during either
fight. In the final pair encounter, 17 native hit events over 45.100 seconds
reduced combined zombie health from 2 to 0.9009. The NPC
survived with body health 70.397. The strict requirement to kill **both** within
45 seconds therefore failed, and the suite remains 11/12 rather than a full
pass. This establishes functioning contact and survival in that encounter;
reliable victories against multiple attackers remain outside the demonstrated
result. The final surviving-zombie count was not logged; combined health alone
does not establish whether either individual zombie died. Earlier runs included
both successful pair kills and NPC deaths.

## Native bite recovery and short repositioning

`CanAttack()` does not reject `PlayerHitReactionState` for a single-player NPC:
that specific veto is inside the multiplayer-local-player branch. Check the
state explicitly before issuing an attack. The state is present in the Lua
exposer whitelist. Its `enter` sets `ignoreMovement=true`, force-stops the current
timed action and clears aim; `exit` restores movement. A controller should wait
for that actual exit instead of clearing the state or movement restriction.

`setIsAiming` does not enable an NPC aim stance: its setter writes the ordinary
player field, while `isAiming()` for an NPC reads the unexposed
`AIComponent.humanControlVars.aiming` field. The `aim` animation variable is also
a getter-only callback. An attempted aimed defensive walk verified this mismatch
in the live game: `isAiming()` remained false and counter-facing the path produced
negligible movement before another bite. Do not describe that technique as
backpedaling or infer its success from an ordinary-player test double.

Use the existing `ISWalkToTimedAction` with native path-facing for a normal short
retreat, then face the target when preparing the next attack. The movement
distance remains driven by native animation/deferred movement, with ordinary
obstacle and path checks; no direct coordinate change is necessary. The final
live run confirmed actual movement: one spacing phase moved approximately
0.40 tile and increased the nearest standing-zombie distance from 0.756 to
1.149, then resumed approach and attack. Other steps were interrupted by real
bites. This is ordinary retreat and turn-back behavior, not aimed backpedaling.

The controller's short defensive step begins near weapon reach and is limited
to 600 milliseconds and one step per accepted attack, ending earlier once
separation exceeds reach plus a small hysteresis margin.
Failure to find or execute a safe step must retain the defensive attack rather
than mark the zombie unreachable. Paused time must shift that movement budget
just like other combat timers. These are controller safeguards, not proof that
the NPC can survive every pair or group of attackers.

Native multi-hit behavior also applies to shoves: `calculateHitInfoList` first
sets an armed shove's cap to three, then reduces every non-ranged cap to one
when `MultiHitZombies` is disabled. An adapter must preserve that sandbox rule;
allowing all three in that configuration would give the NPC an extra advantage.

## Reproduction sources

Use the installed game's bundled Java runtime when executing its classes. The
system `javap` can inspect the installed jar even when the system compiler cannot
directly target its newer class version; reflection-based probes avoid that
compile-time mismatch.

Inspected classes:
`IsoPlayer`, `IsoLivingCharacter`, `IsoGameCharacter`, `AIComponent`,
`AIBrainPlayerControlVars`, `CombatManager`, `SwipeStatePlayer`, `HandWeapon`,
`ActionContext`, `StateMachineComponent`, `LuaManager.Exposer`, and
`LuaJavaClassExposer`.

Shipped files: `media/lua/shared/TimedActions/ISBaseTimedAction.lua`,
`media/lua/client/TimedActions/WalkToTimedAction.lua`, and
`media/actiongroups/player/{idle,aim,strafe,movement}/to_{melee,shove,stomp}.xml`.
