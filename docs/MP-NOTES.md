# Multiplayer follow-up list

The first milestone is single-player. Before declaring multiplayer support, verify:

- Bolt recovery is authoritative on the server and never duplicated by clients.
- Animal and zombie inventories replicate the recovered/broken bolt exactly once.
- Custom reload speed is identical on client and server timed actions.
- Loot-table injection is performed once per server startup.
- Debug test-kit spawning is restricted to administrators.
- Weapon state, loaded bolt count, and reload interruption survive reconnects.

