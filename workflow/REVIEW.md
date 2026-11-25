# Review rules

Review the diff against its plan file (workflow/plans/), AGENTS.md and this file. Max 3 review rounds per change; rounds 2 and 3 review only the diff since the previous round. Procedure: .agents/skills/review/SKILL.md.

## Flag
- Bugs, wrong behaviour, or anything that doesn't match the plan.
- Hard-coded feel values (should be @export or a setting).
- Tests that were edited or deleted to make them pass.
- Work outside the plan's scope.

## Do not flag
- Anything check.ps1 catches: formatting, style, lint, missing static types, Godot 3 APIs.
- Problems in code the change didn't touch, unless the change causes them.
- Anything inside addons/ (third-party code).
- Missing docs or comments on obvious code.
- "Could be more general" ideas with no current need.
- Game feel choices: the owner tunes those by playtesting.
- Items the plan lists as out of scope.
