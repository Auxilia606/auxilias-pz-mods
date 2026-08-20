# Repository instructions

This is a Project Zomboid mod monorepo. Before changing a mod, read
`config/project-zomboid.json`, its entry in `config/mods.json`, and the relevant files in
`shared/knowledge`.

- Keep each independently released mod under `mods/<slug>` with its own `VERSION`,
  `CHANGELOG.md`, `docs`, `source-assets`, `tools`, and installable `workshop` tree.
- Do not hardcode the active Project Zomboid release line in new generators or root tooling.
  Read it from `config/project-zomboid.json`. Historical test reports may retain exact versions.
- Put engine behavior and version findings that apply to multiple mods in `shared/knowledge`.
  Keep feature design and balance evidence specific to one mod in that mod's `docs` directory.
- Put reusable runtime Lua in `shared/lua`, declare each consumer in `config/mods.json`, and run
  `tools/sync-shared.ps1`. Never edit a generated per-mod copy as the source of truth.
- Preserve published mod IDs, item IDs, recipe IDs, and translation keys unless an explicit
  migration is part of the task; they may be stored in existing saves.
- Follow `shared/branding/BRAND-GUIDE.md` for Workshop art. Keep the three 512px distribution
  images identical and retain the high-resolution source in the mod project.
- Run `tools/validate.ps1` after changes. Use `tools/package.ps1 -Mod <slug>` for a release
  candidate so package contents and checksums are audited.
- A release tag is namespaced per mod as `<slug>/v<version>`.
