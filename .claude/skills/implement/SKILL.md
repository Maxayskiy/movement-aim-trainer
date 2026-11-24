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
6. **Hand back.** Report what you built against each plan section, what you couldn't verify, and any follow-ups. I playtest and tune the sliders next. Then review happens in a fresh /review chat.

## Scope

The plan file is the contract. Work found outside it goes into your report as a follow-up. If the plan turns out to be wrong or impossible, stop and tell me; fixing the plan happens in /ideas.

If a test looks wrong, stop and tell me. Tests change only with my approval.
