# Movement aim trainer

First-person movement aim trainer in Godot 4.7.2+ (typed GDScript). Source-style movement on top of the SUCC addon. Vision: workflow/docs/design.md. Build order: workflow/docs/roadmap.md.

## Check your work
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File workflow/tools/check.ps1` after every step. It must pass before you say you're done.
- Show proof: test output, plus a screenshot with debug overlays for anything visual.
- Never edit or delete a test to make it pass. If you think a test is wrong, stop and tell me.
- Godot is `$env:GODOT`, else `C:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`. Call it `& $godot` below.
- One test file: `& $godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/<dir>/<file>.gd -gexit`
- Run the game: `& $godot --path .`

## Rules
- Godot 4 APIs only. Never Godot 3 (KinematicBody, yield, deg2rad, move_and_slide(velocity)).
- Use static types everywhere.
- One movement tech per file in src/player/techs/. Keep player.gd small.
- Every gameplay value that affects feel must be an @export or a settings value, never a hard-coded number.
- Work only on what the issue's plan (`workflow/plans/NNN-slug.md`) lists. List anything else as a follow-up.
- Never edit files in addons/ (third-party code). To change one, copy it into src/ or levels/ first.
- Don't add addons or downloads without asking.

## Layout
- The game: project.godot, src/ code, levels/ scenes, tests/ tests, assets/, addons/ (third-party, read-only).
- Everything else is in workflow/, which Godot ignores: docs/ (design, roadmap, learning), plans/, reviews/, state/, research/, tools/ (check and hook scripts), REVIEW.md.
- workflow/state/ holds working notes for the /ideas and /assets skills. They are not specs: workflow/docs/design.md and the issue's plan win.

## Naming
Every feature or bug starts as a GitHub issue. Its number, padded to 3 digits (`NNN`), plus a short kebab-case slug, names everything about it. Example: issue #12 Bhop.
- Plan: `workflow/plans/NNN-slug.md` (`workflow/plans/012-bhop.md`). Its second line is `Issue: #N`.
- Branch: `feat/NNN-slug` for features, `fix/NNN-slug` for bugs. Throwaway experiments: `spike/slug`.
- Review reports: `workflow/reviews/NNN-slug-r<round>.md` (`workflow/reviews/012-bhop-r1.md`).
- Commits: Conventional Commits, `type(scope): summary (#N)`, e.g. `feat(movement): add bhop speed cap (#12)`. Types: feat, fix, test, docs, refactor, chore. Scopes: movement, aim, ui, debug, tools, docs. Work with no issue (setup, chores) leaves out `(#N)`.
- Merge to main: the merge commit message ends with `Closes #N`, so GitHub closes the issue on push.
- Use 3 digits only in file and branch names. In commit messages and issue text, write `#12`, GitHub's own form.

## Review
Reviews follow `.agents/skills/review/SKILL.md` and the rules in workflow/REVIEW.md. Reports go to `workflow/reviews/NNN-slug-r<round>.md` (see Naming).
