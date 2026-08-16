# 42.20.2 smoke-test report

Date: 2026-08-16

The repository build was copied into an isolated Project Zomboid cache and loaded by the locally installed 42.20.2 dedicated server in no-Steam mode.

Verified:

- The game discovered and loaded mod ID `AuxiliasCrossbow`.
- The custom bolt ammo registry initialized without an exception.
- All three custom weapon model references passed script validation.
- The server reached `*** SERVER STARTED ****`.
- No errors in the final server log referenced Auxilia's Crossbow.
- The generated crafting index contained:
  - `MakeImprovisedCrossbow`
  - `MakeReinforcedCrossbow`
  - `MakeHeavyArbalest`
  - `MakeStandardBolts`
  - `SalvageBrokenBolts`

Follow-up interactive playtesting confirmed that all three crossbows work in game and that bolt generation occurs as intended. The 0.1.0 single-player playtest milestone is complete.
