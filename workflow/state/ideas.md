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
- 2026-11-25 (bhop/strafe tests, feature 4): bhop + air strafing only. Surf numbers → issue #9.
- 2026-11-25 (bhop/strafe tests): bhop numbers: 5-hop W+jump chain from top speed keeps 400 u/s every tick, hop period 86 ticks, 0 ground ticks; `bhop_buffered_jump` off and `enable_bhop` off each: held jump = one jump, press 1 tick early = no hop, press on first floor tick = hop with no loss; late jump above top speed costs ×0.96875 per ground tick, at top speed with W held a ground tick costs nothing.
- 2026-11-25 (bhop/strafe tests): strafe numbers: perfect one hop from 400 → 487.2 u/s; 5 perfect hops land at 487/561/626/685/740; strafe key without turning → 401.1 then flat; W in air adds nothing; S in air 400 → −30 u/s in 2 ticks.
- 2026-11-25 (bhop/strafe tests): "perfect strafe" = A or D only, yaw set each tick to the optimal wish angle (90° to horizontal velocity when per-tick accel ≥ max_air_speed, else velocity·wish = max_air_speed − accel), side switches every hop. With T: 4.29°/tick (549°/s).
- 2026-11-25 (bhop/strafe tests): new config A = T with air_acceleration 5 (accel-limited regime), runs the one-hop strafe test only. S not used.
- 2026-11-25 (bhop/strafe tests): report adds hop period, perfect-strafe speed after 1 and 5 hops, turn rate needed at top speed, air-brake ticks (no asserts). Tolerances and stop-and-report rule same as #8.
- 2026-11-25 (bhop/strafe tests): approach A (literal numbers). Accepted ~40 s more real-time test time in check.ps1, no trimming. Faster test runs (`--fixed-fps 128`) left out; not filed as an issue.

- 2026-11-25 (course, feature 5): build a new course scene from scratch (not edits to the SUCC demo course, not dropped).
- 2026-11-25 (course): the new course keeps a long strafe lane like the user's walled corridor in the demo course (14 m × 107 m, 22 m walls).
- 2026-11-25 (course): delete the SUCC demo course (`levels/test_course/`); the new course `levels/movement_course/` becomes the main scene. Changing `test_course_scene.gd` is a planned spec change the plan states.
- 2026-11-25 (course): layout = hub with stations; R returns to the hub. Linear timed runs → phase 5.
- 2026-11-25 (course): stations: hub + spawn pad; strafe lane 14×107 m, 22 m walls, marker every 10 m; bhop strip (gaps grow); seams & edges (seamed boxes, ramp-to-floor edges, ramp crest); steps 0.30/0.44/0.46/0.60 m; slopes 15/30/44/46°; jump ledges just under/over max jump height; crouch tunnel; surf V-ramp. No slide chute.
- 2026-11-25 (course): add step-height (0.44 climbs, 0.46 blocks) and slope (44° walkable, 46° slides) rig tests.
- 2026-11-25 (course): every feature 5 test builds its own geometry (like #8); a light scene test checks the course loads, has the player, is the main scene.
- 2026-11-25 (course): copy SUCC's demo grid texture (MIT) into `assets/textures/`; one tint per station type.
- 2026-11-25 (course): no barrier walls; floor edges open, falling off respawns via kill height.
- 2026-11-25 (course): split: 5a hull and terrain tests first (seams, ramp edges, crest, steps, slopes, standing-jump ledge limit; geometry built in tests, frozen test config), then 5b movement course (scene, texture, delete demo, main-scene switch, scene test).
- 2026-11-25 (course): 5b jump ledges sit 5 cm under and over the standing-jump ledge limit measured in 5a (SUCC air step-up and air duck raise it above 1.143 m). Crouch-jump limit stays in #7.
- 2026-11-25 (course): 5b bhop strip gaps need 400/450/500/550/600 u/s, each block labelled; missing a gap lands on the floor.
- 2026-11-25 (course): 5b copies demo sizes where they exist: crouch tunnel clearance 1.016 m; surf V 53° sides, 40 m long, 8.9 m start tower.
- 2026-11-25 (course): 5b Label3D sign per station (name + key number); strafe lane has a distance number every 10 m on the wall.
- 2026-11-25 (course): 5a seam cases: straight and 45° seams, ground run at 400 u/s W held, plus a bhop landing on a seam. Pass: 400 ±1 u/s every tick, height ±1 cm, never airborne on a ground run.
- 2026-11-25 (course): 5a ramp edges (15° and 30°, up and down) and 30° crest pass = no single-tick speed drop > 1 u/s at the edge; ramp→floor also no airborne tick; crest may go airborne (Source behaviour).
- 2026-11-25 (course): surf-ramp seams (rampbug) stay in #9 (comment added there).
- 2026-11-25 (course): box hull on seams, ramp-to-floor edges and ramp crests is proven by rig tests (400 u/s across: no speed loss, no vertical bump) plus a playtest. If SUCC snags: stop and report, same rule as #8/#10.

- 2026-11-24: Naming follows AGENTS.md "Naming": every feature starts as a GitHub issue; plans, branches and reviews use the 3-digit issue number (`012-bhop`); commits use Conventional Commits with `(#N)`.
- 2026-11-24: The roadmap stays broad. Phases set goals and gates; the specific features are chosen when each phase starts.
- 2026-11-23: Learn first. The user learns Godot basics through the Teach chat before feature planning starts. Anything we implement, the user checks it in the Teach chat until they understand it.
- 2026-11-23: Learning is done in a throwaway practice game, "Box Gym", kept in its own Godot project outside this repo.

## Plans

- **Movement base (phase 1)**: Big, split into 6 features (see Decisions).
  - Feature 1 **Player base**: `workflow/plans/001-player-base.md`, issue #1. **Done**: merged to main, issue closed 2026-11-25. Approach B (compose around SUCC; no player.gd yet).
  - Feature 2 **Debug overlay**: `workflow/plans/005-debug-overlay.md`, issue #5. **Done**: merged to main, issue closed 2026-11-25. Approach A: `DebugOverlay` CanvasLayer is a child of `player.tscn`; pure `BhopTracker` and `PerfSampler` classes hold the logic.
  - Feature 3 **Ground and jump number tests**: `workflow/plans/008-ground-jump-tests.md`, issue #8. **Done**: merged to main 2026-11-25 (merge commit lacked `Closes #8`, so the issue was still open on 2026-11-25). Approach A: literal expected numbers (computed offline, script in the plan's appendix). Rig `tests/helpers/movement_rig.gd` drives SUCC via `command` and records a per-tick trace; feature 4 reuses it. Doesn't depend on #5.
  - Feature 4 **Bhop and air-strafe tests**: `workflow/plans/010-bhop-strafe-tests.md`, issue #10. **Done**: merged to main via PR #11, issue closed 2026-11-25. Approach A: literal expected numbers (script in the plan's appendix); rig gains controlled steps (per-tick input from a Callable), new `PerfectStrafer` test helper. Depends on #8 (rig) being merged. Adds ~40 s of real-time ticks to check.ps1.
  - Feature 5a **Hull and terrain tests**: `workflow/plans/012-hull-terrain-tests.md`, issue #12, approved 2026-11-25. Implemented on `feat/012-hull-terrain-tests` (d142ffc), not merged yet. Approach A: literal ledge limit 1.613 m (apex 1.143 + top air lift 0.47, appendix script); seam/edge pass rules; rig gains `add_box`, `add_ramp`, `with_floor`, pins step_height/ramp threshold/max floor angle. 6b failed as feared; rig now pins `max_floor_angle` 45° (amendment committed on the feature branch). Shipped value → #13.
  - Bug **Player sticks on 45–50° slopes**: `workflow/plans/013-slope-stick.md`, issue #13, approved 2026-11-25. After #12. Walkable limit → Source's 45.573°.
  - Feature 5b **Movement course**: not planned yet (decisions above). Slope station 44°/46° still straddles the new 45.57° limit.
  - Feature 6: not planned yet.

## Docs written

- `workflow/docs/learning-path.md`: 16 Godot skills in learning order, each with a Box Gym step. Draft, waiting for the user's review.

- `workflow/docs/roadmap.md`: phases 1–7, kept broad on purpose. Each phase has a goal, a pool of example directions, a size range and a gate. We pick a phase's contents when it starts (e.g. phase 3 = "1–3 complex movement techs", not a fixed list). Approved 2026-11-24.

## Open questions

- #12 behaviour 6b failed in the Implement chat (2026-11-25): a player resting on 46° slides 0.000 m. Probe (scratch, headless): default 0.000 m; `floor_stop_on_slope` off only creeps 0.134 m (Godot strips vertical velocity on floor contact); `max_floor_angle` 45° (= ramp threshold) slides 11.3 m, 18.2 m/s after ~1.2 s. 44° stays still in all three. Decided 2026-11-25: #12's rig pins `max_floor_angle` 45° (plan amended, commit 0d5e646 on `feat/012-hull-terrain-tests`); the shipped value is bug issue #13 "Player sticks on 45–50° slopes".
- 2026-11-25 (#13): Godot's 0.01 rad floor margin confirmed by probe (max 45/thr 45 leaves 45.3° stuck). Walkable limit = Source's acos(0.7) = 45.573°: `ramp_angle_threshold` 45.573°, `max_floor_angle` 45°. Approach 1: values only in `player.tscn` + rig pins match + `pin_angles` flag; linking into one slider → feature 6. Plan `workflow/plans/013-slope-stick.md`, approved 2026-11-25 (committed on main 772ba1d, not pushed). Starts after #12 is merged; branch `fix/013-slope-stick`.
- Movement base feature 5b (course): next to plan (5a approved as #12). Ledges at 1.563 / 1.663 m (5a limit 1.613 m ± 5 cm).

## Backlog

The backlog moves to GitHub issues (see AGENTS.md "Naming"). `gh` is signed in as Maxayskiy (2026-11-24): file these as issues, then delete them from here. The movement gotchas below are now covered by issue #1, except the hull-snag and move_and_collide notes (features 5 / phase 3).

- First real feature after learning: probably bhop + air strafing on the movement test course (the design doc's quality bar).
- Movement gotchas. Put these in the first movement plan:
  - Physics tick at 128 Hz (`physics/common/physics_ticks_per_second`). The project still uses the default 60.
  - `Input.use_accumulated_input = false`, so mouse look reads every input event.
  - Test SUCC's box hull on floor seams and ramp edges. It can snag there.
  - Use `move_and_collide` (not only `move_and_slide`) for wall bounce, superglide and grapple, where we need the exact collision normal.
  - SUCC's input actions (forward, back, left, right, jump, crouch, sprint) aren't defined in the Input Map yet. Godot warns about this on every boot.
