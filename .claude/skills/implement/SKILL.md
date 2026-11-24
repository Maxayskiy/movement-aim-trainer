---
name: implement
description: Implement chat. Builds one approved plan file, with proof. Usage: /implement docs/plans/<feature>.md
disable-model-invocation: true
argument-hint: docs/plans/<feature>.md
---

You are the **Implement** chat. Build exactly one plan: `$ARGUMENTS`. Start this chat fresh for each plan.

1. **Read the plan.** If it is missing or its status isn't `approved`, stop and tell me to finish it in /ideas.
2. **Branch.** `git switch -c feature/<feature>` from an up-to-date main.
3. **Plan mode.** Enter plan mode and propose the build as small steps, each one ending in a passing check. Wait for my OK.
4. **Build, step by step.** After each step:
   - run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check.ps1`, and get it green before the next step
   - commit that step
   Write each test before the code it covers, and watch it fail first.
5. **Proof.** Show the check.ps1 output. For anything visual, take a screenshot through godot-ai (`editor_screenshot`; `source: "game"` while the game runs) with the debug overlays on.
6. **Hand back.** Report what you built against each plan section, what you couldn't verify, and any follow-ups. I playtest and tune the sliders next. Then review happens in a fresh Codex chat (or a fresh /review chat), which writes `docs/reviews/<feature>-r<N>.md`.

## Fix round

When I say "fix round N" (after a review wrote `docs/reviews/<feature>-r<N>.md`):

1. **Filter.** Run the `review-filter` subagent on the report. Append its "Filter result" section to the report file.
2. **Show me** the kept findings and wait for my OK. I may drop more.
3. **Fix** each kept finding, test first where it is a bug, running check.ps1 after each fix.
4. **Commit** the fixes together with the review report.
5. **Hand back:** what you fixed, and that round N+1 is next. After round 3, list what is still open for me to decide instead.

## Scope

The plan file is the contract. Work found outside it goes into your report as a follow-up. If the plan turns out to be wrong or impossible, stop and tell me; fixing the plan happens in /ideas.

If a test looks wrong, stop and tell me. Tests change only with my approval.
