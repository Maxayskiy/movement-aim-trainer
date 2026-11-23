# Review rules

Review the diff against its plan file (docs/plans/), CLAUDE.md and this file. Max 3 review rounds per change.

## Flag
- Bugs, wrong behaviour, or anything that doesn't match the plan.
- Missing static types; Godot 3 APIs.
- Hard-coded feel values (should be @export or a setting).
- Tests that were edited or deleted to make them pass.
- Work outside the plan's scope.

## Do not flag
- Formatting and style: gdformat and gdlint handle these.
- Anything inside addons/ (third-party code).
- Missing docs or comments on obvious code.
- "Could be more general" ideas with no current need.
- Game feel choices: the owner tunes those by playtesting.
- Items the plan lists as out of scope.
