# Review: 030-faster-typecheck (#30), round 1

- Plan: `workflow/plans/030-faster-typecheck.md`
- Reviewed commit: `104e664796e72b9d05b4931233df9cfb191d624c`
- Diff reviewed: `main...104e664796e72b9d05b4931233df9cfb191d624c`
- Reviewer: OpenAI Codex (GPT-6)
- check.ps1: passed in Implement at the reviewed commit, as reported by the owner. In Review I ran import, typecheck and both GUT groups with Godot 4.7.2.

## Findings

No findings.

The diff changes the typecheck step and adds its GDScript runner. I traced the file list from the recursive `src/` and `tests/` scan through the runner to the PowerShell failure checks. The diff preserves the import order, gameplay settings, tests and real-time test list.

| Clean run | Observed result |
| --- | --- |
| Main typecheck, same 59 scripts | 26.18 s, exit 0 |
| Branch typecheck | `Typecheck (59 scripts, one Godot process)`, 1.41 s, exit 0 |
| GUT at 128 fixed FPS | 196/196 tests passed across 34 scripts, 5,060 assertions |
| GUT in real time | 34/34 tests passed across 3 scripts, 168 assertions |

I timed the two typecheck steps in the same temporary project copy. I then ran the plan's planted cases against the branch step. Each failure exited 1.

- **Parse error and warning treated as an error.** Godot printed `Expected parameter name.` at `res://src/planted_parse.gd:3` and `Variable "x" has no static type. (Warning treated as error.)` at `res://src/planted_untyped.gd:4`. The step printed:

  ```text
  TYPECHECK DONE checked=61 bad=2
  Errors in:
    res://src/planted_parse.gd
    res://src/planted_untyped.gd
  ```

- **Unchanged callers.** Renaming only `SpeedUtils.to_ups` produced `Static function "to_ups()" not found in base "SpeedUtils".` in both callers, including lines 98 and 18 respectively. The step printed:

  ```text
  TYPECHECK DONE checked=59 bad=2
  Errors in:
    res://src/debug/debug_overlay.gd
    res://tests/unit/test_speed_utils.gd
  ```

- **Agreement with the old command.** Individual `--check-only` runs exited 1 for all four failing paths. On clean code they exited 0 for `src/debug/speed_utils.gd` and `tests/unit/test_speed_utils.gd`.
- **Early process exit.** Terminating Godot from the planted script's `_static_init()` produced `Typecheck stopped early: no summary` followed by `FAILED: typecheck`. With the temporary edits removed, the step returned to `TYPECHECK DONE checked=59 bad=0`, exit 0.

Godot logged a root certificate store error during startup and a resource cleanup diagnostic after the fixed-FPS run. Both GUT groups finished with `All tests passed!` and exited 0.

## Minor, not fixing

None.

## Verdict

ready to merge

## Filter result

| # | Verdict | Reason (one line) |
|---|---|---|
| — | — | The report lists no findings ("No findings."), so there is nothing to filter. |

Kept: 0 of 0.
