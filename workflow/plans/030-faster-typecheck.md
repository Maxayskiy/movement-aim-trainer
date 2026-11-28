# Agent workflow efficiency, stage 2: faster typecheck
Issue: #30
Status: approved (2026-11-27)

check.ps1's typecheck starts one Godot process per script. Replace that with one Godot process that compiles every script and lists the ones that fail. Same scripts, same errors, same pass/fail rule; about 2 s instead of 19-26 s. This is plan 028 change 8 ("Faster typecheck"), now built on its own.

Facts this plan relies on (checked 2026-11-27 with Godot 4.7.2, in a scratch copy of the repo):
- Today's step (`workflow/tools/check.ps1:56-65`) runs `godot --headless --path <root> --check-only --script <res path> --quiet` once per `.gd` file under `src/` and `tests/` (59 today), collects the paths that exit non-zero, prints `Errors in:` with one path per line, and fails. Measured at 19 s (plan 028) and 26 s (plan 029). The import step (`check.ps1:53-54`) runs right before it, so the `class_name` cache is fresh.
- A probe script (`extends SceneTree`, run with `-s`) that calls `ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)` on each script and counts it as failed when the result isn't a `GDScript` or `can_instantiate()` is false:
  - checked all 59 scripts in about 0.7-2.0 s of load time, 2.4 s wall time for the whole process, exit 0;
  - with planted files, it failed exactly these and nothing else: a parse error (`Expected parameter name`), an untyped `var x = 5` (`has no static type. (Warning treated as error.)`), and, after renaming `SpeedUtils.to_ups` in `src/debug/speed_utils.gd`, the unchanged `src/debug/debug_overlay.gd` and `tests/unit/test_speed_utils.gd` (`Static function "to_ups()" not found in base "SpeedUtils"`);
  - with `gdscript/warnings/unused_variable=2` added to `project.godot`, an unused local failed both the probe and `--check-only` with the same message. So warnings set to Error (plan 029 change 1) apply the same way.
- Godot prints each compile error to stderr with the script path and line (`at: GDScript::reload (res://src/debug/debug_overlay.gd:98)`), the same text `--check-only` prints.
- Loading a script runs its `_static_init()`. A planted `src/debug/aa_planted_kill.gd` whose `_static_init()` calls `OS.kill(OS.get_process_id())` stopped the probe part-way: no summary line, and the shell saw exit code 0. So the exit code alone can't be trusted; the summary line must be checked.
- `-s` accepts an absolute path to a script outside the project (the probe ran from the scratchpad and still loaded `res://` scripts). `workflow/` has a `.gdignore`, so Godot never imports or lists a script kept there.

## Behaviour

What the developer and the agents see.

1. check.ps1's typecheck step starts one Godot process for all scripts under `src/` and `tests/`, not one per script. Its title keeps the count: `Typecheck (59 scripts, one Godot process)`. On a clean tree the step takes about 2-3 s (today 19-26 s).
2. A script that fails to compile (parse error, missing type, a warning set to Error, or a broken reference to another script) fails the step. The step prints `Errors in:` and one `res://` path per failing script, as today, and Godot's own error lines (file, line, message) stay visible above it.
3. A script that didn't change still fails when a script it uses changed under it (for example a renamed static function). Every run checks every script; there are no flags and no partial modes.
4. If the Godot process stops before it reports on every script, the step fails with `Typecheck stopped early: checked <n> of <total>` (or `no summary` when it printed none), even if Godot's exit code was 0.

## Files to touch
- `workflow/tools/typecheck_all.gd`: new. `extends SceneTree`, static types. Reads the list file whose path comes after `--` on the command line (`OS.get_cmdline_user_args()`), one `res://` path per line. Loads each with `ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)`; a result that isn't a `GDScript`, or whose `can_instantiate()` is false, counts as failed. Prints `TYPECHECK BAD <path>` per failed script, then `TYPECHECK DONE checked=<n> bad=<m>`, and quits with 1 if any failed, else 0.
- `workflow/tools/check.ps1`: step 4 writes `$gdFiles` as `res://` paths to `.godot/typecheck-list.txt` (`.godot/` is gitignored and per worktree), runs `& $godot --headless --path $root -s <absolute path of typecheck_all.gd> -- <list path>` once, keeps Godot's output visible, and collects the `TYPECHECK BAD` paths. It fails the step when the exit code isn't 0, or when the `TYPECHECK DONE` line is missing or its `checked` count isn't `$gdFiles.Count` (Behaviour 4; the process died part-way, which can still exit 0). The `Errors in:` report stays as today. Update the step's comment.
No change to plan 028 (its change 8 already points here), `.claude/skills/implement/SKILL.md`, the other check.ps1 steps, or any game code.

## Sliders
None. No gameplay value changes.

## How to test
No test file changes. Every planted file or edit below is temporary: undo it, never commit it, and rerun check.ps1 to show it green again. Show each failing output.

1. **Baseline and time.** On the feature branch, check.ps1 passes. The typecheck title reads `Typecheck (59 scripts, one Godot process)` (or today's count) and the step takes under 5 s. Show the time of the step before (on main) and after.
2. **Same failures as before.** Plant `src/planted_untyped.gd` (`extends Node`, one function with `var x = 5`) and `src/planted_parse.gd` (a function header missing its `)`). check.ps1 fails at the typecheck step, lists both under `Errors in:`, and Godot's lines show `(Warning treated as error.)` and the parse error with file and line.
3. **Unchanged dependent.** Rename `to_ups` in `src/debug/speed_utils.gd` (nothing else changed). The step fails and lists the unchanged `src/debug/debug_overlay.gd` and `tests/unit/test_speed_utils.gd`.
4. **Agrees with --check-only.** For each failing path in steps 2 and 3, the old one-file command `& $godot --headless --path . --check-only --script <res path>` also fails; for two scripts the step passed (any two), it passes.
5. **Process stops early.** Plant `src/debug/aa_planted_kill.gd`: `extends Node` with `static func _static_init() -> void:` calling `OS.kill(OS.get_process_id())`. check.ps1 fails at the typecheck step with `Typecheck stopped early` (Behaviour 4), although Godot's exit code may be 0.

No screenshot: nothing visual changes.

## Not in this plan
- Typechecking only changed scripts plus their dependents, with a `-Full` switch for merges and phase gates (old plan 029 change 3; full text in `git show 35e361d:workflow/plans/029-code-quality-checks.md`). Dropped 2026-11-27: with one process the whole typecheck takes about 2 s, so the filter would save only about 1-2 s more, and it adds git logic, a switch and a risk of missing a dependent that is used only through a scene.
- Skipping a repeat check on an already-green commit (old plan 029 change 6). Now in plan 028 change 4, built with review.ps1.
- Faster GUT runs or any other check.ps1 step.

## Cost and noise
- Setup: about 1 hour. Saves about 17-24 s on every check.ps1 run, and the saving grows with the script count.
- Noise: none expected; the pass/fail rule doesn't change.
- Risk: one compile error could leave the process in a bad state and hide a later script's error. The probe saw no sign of it (all four planted failures reported in one run). A process that stops early is caught by the count check (Behaviour 4).

## Open questions
- None. Decided 2026-11-27: plan 028 change 8 joins this feature; after the probe, the changed-scripts filter (old 029 change 3) is dropped and only the one-process typecheck is built.
