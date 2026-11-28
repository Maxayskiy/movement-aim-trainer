# Code quality checks that keep up with project size
Issue: #29
Status: approved (2026-11-27), the recommended level of three (more and less intense options are at the end)

Add cheap, deterministic quality checks to every feature, plus a report-only audit at each roadmap phase gate. The per-feature Codex review (`workflow/REVIEW.md`) is unchanged: it keeps its "Do not flag style" bar. The goal is that the per-feature cost stays flat as `src/` grows, and the audit's input stays bounded.

#28 is merged (`89c3d61`), so this builds on its `check.ps1` and /implement skill.

Facts this plan relies on (checked 2026-11-27 unless noted):
- `check.ps1` runs gdformat, gdlint, an import, a typecheck that starts one Godot process per script, then GUT in two runs (fixed-fps and the `$realTimeTests` list).
- Only `gdscript/warnings/untyped_declaration=2` (Error) is set (`project.godot:24`). Other warnings never fail `--check-only`.
- gdlint already enables every rule (`gdlintrc`; `null` means on with defaults).
- With the four warnings below set to Error in a scratch copy, all 59 scripts still typecheck, and GUT shows no parse errors (the only failures are the 4 known wall-clock tests under fixed fps; they pass in real time). Addon scripts aren't affected. A planted case of each warning fails `--check-only` with `(Warning treated as error.)`.
- gdradon (gdtoolkit 4.5.0, in the venv) has no options besides `--help` and `--version`: no threshold. It exits 0 even when a function is graded C, and when it can't parse a file (it prints the parser error and skips the file). Output is a file path line, then one indented line per function or class: `F 33:0 _input - B (6)`. Its line numbers are wrong (it reports `Rifle._input` at 33; the real line is 59). It takes about 0.5 s over `src/`.
- gdradon grades today: every function in `src/` is A, except `Rifle._input` B(6) and `Rifle._fire` B(7). Grades: A 1-5, B 6-10, C 11-20, D 21-30, E 31-40, F 41+.
- gdformat runs before gdradon and uses the same gdtoolkit parser, so a file gdradon can't parse already fails the format step.
- The full typecheck took 26 s for 59 scripts. Scripts reference each other by `class_name` (18 in `src/`) or by `res://` path in `preload`/`load`. Renaming a static function in `speed_utils.gd` makes the unchanged `debug_overlay.gd` fail `--check-only` (`Static function "to_ups()" not found in base "SpeedUtils"`). A shell prototype of the change 3 dependents rule gave, out of 59: `hit_marker_fade.gd` 7 scripts, `speed_utils.gd` 14, `fire_timer.gd` 18 (it reaches `rifle.gd`, which many scripts name).
- `src/` is about 1,030 lines in 18 scripts. `src/player/techs/` is empty; phase 3 (movement techs) adds one file per tech.
- An audit on 2026-11-27 found no bugs, but patterns worth one decision: the `_last_* = NAN` config-sync cache (`rifle.gd:110`, `dummy.gd:87`), per-frame work while idle (`debug_overlay.gd:99`, `dummy.gd:101-104`), a duplicated eviction loop (`hit_markers.gd:58`, `:72`), the "parent must be a SUCC" guard written three times, and a stale comment (`speed_utils.gd:3`).
- `improve-codebase-architecture` is a user-level skill (`~/.claude/skills/`, not in the repo) that only the owner can start. It writes an HTML report to `%TEMP%`, asks which candidate to explore, then grills. It looks for shallow modules, not code smells. It isn't part of the audit; the owner may run it after an audit (see change 4).
- The smell list comes from Matt Pocock's `code-review` skill (`github.com/mattpocock/skills`, `skills/engineering/code-review/SKILL.md`, commit `bbadaa6`, MIT): Fowler's code smells from *Refactoring*, chapter 3. Change 4 restates them in our own words with credit, not as a verbatim copy.

## Behaviour

What the developer and the agents see.

1. A script under `src/` or `tests/` with an unused local variable, an unused private member variable, code after a `return`, or a local variable that shadows a member variable fails check.ps1 at the typecheck step. Godot's message names the problem and ends with `(Warning treated as error.)`. Prefixing an unused name with `_` silences it (Godot's own rule).
2. A function or class in `src/` with complexity 11 or more (grade C to F) fails check.ps1 at a new complexity step. The step prints the file, the function name, the grade and the score, for example `src/weapons/rifle.gd: _fire C (12)`, but no line number (gdradon's are wrong). Grades A and B print nothing. `tests/` isn't graded.
3. check.ps1 without flags typechecks only:
   - `.gd` files under `src/` and `tests/` that differ from where the branch left main (`git merge-base main HEAD`): committed, staged, unstaged, and untracked files; deleted files are skipped;
   - plus every script under `src/` and `tests/` whose text names one of those files' `class_name` (whole word) or `res://` path, repeated until no new script is added.
   The step title shows the count, for example `Typecheck (4 of 59 scripts: changed + dependents)`. If no script qualifies, the step prints that and passes.
4. check.ps1 typechecks every script when `-Full` is passed, when `project.godot` or anything under `addons/` differs from the merge base, or when git can't find `main` (it prints which reason). GUT still runs every test in every mode.
5. /implement's Merge step runs `check.ps1 -Full` on main after merging. Each roadmap phase gate runs `check.ps1 -Full` and the quality audit.
6. The quality audit is report-only and runs at each phase gate, in any fresh chat, from the "How to run an audit" section of `workflow/docs/quality-log.md`. It appends one dated section with the commit hash it audited. Each finding is one line with an id, `file:line`, the smell or check, the problem, a suggested fix, and `Status: open`. The owner changes each status to `plan #N` (it becomes an issue through /ideas) or `accepted`. The next audit doesn't report an accepted finding again unless the code around it changed, and it covers only `src/` files changed since the last section's commit. The first audit covers all of `src/` and runs at the end of phase 2, before phase 3 tech files start.
7. When an audit finds the same pattern in 3 or more places, the owner decides it once (keep, replace, or make a helper) and one line goes into AGENTS.md. First candidate: how a node reads a live config resource each tick without warning every tick (the config-sync cache). This happens after the first audit, not in this build.
8. When check.ps1 passes with nothing uncommitted in tracked files and no untracked files under `src/` or `tests/`, it writes the current commit hash and the mode (`default` or `full`) to `.godot/last-green` and prints `Recorded green: <short hash>`. If anything is uncommitted, or any step fails, it doesn't write the file and leaves any old one as it is. `check.ps1 -IfChanged` exits 0 at once, printing `Already green at <short hash>, skipped`, when `.godot/last-green` names the current commit and the tree is clean as above. Otherwise it runs normally. A `default` record satisfies a default run; only a `full` record satisfies `-Full -IfChanged`.

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

### 3. Typecheck only changed scripts and their dependents
Add a `-Full` switch to check.ps1 (a `param([switch]$Full)` block at the top). The typecheck step builds its list as Behaviour 3 and 4 say:
- Base: `git merge-base main HEAD`. If that fails, typecheck everything.
- Changed: `git diff --name-only <base> -- src tests` (working tree against the base, so committed, staged and unstaged changes all count), plus `git ls-files --others --exclude-standard -- src tests`. Keep `.gd` files that still exist.
- Full instead: `-Full`, or `git diff --name-only <base> -- project.godot addons` is not empty.
- Dependents: for each script in the list, its `class_name` (from a `^class_name\s+(\w+)` line) and its `res://` path. Add every other `.gd` file under `src/` and `tests/` whose text contains that name as a whole word, or that path. Repeat with the newly added files until nothing new is added. Matching is plain text, so a name in a comment also counts; that only adds scripts, never drops one.
- Typecheck the list exactly as today (one Godot process per script) and keep today's error report.

Other steps don't change: format, lint, complexity and GUT still cover every file.

Edit `.claude/skills/implement/SKILL.md` "Merge": "Run check.ps1 on main" becomes "Run check.ps1 -Full on main". Nothing else in the skill changes; build steps and fix rounds use the default mode.

### 4. Phase-gate audit (report-only)
New `workflow/docs/quality-log.md` with a header, a "How to run an audit" section, the smell list and the project checks below, and no audit sections yet. One sentence goes under the roadmap's phase table: every phase gate also runs `check.ps1 -Full` and the quality audit in `workflow/docs/quality-log.md` (report-only; it blocks nothing).

"How to run an audit" says, in this order:
1. Scope: `src/` files changed since the commit named in the newest audit section (`git diff --name-only <hash> HEAD -- src`). If there is no section yet, all of `src/`.
2. Read AGENTS.md and every earlier finding marked `accepted`.
3. Check each file in scope against the smells and project checks. Each is a judgement call. A rule in AGENTS.md or a decision in a plan wins over a smell. Skip what check.ps1 already enforces (format, lint, types, warnings, complexity).
4. Append `## YYYY-MM-DD, phase N gate, commit <short hash>`, a scope line, then one line per finding: `Q<n>. file:line. <smell or check>. <problem>. Fix: <suggested fix>. Status: open`. Number findings on from the last `Q` id in the file.
5. List any pattern seen in 3 or more places under a `Patterns` line in the section (Behaviour 7).
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

### 5. Write repeated patterns into AGENTS.md
Behaviour 7. Not part of this build: it follows the first audit.

### 6. Skip a repeat check on an already-green commit
Added 2026-11-27. Reason: in the planned flow (build, commit, proof, playtest, "review"), plan 028 change 4's `review.ps1` runs check.ps1 again on the commit Implement just checked. That costs about 45 s per review round and finds nothing new. The check only matters if something was committed after the last green run, for example slider values tuned during the playtest.
- check.ps1 writes `.godot/last-green` as Behaviour 8 says. `.godot/` is already in `.gitignore`, and each worktree has its own `.godot/`, so records never mix between branches. Write it only at the very end, after every step passed. "Clean" means `git status --porcelain --untracked-files=no` is empty and `git ls-files --others --exclude-standard -- src tests` is empty.
- Add a `-IfChanged` switch (Behaviour 8). It's the only way the skip happens; a plain `check.ps1` always runs everything.
- `review.ps1` doesn't exist yet (plan 028 change 4, still to be built). Add one line to 028 change 4: `review.ps1` calls `check.ps1 -IfChanged` instead of `check.ps1`, and passes the hash it reports to Codex as the commit check.ps1 passed at.
- /implement doesn't change: its "don't rerun unless code changed" rule stays a judgement call. It may use `-IfChanged`, but nothing requires it.

## Files to touch
- `project.godot`: four warning settings (change 1).
- `workflow/tools/check.ps1`: `-Full` switch, changed-and-dependents typecheck list, complexity step (changes 2 and 3); `-IfChanged` switch and the `.godot/last-green` record (change 6).
- `workflow/plans/028-agent-efficiency.md`: one line in change 4, `review.ps1` uses `check.ps1 -IfChanged` (change 6).
- `.claude/skills/implement/SKILL.md`: Merge step uses `check.ps1 -Full` (change 3).
- `workflow/docs/roadmap.md`: one sentence under the phase table (change 4).
- `workflow/docs/quality-log.md`: new; header, how to run, smell list, project checks (change 4).
- `src/`, `tests/`: only fixes needed to pass change 1, if any.
- `AGENTS.md`: not in this build (change 5 follows the first audit).

## Sliders
None. No gameplay value changes. The complexity limit (grade C) and the four warnings are check settings, not feel values.

## How to test
No test file changes. Every planted file or edit below is temporary: remove it, never commit it, and rerun check.ps1 to show it green again. Show each failing output.

1. **Baseline.** On the feature branch with all changes in, `check.ps1 -Full` passes and its typecheck title shows all scripts (59 today, plus any new ones). The complexity step prints nothing (Rifle's two B grades stay silent).
2. **Warnings.** Plant one untracked file per warning in `src/` (`planted_unused_var.gd`, `planted_unused_member.gd`, `planted_unreachable.gd`, `planted_shadowed.gd`), each a minimal `extends Node` script with only that problem. For each, `check.ps1` (default mode) fails at the typecheck step and lists that file; the one-file command `& $godot --headless --path . --check-only --script res://src/<file>` shows Godot's message with `(Warning treated as error.)`. A fifth file with the same shapes but `_`-prefixed unused names passes.
3. **Complexity C fails.** Plant `src/planted_complex.gd` with one function holding 11 `if` statements (score 12). `check.ps1` fails at the complexity step and prints `src/planted_complex.gd: <name> C (12)` (or the path form gdradon prints). With 5 `if` statements instead (B), the step prints nothing and passes.
4. **Untracked file is typechecked.** Step 2 already shows it: the planted files are untracked, and default mode lists them.
5. **Unchanged dependent is typechecked.** Rename `to_ups` in `src/debug/speed_utils.gd` (tracked edit, nothing else changed). Default mode's title counts `speed_utils.gd` plus its dependents (at least `debug_overlay.gd` and `tests/unit/test_speed_utils.gd`), and the step fails listing the unchanged `debug_overlay.gd`.
6. **Only changed scripts otherwise.** With only a comment edit in `src/ui/hit_marker_fade.gd`, the title shows 7 of 59 scripts (today's count; more if new scripts name it).
7. **Full triggers.** A whitespace-only edit to `project.godot` makes default mode typecheck all scripts and print the reason. `check.ps1 -Full` with a clean tree typechecks all scripts.
8. **Nothing changed.** On main with a clean tree (after the merge), default mode prints that no scripts changed and passes; `-Full` checks all.
9. **Docs.** `workflow/docs/quality-log.md` has the how-to, 12 smells with the credit line and 3 project checks, and no audit section. The roadmap sentence and the /implement Merge line read as Behaviour 5 says.
10. **Green record and skip.** After a passing default run on a clean tree, `.godot/last-green` holds the current hash and `default`, and the run printed `Recorded green`. `check.ps1 -IfChanged` then prints `Already green at <hash>, skipped` and exits 0 in about a second; `check.ps1 -Full -IfChanged` runs fully. Plant an untracked `src/planted_x.gd`: `-IfChanged` runs fully, and the record isn't rewritten. Make a commit (any tracked change): `-IfChanged` runs fully. Make one step fail (step 3's planted file): the old record stays unchanged.

No screenshot: nothing visual changes.

## Not in this plan
- No quality rule in `workflow/REVIEW.md` and no per-feature cleanup pass (`/simplify`, `deslop`, code-simplifier). These were the "more intense" option.
- No duplicate-code detector: no tool found that is known to work on GDScript.
- No complexity grading of `tests/`.
- Running the first audit, and change 5's AGENTS.md line: both happen at the phase 2 gate, after this merges.
- Plan 028 change 8 (one Godot process for the whole typecheck).

## Cost and noise
- Setup: about 2-3 hours. Per feature: about 0.5 s more for gdradon; the typecheck drops from about 26 s to roughly 3-10 s for a typical feature (7-18 of 59 scripts in the prototype). A change to a widely named script (Rifle, the player) still pulls in many. Per phase gate: one `-Full` run and one agent session.
- Noise: low. Changes 1-3 don't guess. Audit findings never block.
- Risk: the dependents rule misses a script that uses another without naming its `class_name` or path (for example through a `.tscn` only). GUT still loads it at test time, and `-Full` on main after every merge catches the rest.

## Other levels considered
- **More intense:** also most Godot warnings as errors (not `unsafe_*`), gdlint `max-file-lines` 400, fail on gdradon B, a cleanup pass after tests in every /implement, a REVIEW.md quality rule (duplicate helpers, per-frame work that could run only on change), a report-only headless frame-time test, and `correct` after any finding repeats. Rejected for now: higher per-feature token cost, churn, and it conflicts with REVIEW.md's no-style bar and #28's goal.
- **Less intense:** change 1 only, with manual audits when something feels off. Move up to this plan when `src/` passes ~3,000 lines, the full typecheck takes over 60 s, the same finding appears twice, or phase 3 adds more than 5 tech files.

## Open questions
- None. Decided 2026-11-27: gdradon grade B prints nothing; change 3 kept in its full form; the audit uses its own checklist (Pocock's 12 smells restated, plus 3 project checks), not improve-codebase-architecture; the first audit covers all of `src/`; change 6 added after approval, at the owner's request, so review.ps1 doesn't repeat a green check.
