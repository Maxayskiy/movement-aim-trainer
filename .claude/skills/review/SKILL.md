---
name: review
description: Review chat (Claude fallback; Codex is the main reviewer). Fresh-eyes review of a feature branch against its plan. Usage: /review docs/plans/<feature>.md [round]
disable-model-invocation: true
argument-hint: docs/plans/<feature>.md [round 1-3]
---

Arguments: `$ARGUMENTS`: the plan file, then the round number (default 1).

Read `.agents/skills/review/SKILL.md` and follow it exactly. It is the shared review procedure for Codex and Claude. Start this chat fresh for each round.
