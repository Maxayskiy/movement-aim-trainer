# Ideas chat state

## Decisions

- 2026-11-24: Naming follows AGENTS.md "Naming": every feature starts as a GitHub issue; plans, branches and reviews use the 3-digit issue number (`012-bhop`); commits use Conventional Commits with `(#N)`.
- 2026-11-23: Learn first. The user learns Godot basics through the Teach chat before feature planning starts. Anything we implement, the user checks it in the Teach chat until they understand it.
- 2026-11-23: Learning is done in a throwaway practice game, "Box Gym", kept in its own Godot project outside this repo.

## Plans

_None yet._

## Docs written

- `docs/learning-path.md`: 16 Godot skills in learning order, each with a Box Gym step. Draft, waiting for the user's review.

- `docs/box-gym-teaching.md`: instructions the Teach chat follows to teach Box Gym. The user types all code; Teach guides and checks. This file overrides the Teach skill for Box Gym sessions only.

- `docs/roadmap.md`: phases 0–7 with sizes and gates. Draft, waiting for the user's approval.

## Open questions

_None._ (Decided: don't change the Teach skill. Box Gym teaching uses docs/box-gym-teaching.md instead.)

## Backlog

The backlog moves to GitHub issues (see AGENTS.md "Naming"). File these as issues once `gh` is signed in as Maxayskiy, or by hand, then delete them from here.

- First real feature after learning: probably bhop + air strafing on the movement test course (the design doc's quality bar).
- Movement gotchas. Put these in the first movement plan:
  - Physics tick at 128 Hz (`physics/common/physics_ticks_per_second`). The project still uses the default 60.
  - `Input.use_accumulated_input = false`, so mouse look reads every input event.
  - Test SUCC's box hull on floor seams and ramp edges. It can snag there.
  - Use `move_and_collide` (not only `move_and_slide`) for wall bounce, superglide and grapple, where we need the exact collision normal.
  - SUCC's input actions (forward, back, left, right, jump, crouch, sprint) aren't defined in the Input Map yet. Godot warns about this on every boot.
