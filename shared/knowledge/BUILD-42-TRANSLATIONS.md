# Build 42 translation file format

Inspected 2026-09-10 against installed Project Zomboid 42.20.4 b0bbce05d5.

`zombie.core.Translator.tryFillMapFromFile`, inspected with `javap -c -p`, reads
`<mod version or common root>/media/lua/shared/Translate/<language>/<category>.json`.
It reads UTF-8 with `Files.readString` and parses a flat JSON object using
`org.json.JSONObject`. The language belongs in the directory, not the filename.

Examples: `Translate/EN/ContextMenu.json`, `Translate/KO/IG_UI.json`. Keys retain
their normal prefixes (`ContextMenu_`, `IGUI_`); values are translated strings.
The installed vanilla translation files use the same layout. This method does
not fall back to the legacy `<category>_<language>.txt` format.

Historical live evidence from the retired Auxilia's Survivors experiment
(removed on 2026-09-12): version 0.2.2 loaded and displayed its physical actor,
but the context menu showed `ContextMenu_AS_Companion` and dialogue showed
`IGUI_AS_Welcome`. Its legacy translation files were present but ignored. A
validator that only compares key parity in those files will miss this failure.

Use this finding for this inspected build; verify the translator again when the
central target changes. Keep identifiers stable during format conversion.
