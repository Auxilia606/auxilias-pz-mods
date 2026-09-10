# Primary character save/bootstrap ordering

Installed bytecode evidence: **42.20.4 b0bbce05d5**, inspected 2026-09-12.
The configured active target remains `config/project-zomboid.json`.

This research originated in the Auxilia's Survivors experiment, retired and
removed on 2026-09-12. The native-agent discussion records design constraints
and historical engine findings, not a currently distributed save adapter.

`PlayerDB.savePlayerAsync(IsoPlayer)` captures body state into a queued PlayerData
record. `saveLocalPlayersForce` also uses this path. GameWindow exit and IngameState
quit can force-save the local players **before** Lua `OnSave`. A Lua OnSave handler
therefore cannot reliably prepare the character's accompanying state before its
last native snapshot. OnPostSave is not a universal success/commit notification.

Startup selects default database row1, checks whether it is alive, and loads its
position before loading world chunks and the complete body. OnCreatePlayer,
OnGameStart and OnLoad are too late to change that bootstrap selection safely.
OnInitGlobalModData occurs before PlayerDB opens; OnLoadedMapZones is before the
in-world info lookup but after the earlier save-selection menu's alive check.

When the primary is dead, creating a new survivor does not load its old body or
its ModData. IsoWorld initializes the replacement slot/sqlId before OnNewGame;
it enables PlayerDB saving after OnNewGame. OnCreatePlayer/OnGameStart precede
normal world updates, but other mods can request forced saves in their callbacks.
Do not infer the replacement's identity from a stale world roster. Read a dead
row's envelope through the native store before it is overwritten, and guard a
fresh body's first save until that provenance is adopted. Native bare-player
construction for readback fires OnCreateLivingCharacter even without insertion
into the world, so check engine errors and clean up only that temporary body.

The local slot and native sqlId are different identities. Keeping one local
player does not automatically make that actor row1. `setPlayerMouse` assigns
row1 but also unregisters the outgoing emitter and enters AddCoopPlayer's world
and chunk lifecycle; it does not demote an outgoing row1 actor. A narrow native
handoff must update both actors' save identities together and roll back both if
the controller transaction fails. Do not rewrite SQL IDs externally while the
native save queue/allocator is active.

The legacy `map_p.bin` path was also inspected. Mere file presence makes the menu
helper treat the primary player as alive; both LoadPlayerForInfo and LoadPlayer
prefer the legacy file. Import later allocates another native ID, force-saves,
then deletes the legacy file before OnGameStart. A stale alive file after death
can consequently revive a character. Native no-argument save serializes before
opening its output but directly overwrites the file. This is unsuitable as a
rolling primary-player handoff mechanism. NPC snapshots use explicit paths.

`Core.setNoSave(true)` after PlayerDB initialization does not close its SQLite
connection or prevent every forced player write. It cannot be used as a reliable
late guard against loading a save with a missing native adapter. A default-menu
guard must be installed before that save is selected. Mod-disabled loading and
custom loading paths can bypass mod Lua entirely.

For an opt-in startup agent, hooking the native save method **before** PlayerData
construction permits a mod to validate dependent immutable NPC files and attach
their complete manifest to the active player's ModData before capture. SQLite
then commits that player's body and its manifest in one record. This does not
make terrain, vehicles, corpse/world items and all other world files one atomic
transaction. Callback failure must stop player capture, not merely log a Lua
error and continue; Kahlua protected-call results and error counters both matter.

The installed minimized Java runtime does not contain JDK-internal ASM classes.
An agent built against an unrelated full JDK's internal packages can compile and
still fail during premain on the game's runtime. Use a pinned permitted public
dependency and test actual startup instrumentation with the bundled runtime.
Core.getVersionNumber returns the release line (`42.20`) in this installation;
an exact archive SHA-256 provides a stronger compatibility gate than that string.

Primary sources: installed `GameWindow`, `IngameState`, `IsoWorld`, `PlayerDB`,
`PlayerDBHelper`, `LuaManager`, `LuaManager$GlobalObject`, and shipped
`MainScreen.lua`/load-screen Lua. Mod-specific implementation and acceptance
results belong under the consuming mod's docs.
