# check.ps1 fails at random in gdformat or gdlint (gdtoolkit crash)
Issue: #32
Status: approved (2026-11-27)

Bug. check.ps1 sometimes fails at the format or lint step on code that is valid and already formatted. The same tree passes on the next run. It fails closed (never a false pass), but it costs reruns and makes agents chase errors that aren't there.

Facts (seen 2026-11-27, gdtoolkit 4.5.0, lark 1.2.2, Python 3.14.4 in `.venv`):
- A lark parser crash in gdlint during the #29 build.
- `gdformat --check src tests` failed 1 of 15 runs on a clean tree with an `AssertionError`.
- One `RecursionError` in `gdtoolkit/formatter/expression_utils.py` (`is_expression_forcing_multiple_lines`).
- One stop at the lint step with no output kept.
- `gdlint src tests` passed 15 of 15 on a clean tree.
- No traceback from these runs was saved. The failing file is unknown.

How it works today:
- `workflow/tools/requirements.txt` pins `gdtoolkit==4.5.0` (the newest on PyPI; older: 4.3.4, 4.3.3, ...). No pin for lark or Python.
- `workflow/tools/check.ps1:39-43`: `gdformat --check src tests`; any non-zero exit fails the `format` step. `:46-50`: `gdlint src tests`; any non-zero exit fails `lint`. Output goes straight to the console; nothing is kept.
- `:61`: gdradon (same gdtoolkit parser) runs on `src/` only and fails on any stderr text, so a crash there would also fail the run.
- `workflow/tools/format-hook.ps1` runs gdformat on each file Claude edits; a crash there blocks the edit with exit 2.
- A crash and a real finding both exit non-zero. Only the text differs: a crash prints `Traceback (most recent call last):`.

Suspects, not checked: Python hash randomisation (`PYTHONHASHSEED`) changing set order inside lark or gdtoolkit; Python 3.14 (newer than gdtoolkit 4.5.0 was released against; 3.12+ changed recursion limits); deep nesting in one of our files.

## Behaviour

What the developer and the agents see.

1. On a clean, formatted tree, check.ps1's format and lint steps pass every time: 0 failures in 50 runs of each.
2. A real format or lint problem still fails its step, with the same output as today.
3. If a gdtoolkit crash still happens, check.ps1 prints the full Python traceback, never a pass without the step having run cleanly. (Whether it then retries depends on the fix chosen in step 2 of How to test.)

## Files to touch

Step 1 changes no files in the repo. The repro script and logs are temporary: script in the session scratchpad, logs in `.godot/gdtoolkit-repro/` (gitignored). Don't commit them.

Step 3 touches only what the chosen fix needs, from this list:
- **A. Version pin.** `workflow/tools/requirements.txt`: a different gdtoolkit version, and/or a pin for `lark`. If the fix is a Python version, the README/setup line in check.ps1's `$reinstallHint` (`check.ps1:33`) names it (`py -3.13 -m venv .venv`).
- **B. Fixed hash seed.** check.ps1 (format, lint, complexity steps) and format-hook.ps1 set `$env:PYTHONHASHSEED` to one value that passed the repro before calling gdtoolkit. Only if step 1 shows the seed decides the crash.
- **C. Recursion limit.** gdtoolkit can't be edited in place (third-party, in `.venv`). A small wrapper `workflow/tools/gdtoolkit_run.py` that calls `sys.setrecursionlimit(<n>)` and then gdtoolkit's own entry point (`gdtoolkit.formatter.__main__:main` / `gdtoolkit.linter.__main__:main`); check.ps1 and format-hook.ps1 call it with the venv's python. Only if step 1 shows every crash is a `RecursionError`.
- **D. One retry.** check.ps1 format and lint steps: run once; if it fails and the output has `Traceback (most recent call last):`, print the whole output under `gdtoolkit crashed, retrying once:` and run the step again. The second result decides. A failure without a traceback (a real finding) is never retried. Last resort: it hides the cause.

Fixes can combine (for example A plus D). Keep check.ps1's comments accurate.

## Sliders
None. No gameplay value changes.

## How to test

No test file changes. Show each output.

1. **Reproduce first, before changing anything.** On a clean tree, run a loop (PowerShell script in the scratchpad) that keeps every failing run's full stdout and stderr:
   - 50 runs of `.venv\Scripts\gdformat.exe --check src tests` and 50 of `.venv\Scripts\gdlint.exe src tests`, each run's output in `.godot/gdtoolkit-repro/<tool>-<i>.txt` with its exit code and `PYTHONHASHSEED` value.
   - Each run sets `$env:PYTHONHASHSEED` to the run number (0-49), so a failing seed can be replayed.
   - Report: failures per tool, each distinct traceback in full (last frame and exception), the file being processed when it crashed (if the traceback or `-v`/per-file runs show it), and whether replaying a failing seed fails again every time (10 replays).
   - If 100 runs give no failure, run 200 more of gdformat with random seeds (unset `PYTHONHASHSEED`), then run check.ps1 itself 10 times. If still nothing fails, stop and report: the bug isn't reproducible today.
2. **Stop and propose.** Report the results from step 1 and recommend one fix (A-D, or a mix) with the evidence for it, plus what a probe showed for it: for A, the same 50+50 loop in a scratch venv with the candidate version (gdtoolkit 4.3.4, or Python 3.13); for B, the replayed seed failing and the chosen seed passing 50 times; for C, the failing case passing with the wrapper. Wait for the owner to pick. Don't change files before the pick.
3. **Fix**, then rerun the step 1 loop through the real path (check.ps1's commands, or the wrapper): 0 failures in 50 + 50 runs (Behaviour 1).
4. **Real findings still fail.** Plant `src/planted_bad.gd` with a line gdformat would change (for example `var x:int=1` in a function) and a gdlint violation (a function named `BadName`). check.ps1 fails at format with gdformat's message; fix the format and it fails at lint with gdlint's message. With fix D, show the step ran once (no retry line). Delete the file and show check.ps1 green (Behaviour 2).
5. **Crash path (fix D only).** Show Behaviour 3 by forcing a crash: for example run the step against a temporary copy of the gdformat command that raises (a scratch `.py` that prints a traceback and exits 1). Show the retry line with the full traceback. Don't commit the probe.
6. **Baseline.** check.ps1 passes on the clean tree, with timings for the format and lint steps before and after (they shouldn't get noticeably slower).

No screenshot: nothing visual changes.

## Out of scope
- Replacing gdtoolkit or gdradon.
- Patching gdtoolkit or lark in `.venv` or `addons/`. An upstream bug report to gdtoolkit (owner decides, after step 1).
- The typecheck and test steps.
- Making the repro loop a committed tool.
