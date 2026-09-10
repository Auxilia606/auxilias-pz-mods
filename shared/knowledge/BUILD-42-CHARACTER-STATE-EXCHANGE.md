# Native character state reload inside existing actors

Installed engine inspection: 42.20.4 b0bbce05d5, 2026-09-12. Active target comes
from `config/project-zomboid.json`. This records native behavior; mod-specific
acceptance and fixture results belong in the consuming mod's docs.

The fixture diagnostics cited here came from the Auxilia's Survivors experiment,
retired and removed on 2026-09-12. No state-exchange implementation or test harness
is distributed here; these engine findings are preserved for future research.

An actor object, its native local/database role and the person represented by
its contents are distinct. Exchanging contents can keep the local IsoPlayer
object and sqlId fixed. Stable person IDs must travel with their own state, while
the original-person identity and current controller remain separate metadata.

Native load into an existing character is not by itself a complete replacement.
Some lists/maps append, and absent fields leave previous values behind. Inspection
identified readBooks, knownRecipes, readLiterature, mechanicsItem and alreadyReadBook
collections, existing hands/worn slots, ModData and Fitness collections as requiring
explicit cleanup before a current-version reload. BodyDamage's full-health reset
clears prior wound/thermoregulator state before native deserialization restores
the incoming body; it also resets Stats, which the native stream then replaces.
XP/trait/visual loaders have their own clearing behavior and must be audited
individually rather than assuming every loader behaves alike.

Stats, BodyDamage, XP, Nutrition, Fitness, Moodles and inventory containers hold
actor ownership/context. Retain those containers with their carrier actors and
replace their contents through native loading. Merely swapping their references
can leave physiological updates attached to the wrong actor. Item instances may
be reconstructed; persistent item IDs/content, proper container/equip-parent
references and item processing registration must be verified after loading.

Current/moving square memberships must follow restored position. Deserialization
alone is not a world-registration or camera/HUD lifecycle. Restrict exchanges
to idle loaded actors and rebuild relevant presentation references. Pending
actions, animations and other native transient internals are not a persistent
person-state snapshot and are not safe to exchange during their execution.

In this build the native character serializer omits AttachedItems. To persist
attachment placement, serialize location-to-item-ID metadata and bind each
location to the item already restored in that person's native inventory. Do not
create another copy of an attached item. The managed serializer and loader hooks
must cover both explicit character files and PlayerDB bytes.

The explicit string saver also changes `saveFileName`. If a transactional state
exchange writes an NPC checkpoint and later fails, rollback must restore that
path alongside the character bytes; native death can delete saveFileName.

Derived moodles require a valid native world context. A headless human fixture
that omits IsoRegions.dataRoot can fail during Moodles.Update even after native
state replacement completed. Supply the real empty region data for a fixture;
do not remove the production moodle refresh to conceal a missing dependency.

Evidence: installed IsoPlayer/IsoGameCharacter, BodyDamage, Fitness, XP, HumanVisual,
ItemContainer and AttachedItems bytecode, plus native fixture diagnostics. Full
rendered gameplay and other mods retaining their own actor/item references need
separate compatibility testing.
