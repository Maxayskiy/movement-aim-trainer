# Review rules

Review the diff against its plan file (workflow/plans/), AGENTS.md and this file. Max 3 review rounds per change; rounds 2 and 3 review only the diff since the previous round. Procedure: .agents/skills/review/SKILL.md.

## Flag
- Bugs, wrong behaviour, or anything that doesn't match the plan.
- Hard-coded feel values (should be @export or a setting).
- Tests that were edited or deleted to make them pass.
- Work outside the plan's scope.

## Will a player hit this?
A bug or behaviour mismatch is a finding only if at least one of these holds:
- A player can hit it in real play: normal or repeated play, or holding keys. Judge how likely it is, not how short the timing window is: players hit bhop-style windows again and again.
- The damage is serious, however rare: a crash, lost or corrupted saves or settings, or a player stuck until restart.
- It breaks a plan behaviour in a way a player can notice in real play.

Anything else goes under "Minor, not fixing": one line each, with no code or test changes. For example, two separate key presses that only matter if they land on the same physics tick. The owner can promote a minor item to a finding.

This bar does not apply to the other Flag rules above, or to a test the plan asks for that is missing. Those are always findings.

## Do not flag
- Anything check.ps1 catches: formatting, style, lint, missing static types, Godot 3 APIs.
- Problems in code the change didn't touch, unless the change causes them.
- Anything inside addons/ (third-party code).
- Missing docs or comments on obvious code.
- "Could be more general" ideas with no current need.
- Game feel choices: the owner tunes those by playtesting.
- Items the plan lists as out of scope.
