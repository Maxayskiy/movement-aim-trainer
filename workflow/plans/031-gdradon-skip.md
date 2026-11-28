# Complexity gate passes files gdradon skips
Issue: #31
Status: approved (2026-11-27)

Bug found in #29 review r1 (`workflow/reviews/029-code-quality-checks-r1.md` and `-r1-codexchat.md`). check.ps1's complexity step (`workflow/tools/check.ps1:51-67`) can pass without grading a file.

Facts (checked 2026-11-27):
- check.ps1 runs `$radon = @(& "$venv\gdradon.exe" cc src)` (`check.ps1:56`). That captures stdout only. It fails only on a non-zero exit code (`:57`) or a C-F grade in stdout (`:60-66`).
- A valid script with a local named `from` (a Python keyword) passes gdformat, gdlint and Godot. gdradon converts GDScript to Python before grading, the conversion fails, and gdradon prints `Cannot process file 'src\planted_from.gd' due to exception: invalid syntax (<unknown>, line 3)` to **stderr**, prints nothing for that file on stdout, and exits 0. The same file with the local named `score` prints `F 2:0 probe - C (12)`. Reproduced in a scratch folder with the repo's venv (gdtoolkit 4.5.0).
- Any other Python keyword used as a GDScript name (`def`, `lambda`, `global`, `with`, `yield`, `del`, `except`, `raise`, `nonlocal`, `try`, `import`, …) is expected to do the same. Not all were tested.
- If `$venv\gdradon.exe` is missing (gdformat and gdlint present), `&` raises `CommandNotFoundException` as a non-terminating error (`$ErrorActionPreference = 'Continue'`, `:7`). `$LASTEXITCODE` still holds gdlint's 0, `$radon` is empty, and the step passes (Codex chat review r1 saw `ALL CHECKS PASSED` with a C (12) file planted). The setup check (`:33`) tests only gdformat.exe.
- `workflow/docs/quality-log.md:8` says "Run it in a fresh chat at a phase gate." It doesn't say the first audit runs at the end of phase 2, which plan 029 Behaviour 4 requires. The phase 1 gate playtest is still in the backlog (#15 first), so a fresh chat at that gate could start the log one gate early.

## Behaviour

What the developer and the agents see.

1. When gdradon reports a file it couldn't process, check.ps1 fails at the complexity step and prints one line per such file: `<file>: not graded (gdradon: <reason>)`, for example `src/planted_from.gd: not graded (gdradon: invalid syntax (<unknown>, line 3))`. Paths use forward slashes, like the grade lines. The fix for the developer is to rename the name that is a Python keyword.
2. Any other text gdradon writes to stderr also fails the complexity step and is printed as it is. Unknown output never passes silently.
3. When `gdradon.exe` isn't in the venv, check.ps1 fails at the complexity step with `gdradon not found at <path>` and the same reinstall hint as the setup check.
4. Grading is unchanged: C-F fails and prints `<file>: <name> <grade> (<score>)`; A and B print nothing; `tests/` isn't graded.
5. `workflow/docs/quality-log.md` "How to run an audit" says the first audit runs at the end of phase 2, before phase 3 tech files start, and that earlier gates (the phase 1 gate playtest, even if it's held later) don't start the log.

## Files to touch
- `workflow/tools/check.ps1`: complexity step only (`:51-67`). Check that `$venv\gdradon.exe` exists before running it. Capture stderr separately from stdout (for example `2>` to a temp file, or `2>&1` and split by type: in PowerShell 5.1 stderr lines arrive as `ErrorRecord` objects; convert them with `.ToString()`). Match `^Cannot process file '(.+)' due to exception: (.+)$` for Behaviour 1; any other non-empty stderr line is Behaviour 2. Collect these with the C-F lines and fail once, printing all of them. Keep the existing comment block accurate.
- `workflow/docs/quality-log.md`: line 8 (Behaviour 5).

## Sliders
None. No gameplay value changes.

## How to test
No test file changes. Every planted file is temporary: remove it, never commit it, and rerun check.ps1 to show it green again. Show each output.

1. **Reproduce first, before changing anything.** On the branch, before any edit, plant `src/planted_from.gd`: `extends Node`, one typed function with a local `var from: int = 0` and 11 `if` statements that each do `from += 1` (score 12). Run check.ps1: it ends with `ALL CHECKS PASSED`, and gdradon's `Cannot process file ...` line shows on the console. Show that output.
2. **Skipped file fails.** After the fix, the same planted file fails at the complexity step and prints `src/planted_from.gd: not graded (gdradon: invalid syntax ...)` (Behaviour 1).
3. **Grades unchanged.** Rename the local to `score` in the planted file: the step prints `src/planted_from.gd: probe C (12)` (or the planted function's name) and fails. With 5 `if` statements (B), it prints nothing and passes (Behaviour 4).
4. **Missing executable.** Rename `.venv\Scripts\gdradon.exe` to `gdradon.exe.bak` (the venv check.ps1 actually uses; in a worktree that is the main checkout's venv). check.ps1 fails at the complexity step with `gdradon not found at ...` (Behaviour 3). Rename it back and show a green run.
5. **Baseline.** With no planted files, check.ps1 passes and the complexity step prints nothing.
6. **Docs.** quality-log.md line 8 reads as Behaviour 5 says.

Behaviour 2 has no planted test: gdradon's only known stderr output is the `Cannot process file` line. Show the branch in the diff instead.

No screenshot: nothing visual changes.

## Out of scope
- Grading `tests/`, gdradon's wrong line numbers, a threshold change.
- A gdlint rule that bans Python keywords as names (the gate now names the file instead).
- Replacing gdradon.
- Plan 029's `_`-prefix wording (already corrected in the plan).
