# Ideas chat state

## Decisions

- 2026-11-24 (movement base): plan phase 1 now; hold building until Box Gym step 6 unless the user says otherwise.
- 2026-11-24 (movement base): the base uses everything SUCC ships, switched on (bhop buffered jump, air strafing, surf). "Later concepts" = phase 3 techs.
- 2026-11-24 (movement base): our config starts as a copy of SUCC's `default_config.tres` (10.16 m/s, air accel 100, bob/tilt off), except no sprint (`sprint_speed_modifier` 1.0, slider kept). Crouch stays.
- 2026-11-24 (movement base): keep SUCC's box hull; test it on seams and ramp edges in the course feature.
- 2026-11-24 (movement base): phase 1 split: (1) player scene + config + project setup + respawn, (2) debug overlay, (3) ground/jump number tests, (4) bhop/air-strafe tests, (5) own grey-box course incl. seams, ramp edges, bhop strip, surf ramp, (6) in-game tuning panel.
- 2026-11-24 (movement base): keys: WASD, Space jump (no mouse-wheel jump), Left Ctrl crouch, R respawn, Esc frees mouse (SUCC). First-person only. FOV stays SUCC's 90 (vertical) until phase 2.
- 2026-11-24 (movement base): respawn on R and below a kill height (@export, default -30 m), zero velocity.
- 2026-11-24 (movement base): feature 1 uses approach B: SUCC's script stays on the root unchanged; respawn and input setup are child nodes. player.gd comes with the first tech that needs a movement-loop hook.
- 2026-11-24 (movement base): feature 1 includes 128 Hz tick, `use_accumulated_input = false`, SUCC input actions in the Input Map; keeps the demo course geometry, drops the demo level script, adds our own respawn.

- 2026-11-24: Naming follows AGENTS.md "Naming": every feature starts as a GitHub issue; plans, branches and reviews use the 3-digit issue number (`012-bhop`); commits use Conventional Commits with `(#N)`.
- 2026-11-24: The roadmap stays broad. Phases set goals and gates; the specific features are chosen when each phase starts.
- 2026-11-23: Learn first. The user learns Godot basics through the Teach chat before feature planning starts. Anything we implement, the user checks it in the Teach chat until they understand it.
- 2026-11-23: Learning is done in a throwaway practice game, "Box Gym", kept in its own Godot project outside this repo.

## Plans

- **Movement base (phase 1)**: Big, split into 6 features (see Decisions).
  - Feature 1 **Player base**: `workflow/plans/001-player-base.md`, issue #1, approved 2026-11-24. Build waits for Box Gym step 6 unless the user says otherwise. Approach B (compose around SUCC; no player.gd yet).

## Docs written

- `workflow/docs/learning-path.md`: 16 Godot skills in learning order, each with a Box Gym step. Draft, waiting for the user's review.

- `workflow/docs/roadmap.md`: phases 1–7, kept broad on purpose. Each phase has a goal, a pool of example directions, a size range and a gate. We pick a phase's contents when it starts (e.g. phase 3 = "1–3 complex movement techs", not a fixed list). Approved 2026-11-24.

## Open questions

- Movement base feature 5: the demo course already has stairs, slants, bhop blocks, a crouch tunnel and surf ramps. Revisit whether feature 5 shrinks to adding seams/ramp edges, or is dropped.

## Backlog

The backlog moves to GitHub issues (see AGENTS.md "Naming"). `gh` is signed in as Maxayskiy (2026-11-24): file these as issues, then delete them from here. The movement gotchas below are now covered by issue #1, except the hull-snag and move_and_collide notes (features 5 / phase 3).

- First real feature after learning: probably bhop + air strafing on the movement test course (the design doc's quality bar).
- Movement gotchas. Put these in the first movement plan:
  - Physics tick at 128 Hz (`physics/common/physics_ticks_per_second`). The project still uses the default 60.
  - `Input.use_accumulated_input = false`, so mouse look reads every input event.
  - Test SUCC's box hull on floor seams and ramp edges. It can snag there.
  - Use `move_and_collide` (not only `move_and_slide`) for wall bounce, superglide and grapple, where we need the exact collision normal.
  - SUCC's input actions (forward, back, left, right, jump, crouch, sprint) aren't defined in the Input Map yet. Godot warns about this on every boot.
