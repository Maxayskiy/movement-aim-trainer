---
name: implement
description: Implement chat. Builds one approved plan file, with proof. Usage: /implement workflow/plans/NNN-slug.md
disable-model-invocation: true
argument-hint: workflow/plans/NNN-slug.md
---

You are the **Implement** chat. Build exactly one plan: `$ARGUMENTS`. Start this chat fresh for each plan.

1. **Read the plan.** If it is missing, its status isn't `approved`, or it has no issue number, stop and tell me to finish it in /ideas. Names below follow AGENTS.md "Naming".
2. **Branch.** From an up-to-date main: `git switch -c feat/NNN-slug` (or `fix/NNN-slug` for a bug), the same `NNN-slug` as the plan file.
3. **Plan mode.** Enter plan mode and propose the build as small steps, each one ending in a passing check. Wait for my OK.
4. **Build, step by step.** After each step:
   - run `powershell -NoProfile -ExecutionPolicy Bypass -File workflow/tools/check.ps1`, and get it green before the next step
   - commit that step: `type(scope): summary (#N)`, e.g. `test(movement): add bhop speed gain test (#12)`
   Write each test before the code it covers, and watch it fail first.
5. **Proof.** Show the check.ps1 output. For anything visual, take a screenshot through godot-ai (`editor_screenshot`; `source: "game"` while the game runs) with the debug overlays on.
6. **Hand back.** Report what you built against each plan section, what you couldn't verify, and any follow-ups. I playtest and tune the sliders next. Then review happens in a fresh Codex chat (or a fresh /review chat), which writes `workflow/reviews/NNN-slug-r<round>.md`.

## Fix round

When I say "fix round R" (after a review wrote `workflow/reviews/NNN-slug-rR.md`):

1. **Filter.** Run the `review-filter` subagent on the report. Append its "Filter result" section to the report file.
2. **Show me** the kept findings and wait for my OK. I may drop more.
3. **Fix** each kept finding, test first where it is a bug, running check.ps1 after each fix.
4. **Commit** the fixes together with the review report: `fix(scope): address review rR (#N)`.
5. **Hand back:** what you fixed, and that round R+1 is next. After round 3, list what is still open for me to decide instead.

## Merge

When I say "merge" (the last review said "ready to merge"): switch to main, pull, then `git merge --no-ff feat/NNN-slug` with the message `feat(scope): <feature name> (#N)` and a last line `Closes #N`. Run check.ps1 on main, push only when I say so, then delete the branch.

## Scope

The plan file is the contract. Work found outside it goes into your report as a follow-up. If the plan turns out to be wrong or impossible, stop and tell me; fixing the plan happens in /ideas.

If a test looks wrong, stop and tell me. Tests change only with my approval.
