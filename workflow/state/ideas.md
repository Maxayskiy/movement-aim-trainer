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
- 2026-11-25 (debug overlay, feature 2): a developer tool. A player speedometer setting comes in phase 4 and can reuse it.
- 2026-11-25 (debug overlay): shows horizontal speed, vertical speed, movement state, floor type, crouched, held keys (WASD/jump/crouch boxes), FPS, physics ticks/s, frame time (ms), process time, physics time. Bhop stats: last takeoff speed, gain vs previous takeoff, hops in a row (no history list). No position, no velocity vector.
- 2026-11-25 (debug overlay): speeds in u/s only.
- 2026-11-25 (debug overlay): F3 (`toggle_debug`) toggles everything except the horizontal speed, which always stays on. On at start (@export).
- 2026-11-25 (debug overlay): horizontal speed sits under the crosshair; everything else is a top-left panel, monospace, semi-transparent dark background, font size @export (default 18).
- 2026-11-25 (debug overlay): text and key boxes only. Speed graph (#2) and 3D velocity/wish-dir arrows (#3) are separate backlog issues.
- 2026-11-25 (debug overlay): speedometer = whole-number u/s, no unit text, white, ~40 px under the crosshair, size 28; offset, size and `show_speedometer` (default on, no key) are @exports. Gain/loss colour is backlog issue #4.
- 2026-11-25 (debug overlay): all speeds whole-number u/s; times in ms, 2 decimals.
- 2026-11-25 (debug overlay): a hop extends the chain only with ≤ `max_chain_ground_ticks` (@export, default 0) friction ticks between landing and jump; otherwise the chain restarts at 1. Panel also shows the last hop's ground ticks.
- 2026-11-25 (debug overlay): respawn (R or kill height) clears bhop stats, via a new `respawned` signal on `respawn.gd`.
- 2026-11-25 (debug overlay): performance numbers refresh every 0.25 s (@export); frame time is the window average; ticks/s is counted in real time, not read from settings. Movement numbers update every frame.
- 2026-11-25 (debug overlay): F3 state lasts for the session, not saved.
- 2026-11-25 (number tests, feature 3): tests guard mechanics, not tuning: they use their own fixed test config, so retuning `player_config.tres` never breaks them.
- 2026-11-25 (number tests): numbers covered: top ground speed = max_speed (diagonals too), time + distance 0→top, stop time + distance with no keys, crouch-walk top speed, sprint held doesn't change top speed, jump apex, airtime, takeoff tick keeps horizontal speed, landing tick keeps it (friction from the next tick), fall speed = −g·t. Counter-strafe → issue #6, crouch-jump apex → issue #7. Step height and slopes → feature 5.
- 2026-11-25 (number tests): build a reusable movement test rig (flat arena, spawn player, scripted per-tick input, per-tick trace) for feature 4 to reuse.
- 2026-11-25 (number tests): tests use a flat floor built in the test, not `test_course.tscn`.
- 2026-11-25 (number tests): tests also print the shipped config's numbers (no asserts): speeds u/s, distances/heights m, times s + ticks.
- 2026-11-25 (number tests): real-time tests are OK (~10–15 s more on check.ps1).
- 2026-11-25 (number tests): test config = frozen copy of today's defaults. A second config (max_speed 8, jump_height 2, friction 6) also runs top speed, apex and stop time.
- 2026-11-25 (number tests): tolerances: speeds ±1 u/s, heights ±1 cm, distances ±2 cm, times ±1 tick.
- 2026-11-25 (number tests): if a measurement is out of tolerance, the Implement chat stops and reports measured vs expected; no tolerance/expected edits, no addon edits. The user decides: accepted SUCC quirk (reason recorded in the plan) or bug issue.

- 2026-11-24: Naming follows AGENTS.md "Naming": every feature starts as a GitHub issue; plans, branches and reviews use the 3-digit issue number (`012-bhop`); commits use Conventional Commits with `(#N)`.
- 2026-11-24: The roadmap stays broad. Phases set goals and gates; the specific features are chosen when each phase starts.
- 2026-11-23: Learn first. The user learns Godot basics through the Teach chat before feature planning starts. Anything we implement, the user checks it in the Teach chat until they understand it.
- 2026-11-23: Learning is done in a throwaway practice game, "Box Gym", kept in its own Godot project outside this repo.

## Plans

- **Movement base (phase 1)**: Big, split into 6 features (see Decisions).
  - Feature 1 **Player base**: `workflow/plans/001-player-base.md`, issue #1. **Done**: merged to main, issue closed 2026-11-25. Approach B (compose around SUCC; no player.gd yet).
  - Feature 2 **Debug overlay**: `workflow/plans/005-debug-overlay.md`, issue #5, approved 2026-11-25. Ready for the Implement chat. Approach A: `DebugOverlay` CanvasLayer is a child of `player.tscn`; pure `BhopTracker` and `PerfSampler` classes hold the logic.
  - Feature 3 **Ground and jump number tests**: `workflow/plans/008-ground-jump-tests.md`, issue #8, approved 2026-11-25. Ready for the Implement chat. Approach A: literal expected numbers (computed offline, script in the plan's appendix). Rig `tests/helpers/movement_rig.gd` drives SUCC via `command` and records a per-tick trace; feature 4 reuses it. Doesn't depend on #5.
  - Features 4–6: not planned yet.

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
