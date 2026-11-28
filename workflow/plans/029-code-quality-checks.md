# Code quality checks that keep up with project size
Issue: #29
Status: merged (85764b8, 2026-11-27), the recommended level of three (more and less intense options are at the end)

Add cheap, deterministic quality checks to every feature, plus a report-only audit at each roadmap phase gate. The per-feature Codex review (`workflow/REVIEW.md`) is unchanged: it keeps its "Do not flag style" bar. The goal is that the per-feature quality cost stays flat as `src/` grows (deterministic checks only, no extra agent pass), and the audit's input stays bounded.

#28 is merged (`89c3d61`), so this builds on its `check.ps1`. This plan is code quality only: typecheck speed-ups belong to #28 (see "Not in this plan").

Facts this plan relies on (checked 2026-11-27 unless noted):
- `check.ps1` runs gdformat, gdlint, an import, a typecheck that starts one Godot process per script, then GUT in two runs (fixed-fps and the `$realTimeTests` list).
- Only `gdscript/warnings/untyped_declaration=2` (Error) is set (`project.godot:24`). Other warnings never fail `--check-only`.
- gdlint already enables every rule (`gdlintrc`; `null` means on with defaults).
- With the four warnings below set to Error in a scratch copy, all 59 scripts still typecheck, and GUT shows no parse errors (the only failures are the 4 known wall-clock tests under fixed fps; they pass in real time). Addon scripts aren't affected. A planted case of each warning fails `--check-only` with `(Warning treated as error.)`.
- gdradon (gdtoolkit 4.5.0, in the venv) has no options besides `--help` and `--version`: no threshold. It exits 0 even when a function is graded C, and when it can't parse a file (it prints the parser error and skips the file). Output is a file path line, then one indented line per function or class: `F 33:0 _input - B (6)`. Its line numbers are wrong (it reports `Rifle._input` at 33; the real line is 59). It takes about 0.5 s over `src/`.
- gdradon grades today: every function in `src/` is A, except `Rifle._input` B(6) and `Rifle._fire` B(7). Grades: A 1-5, B 6-10, C 11-20, D 21-30, E 31-40, F 41+.
- gdformat runs before gdradon and uses the same gdtoolkit parser, so a file gdradon can't parse already fails the format step. Wrong in one case, found in review r1: a valid script with a local named after a Python keyword (for example `from`) passes format, but gdradon's conversion to Python fails, so it skips the file and exits 0. Fixed by #31.
- `src/` is about 1,030 lines in 18 scripts. `src/player/techs/` is empty; phase 3 (movement techs) adds one file per tech.
- An audit on 2026-11-27 found no bugs, but patterns worth one decision: the `_last_* = NAN` config-sync cache (`rifle.gd:110`, `dummy.gd:87`), per-frame work while idle (`debug_overlay.gd:99`, `dummy.gd:101-104`), a duplicated eviction loop (`hit_markers.gd:58`, `:72`), the "parent must be a SUCC" guard written three times, and a stale comment (`speed_utils.gd:3`).
- `improve-codebase-architecture` is a user-level skill (`~/.claude/skills/`, not in the repo) that only the owner can start. It writes an HTML report to `%TEMP%`, asks which candidate to explore, then grills. It looks for shallow modules, not code smells. It isn't part of the audit; the owner may run it after an audit (see change 3).
- The smell list comes from Matt Pocock's `code-review` skill (`github.com/mattpocock/skills`, `skills/engineering/code-review/SKILL.md`, commit `bbadaa6`, MIT): Fowler's code smells from *Refactoring*, chapter 3. Change 3 restates them in our own words with credit, not as a verbatim copy.

## Behaviour

What the developer and the agents see.

1. A script under `src/` or `tests/` with an unused local variable, an unused private member variable, code after a `return`, or a local variable that shadows a member variable fails check.ps1 at the typecheck step. Godot's message names the problem and ends with `(Warning treated as error.)`. The fix for an unused local or member is to delete it. A `_` prefix is only for unused parameters and loop variables (gdlint's `unused-argument` rule accepts `_value`). It doesn't work on locals, because gdlint's `function-variable-name` rule rejects a leading `_`, and it never silences an unused private member (`_x` is already private and still warns). Corrected 2026-11-27 after review r1.
2. A function or class in `src/` with complexity 11 or more (grade C to F) fails check.ps1 at a new complexity step. The step prints the file, the function name, the grade and the score, for example `src/weapons/rifle.gd: _fire C (12)`, but no line number (gdradon's are wrong). Grades A and B print nothing. `tests/` isn't graded.
3. Each roadmap phase gate runs the quality audit. The roadmap says so under its phase table.
4. The quality audit is report-only and runs at each phase gate, in any fresh chat, from the "How to run an audit" section of `workflow/docs/quality-log.md`. It appends one dated section with the commit hash it audited. Each finding is one line with an id, `file:line`, the smell or check, the problem, a suggested fix, and `Status: open`. The owner changes each status to `plan #N` (it becomes an issue through /ideas) or `accepted`. The next audit doesn't report an accepted finding again unless the code around it changed, and it covers only `src/` files changed since the last section's commit. The first audit covers all of `src/` and runs at the end of phase 2, before phase 3 tech files start.
5. When an audit finds the same pattern in 3 or more places, the owner decides it once (keep, replace, or make a helper) and one line goes into AGENTS.md. First candidate: how a node reads a live config resource each tick without warning every tick (the config-sync cache). This happens after the first audit, not in this build.

## Changes

### 1. Stricter Godot warnings
In `project.godot` `[debug]`, set to Error (2), next to `untyped_declaration`:
- `gdscript/warnings/unused_variable`
- `gdscript/warnings/unused_private_class_variable`
- `gdscript/warnings/unreachable_code`
- `gdscript/warnings/shadowed_variable`

No code fixes are expected (see Facts). If the real repo trips one anyway, fix it in this change; `src/` and `tests/` edits are limited to that.

### 2. Complexity gate (gdradon)
New check.ps1 step after lint: `Complexity (gdradon, src/)`. Run `gdradon cc src` and capture its output; fail if its exit code isn't 0. Read the output line by line: a line that doesn't start with whitespace is the current file; an indented line matching `<kind> <line>:<col> <name> - <grade> (<score>)` is a function or class. Collect every grade C, D, E or F, print each as `<file>: <name> <grade> (<score>)`, then fail the step. Print nothing for A and B.

### 3. Phase-gate audit (report-only)
New `workflow/docs/quality-log.md` with a header, a "How to run an audit" section, the smell list and the project checks below, and no audit sections yet. One sentence goes under the roadmap's phase table: every phase gate also runs the quality audit in `workflow/docs/quality-log.md` (report-only; it blocks nothing).

"How to run an audit" says, in this order:
1. Scope: `src/` files changed since the commit named in the newest audit section (`git diff --name-only <hash> HEAD -- src`). If there is no section yet, all of `src/`.
2. Read AGENTS.md and every earlier finding marked `accepted`.
3. Check each file in scope against the smells and project checks. Each is a judgement call. A rule in AGENTS.md or a decision in a plan wins over a smell. Skip what check.ps1 already enforces (format, lint, types, warnings, complexity).
4. Append `## YYYY-MM-DD, phase N gate, commit <short hash>`, a scope line, then one line per finding: `Q<n>. file:line. <smell or check>. <problem>. Fix: <suggested fix>. Status: open`. Number findings on from the last `Q` id in the file.
5. List any pattern seen in 3 or more places under a `Patterns` line in the section (Behaviour 5).
6. Change no other file. Stop and hand the section to the owner.
7. Optional, owner only: run `/improve-codebase-architecture` afterwards for deepening ideas. If the owner wants any of its candidates kept, the chat adds them to the same section as findings (`<smell or check>` = `Architecture`).

Smell list (credit line: "Fowler's code smells (*Refactoring*, ch. 3), as listed in Matt Pocock's `code-review` skill, github.com/mattpocock/skills, commit bbadaa6, MIT. Restated for GDScript."). Each is one line, what it is → fix, written in our words:
1. **Mysterious Name**: a name that doesn't say what the thing does or holds → rename it.
2. **Duplicated Code**: the same logic in two or more places → one function that both call.
3. **Feature Envy**: a function that uses another object's data more than its own → move it to that object.
4. **Data Clumps**: the same few values always passed or stored together → one type (a Resource or inner class).
5. **Primitive Obsession**: a plain int, float or String standing in for a game concept → a small type or an enum.
6. **Repeated Switches**: the same `match` or if-chain on the same value in several places → one shared table, or one method per type.
7. **Shotgun Surgery**: one change needs edits in many files → gather what changes together into one script.
8. **Divergent Change**: one script changes for several unrelated reasons → split it.
9. **Speculative Generality**: hooks, parameters or abstractions that no plan needs → delete them.
10. **Message Chains**: long `a.b.c.d` walks through other nodes → one method on the first object.
11. **Middle Man**: a script that mostly forwards calls → call the target directly.
12. **Refused Bequest**: a script that `extends` a class but ignores or overrides most of it → use composition.

Project checks (from the 2026-11-27 audit):
- Work done every frame or tick while nothing it depends on changed.
- A comment that no longer matches the code.
- Code that breaks a pattern line in AGENTS.md.

### 4. Write repeated patterns into AGENTS.md
Behaviour 5. Not part of this build: it follows the first audit.

## Files to touch
- `project.godot`: four warning settings (change 1).
- `workflow/tools/check.ps1`: complexity step (change 2).
- `workflow/docs/roadmap.md`: one sentence under the phase table (change 3).
- `workflow/docs/quality-log.md`: new; header, how to run, smell list, project checks (change 3).
- `src/`, `tests/`: only fixes needed to pass change 1, if any.
- `AGENTS.md`: not in this build (change 4 follows the first audit).

## Sliders
None. No gameplay value changes. The complexity limit (grade C) and the four warnings are check settings, not feel values.

## How to test
No test file changes. Every planted file below is temporary: remove it, never commit it, and rerun check.ps1 to show it green again. Show each failing output.

1. **Baseline.** On the feature branch with all changes in, `check.ps1` passes. The complexity step prints nothing (Rifle's two B grades stay silent).
2. **Warnings.** Plant one untracked file per warning in `src/` (`planted_unused_var.gd`, `planted_unused_member.gd`, `planted_unreachable.gd`, `planted_shadowed.gd`), each a minimal `extends Node` script with only that problem. For each, `check.ps1` fails at the typecheck step and lists that file; the one-file command `& $godot --headless --path . --check-only --script res://src/<file>` shows Godot's message with `(Warning treated as error.)`. A fifth file, `planted_unused_param.gd`, holds one function with an unused parameter named `_value`; it passes check.ps1. (The same parameter named `value` fails lint with `unused-argument`.)
3. **Complexity C fails.** Plant `src/planted_complex.gd` with one function holding 11 `if` statements (score 12). `check.ps1` fails at the complexity step and prints `src/planted_complex.gd: <name> C (12)` (or the path form gdradon prints). With 5 `if` statements instead (B), the step prints nothing and passes.
4. **Docs.** `workflow/docs/quality-log.md` has the how-to, 12 smells with the credit line and 3 project checks, and no audit section. The roadmap sentence reads as Behaviour 3 says.

No screenshot: nothing visual changes.

## Not in this plan
- No quality rule in `workflow/REVIEW.md` and no per-feature cleanup pass (`/simplify`, `deslop`, code-simplifier). These were the "more intense" option.
- No duplicate-code detector: no tool found that is known to work on GDScript.
- No complexity grading of `tests/`.
- Running the first audit, and change 4's AGENTS.md line: both happen at the phase 2 gate, after this merges.
- Typecheck speed-ups. They are workflow speed, not code quality: one Godot process for the whole typecheck is #30; skipping a repeat check on an already-green commit is in plan 028 change 4 (#28).

## Cost and noise
- Setup: about 1-1.5 hours. Per feature: about 0.5 s more for gdradon; the four warnings add no time (the typecheck already runs). Per phase gate: one agent session for the audit.
- Noise: low. Changes 1 and 2 don't guess. Audit findings never block.

## Other levels considered
- **More intense:** also most Godot warnings as errors (not `unsafe_*`), gdlint `max-file-lines` 400, fail on gdradon B, a cleanup pass after tests in every /implement, a REVIEW.md quality rule (duplicate helpers, per-frame work that could run only on change), a report-only headless frame-time test, and `correct` after any finding repeats. Rejected for now: higher per-feature token cost, churn, and it conflicts with REVIEW.md's no-style bar and #28's goal.
- **Less intense:** change 1 only, with manual audits when something feels off. Move up to this plan when `src/` passes ~3,000 lines, the same finding appears twice, or phase 3 adds more than 5 tech files.

## Open questions
- None. Decided 2026-11-27: gdradon grade B prints nothing; the audit uses its own checklist (Pocock's 12 smells restated, plus 3 project checks), not improve-codebase-architecture; the first audit covers all of `src/`. Later the same day, the typecheck speed-ups (changed-scripts typecheck and the green-commit skip) moved out of this plan to #28's scope, and the remaining changes were renumbered 1-4.
