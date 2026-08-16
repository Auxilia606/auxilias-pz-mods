# Deferred multiplayer follow-up list

Multiplayer implementation and empirical testing are the project's lowest-priority
work. New code should still avoid design choices that would unnecessarily prevent
future multiplayer support, but dedicated-server and multi-client validation is
deferred until the planned single-player work is complete.

Before eventually declaring multiplayer support, verify:

- Bolt recovery is authoritative on the server and never duplicated by clients.
- Animal and zombie inventories replicate the recovered/broken bolt exactly once.
- Custom reload speed is identical on client and server timed actions.
- Loot-table injection is performed once per server startup.
- Debug test-kit spawning is restricted to administrators.
- Weapon state, loaded bolt count, and reload interruption survive reconnects.
