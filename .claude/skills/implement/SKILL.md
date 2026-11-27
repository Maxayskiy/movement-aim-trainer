---
name: implement
description: Implement chat. Builds one approved plan file, with proof. Usage: /implement workflow/plans/NNN-slug.md
disable-model-invocation: true
argument-hint: workflow/plans/NNN-slug.md
---

You are the **Implement** chat. Build exactly one plan: `$ARGUMENTS`. Start this chat fresh for each plan.

1. **Read the plan.** If it is missing, its status isn't `approved`, or it has no issue number, stop and tell me to finish it in /ideas. Names below follow AGENTS.md "Naming".
2. **Branch.** From an up-to-date main: `git switch -c feat/NNN-slug` (or `fix/NNN-slug` for a bug), the same `NNN-slug` as the plan file.
3. **Build, step by step.** The approved plan is the gate: start building, no plan mode. After each step:
   - run check.ps1 (command in AGENTS.md "Check your work"), and get it green before the next step. Don't rerun it unless code changed since the last green run.
   - check tracked changes only (`git status --porcelain --untracked-files=no`): other chats' untracked drafts share this folder and don't stop the build
   - stage only the files this step touched (never `git add -A`) and commit that step (format in AGENTS.md "Naming")
   Write each test before the code it covers, and watch it fail first.
4. **Proof.** Show the check.ps1 output. For anything visual, take a screenshot through godot-ai (`editor_screenshot`; `source: "game"` while the game runs) with the debug overlays on.
5. **Hand back.** Report what you built against each plan section, what you couldn't verify, and any follow-ups. I playtest and tune the sliders next. Then review happens in a fresh Codex chat (or a fresh /review chat), which writes `workflow/reviews/NNN-slug-r<round>.md`.

The build is done when every plan section is built, each behaviour line has a passing test, check.ps1 passes on the last commit, and the proof is shown.

## Commits, push and PRs

Running this skill is my request to commit: commit each step and each fix round without asking. Don't ask about or offer to push or open a pull request, including as a button. We merge locally (see Merge). After the build, the next steps are my playtest, then review.

## Fix round

When I say "fix round R" (after a review wrote `workflow/reviews/NNN-slug-rR.md`):

1. **Filter.** Run the `review-filter` subagent on the report. Append its "Filter result" section to the report file.
2. **Show me** the kept findings, plus every minor item in one line each, and wait for my OK. I may drop more or promote a minor one. Minor items get no code or test changes.
3. **Fix** each kept finding, test first where it is a bug, running check.ps1 after each fix.
4. **Commit** the fixes together with the review report: `fix(scope): address review rR (#N)`.
5. **Hand back:** what you fixed, and that round R+1 is next. After round 3, list what is still open for me to decide instead.

## Merge

When I say "merge" (the last review said "ready to merge"): switch to main, pull, then `git merge --no-ff feat/NNN-slug` with the message `feat(scope): <feature name> (#N)` and a last line `Closes #N`. Run check.ps1 on main, push only when I say so, then delete the branch.

## Scope

The plan file is the contract. Work found outside it goes into your report as a follow-up. If the plan turns out to be wrong or impossible, stop and tell me; fixing the plan happens in /ideas.

Also stop and tell me when:
- a test still fails after two tries with different fixes
- a step can't be undone with `git revert`

If a test looks wrong, stop and tell me. Tests change only with my approval.
