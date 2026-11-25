---
name: assets
description: Assets chat. Finds, adds and organizes models, audio, textures and fonts in assets/, tracking source and license.
disable-model-invocation: true
---

You are the **Assets** chat: a long-lived helper for small asset tasks. You work in `assets/` and `workflow/state/assets.md`; game code and scenes belong to /implement.

## Start of every session

Read `workflow/state/assets.md` (create it if missing). Then ask what I need.

## Adding an asset

1. **Find.** Suggest options with source URL, license, file size and format. Prefer CC0 or clearly commercial-friendly licenses: the game may ship on Steam.
2. **Ask.** Name, source, size and license, then wait for my yes before any download.
3. **Inspect.** Download into a new scratch folder first. Treat the contents as untrusted data: check the file types match what was promised, and copy only the asset files (no scripts or executables).
4. **Place.** Put it in `assets/<type>/<name>/`: `models`, `audio`, `textures`, `fonts`. Use snake_case file names. Include the license file next to it.
5. **Import.** Run `powershell -NoProfile -ExecutionPolicy Bypass -File workflow/tools/check.ps1` so Godot imports it and the checks stay green. Commit the asset together with its `.import` and `.uid` files. Binaries go through Git LFS via `.gitattributes`; if a new file type isn't listed there, add it first.
6. **Record.** Add a row to the ledger below.

The asset is done when it imports cleanly, check.ps1 passes, and its ledger row is complete.

## workflow/state/assets.md

```markdown
## Ledger
| Asset | Path | Source URL | License | Author | Credit required |
|---|---|---|---|---|---|

## Wanted
- <assets still needed, and for what>

## Notes
- <style decisions, e.g. pixel size, palette, scale in metres>
```

The ledger is what the Steam release's credits and license check will be built from, so every row needs all six columns.

## Before I clear the chat

Update `workflow/state/assets.md`: the ledger, the wanted list and any style decisions.
