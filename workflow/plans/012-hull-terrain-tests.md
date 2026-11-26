# Hull and terrain tests
Issue: #12
Status: approved

Feature 5a of roadmap phase 1 (movement base). Before we build our own course (5b), it proves that SUCC's box hull crosses seams and ramp edges without snagging, and it pins the step-height, slope and jump-ledge limits. It adds no game code. It builds on the movement test rig from #8 and #10 (`tests/helpers/movement_rig.gd`).

Approach (chosen): **literal expected numbers**, like #8 and #10. The jump-ledge limit was worked out offline by stepping SUCC's jump arc and its air step-up at 128 Hz (script in the appendix). Seam and edge cases use the pass rules below. Every test builds its own geometry and uses the frozen test config T, so neither the course nor `src/player/player_config.tres` can break them.

Facts from SUCC (`addons/SUCC/scripts/succ.gd`, read-only) and Godot that this plan relies on:
- Hull: a box 0.813 × 1.829 × 0.813 m with its bottom at the player origin (`src/player/player.tscn:10–45`). Origin height = feet height.
- Floor type (`:812–820`): on a floor at `ramp_angle_threshold` (45°, player-root @export, `:52`) or steeper, the type is RAMP. Flatter floor is FLOOR. Nothing steeper than `max_floor_angle` (SUCC default 50°, `:55`) counts as floor. The rig pins it at 45° (see Decision below).
- FLOOR: vertical velocity is set to 0, then friction and ground acceleration (`:414–422`). No gravity (`:393`).
- RAMP: gravity stays on, no friction, air acceleration only, jump ignored (`:393`, `:405–408`).
- Godot's `move_and_slide` (`character_body_3d.cpp`, master) keeps the `velocity` property on floor slopes. It changes only the displacement, which shrinks by cos²θ horizontally going up. Snapping down a slope doesn't touch velocity either. So **horizontal speed read from velocity stays 400 u/s on a walkable slope** with W held at top speed. Displacement per tick does not.
- Ground step-up (`:545–558`, `:624–673`): runs only when a face too steep to walk blocks the hull. It refuses a rise above `step_height` (0.45 m, `succ_config.gd:88`, `:666`). So 0.44 m climbs and 0.46 m blocks.
- Air step-up (`:563–593`): on every airborne tick, before the move, if a wall (normal y ≤ 0.01) blocks the hull, SUCC tries lifts of 0.02, 0.1325, 0.245, 0.3575 and 0.47 m (start `FLOOR_COL_MARGIN` 0.02, step `step_height`·0.25, cap `step_height` + 0.02). It keeps the first lift that clears.
- Jump (`:479–484`): from #8, a standing jump peaks 1.143 m up at tick 43 after takeoff (T).
- Floor snap length = `step_height` + 0.02 = 0.47 m (`:119`, `:159`).

**Decision (2026-11-25, after test 6b failed in implementation):** the rig pins `max_floor_angle` at **45°** (= `ramp_angle_threshold`), not SUCC's 50°. With 50°, Godot treats 45–50° as floor, removes vertical velocity on every floor contact, and `floor_stop_on_slope` zeroes a resting body's velocity. A player resting on 46° slid 0.000 m. A probe showed `floor_stop_on_slope` off only creeps 0.134 m; `max_floor_angle` 45° slides 11.3 m (18.2 m/s after about 1.2 s); 44° holds still in every case. The game's own value in `src/player/player.tscn` is fixed separately in bug issue #13, so this feature still changes no game code.

## Behaviour
What the player gets: crossing a join between two floor pieces, or the edge of a ramp, never costs speed or bumps you. Steps, slopes and ledges have exact, known limits. All numbers use config T, `ramp_angle_threshold` 45°, `max_floor_angle` 45°. Speeds are horizontal, read from `velocity`, in u/s.

1. **Straight seam.** Running at top speed with W held across the join between two floor boxes (seam at 90° to the run): speed stays 400 ±1 u/s on every tick, feet height stays the same ±1 cm, floor type is FLOOR on every tick.
2. **Diagonal seam.** Same as 1, with the seam at 45° to the run.
3. **Bhop landing on a seam.** A W + jump (held) chain from top speed whose first landing has the seam under the hull: speed stays 400 ±1 u/s on every tick for 3 hops. Each landing is at floor height ±1 cm. Each landing is followed by a jump on the next tick (0 ground ticks).
4. **Ramp edges, 15° and 30°.**
   - a. Up-run: from top speed on the floor, W held, up the ramp and onto a flat platform flush with its top. No tick loses more than 1 u/s against the tick before. The 30° ramp's crest (ramp → platform) may leave the ground, as in Source; the speed rule still holds there.
   - b. Down-run: from the platform, W held at top speed, down the ramp onto the floor. Same speed rule. Also, on every tick while the player is within 1 m (horizontal) of the ramp → floor edge, the floor type is not NONE (no bounce).
5. **Steps.** Walking at top speed into a box:
   - a. 0.44 m tall: the player climbs it and ends on top, feet at 0.44 ±0.01 m, floor type FLOOR.
   - b. 0.46 m tall: the player is blocked. Horizontal speed drops to 0 ±1 u/s, the player stops at the face, feet stay at floor height ±1 cm.
6. **Slopes.**
   - a. 44°: a player resting on the face (no input) is on FLOOR and moves less than 1 cm in 128 ticks. With W held uphill for 128 ticks, feet rise more than 1 m.
   - b. 46°: a player resting on the face (no input) is on RAMP and slides more than 1 m downhill in 128 ticks.
7. **Jump-ledge limit.** Standing against a wall, W held into it, one jump (jump held 1 tick), no crouch. The highest ledge a standing jump climbs is **1.613 m** (apex 1.143 m + top air lift 0.47 m).
   - a. Ledge 1.593 m (limit − 2 cm): the player ends on top, feet at 1.593 ±0.01 m, floor type FLOOR.
   - b. Ledge 1.633 m (limit + 2 cm): the player falls back, feet at floor height ±1 cm.

For 5b: the shipped config has the same jump height and step height, so the course's ledges go at 1.563 m and 1.663 m.

## Files to touch
- `tests/helpers/movement_rig.gd` (changed):
  - `spawn()` gains `with_floor: bool = true`. Today it always adds the 200 × 200 m floor (`:117–126`). Existing callers don't change.
  - `spawn()` sets the player root's `ramp_angle_threshold` to 45° and `max_floor_angle` to 45° from new constants, so the tests pin them like the config. A comment on the `max_floor_angle` constant points to the Decision above and #13.
  - `test_config()` also sets `step_height = 0.45`.
  - New `add_box(size: Vector3, position: Vector3, rotation_deg: Vector3 = Vector3.ZERO) -> StaticBody3D`: a static box with a `BoxShape3D`, added under the rig.
  - New `add_ramp(angle_deg: float, low_edge: Vector3, length: float, width: float, thickness: float = 0.5) -> StaticBody3D`: a box rotated about X so its top face rises toward −Z at `angle_deg`, with the top face's low edge centred on `low_edge`. `length` is measured along the slope.
- `tests/movement/test_movement_rig.gd` (changed): adds tests for the new pieces (see How to test). Existing tests stay as they are.
- `tests/movement/test_seams.gd` (new): behaviours 1–3.
- `tests/movement/test_ramp_edges.gd` (new): behaviour 4.
- `tests/movement/test_steps_slopes.gd` (new): behaviours 5–6.
- `tests/movement/test_jump_ledge.gd` (new): behaviour 7.

No files in `src/`, `levels/` or `addons/` change.

## Sliders
None. This feature adds no game code. The values the tests depend on are pinned in the rig, not sliders: `step_height` 0.45 m (config T), `ramp_angle_threshold` 45° and `max_floor_angle` 45° (player root).

## How to test
Each test drives SUCC through the rig's `command` and reads the per-tick trace. Tolerances are the rig's: speed ±1 u/s, height ±1 cm, ticks ±1. "Top speed" means reached the way the #10 tests reach it.

- `test_movement_rig.gd`:
  - `test_config()` has `step_height` 0.45.
  - `spawn(config, at, false)` adds no floor. `spawn()` sets `ramp_angle_threshold` 45° and `max_floor_angle` 45°.
  - `add_box` has a collision shape of the given size at the given place. A ray cast down onto it hits its top at the expected height.
  - `add_ramp(30, …)`: ray casts down hit the top face at the low edge (height of `low_edge` ±1 mm) and one metre up the slope (rise = tan 30° per horizontal metre ±1 mm). The hit normal is 30° from up ±0.1°.
- `test_seams.gd`: build the floor from two boxes (top at y = 0, `with_floor` false).
  - (1) Seam across the run, 5 m past the point where top speed is reached. Run W for 2 s. Assert behaviour 1 on every tick after top speed.
  - (2) Same with both boxes turned 45° about Y so the seam crosses the run at 45°.
  - (3) Put the seam 6.826 m past the takeoff point: one hop at 400 u/s is 86 ticks × 10.16 m/s / 128 = 6.826 m, and the hull spans ±0.41 m, so the seam is under it on landing. Hold W + jump for 3 hops. Assert behaviour 3.
- `test_ramp_edges.gd`: rig floor plus `add_ramp` and a platform box flush with the ramp top. 15° and 30° ramps, 6 m along the slope.
  - (4a) Start 5 m before the low edge at top speed, W held, until 3 m onto the platform. Speed rule on every tick.
  - (4b) Start on the platform 3 m before the top edge at top speed, W held downhill, until 5 m past the low edge. Speed rule on every tick. No NONE floor type while within 1 m of the low edge.
- `test_steps_slopes.gd`:
  - (5a, 5b) A box 0.44 m (then 0.46 m) tall, 5 m past top speed. Run W into it for 1 s.
  - (6a, 6b) A 44° (then 46°) ramp, 10 m along the slope. Spawn the player above the middle of its face, with the hull's uphill bottom edge 5 cm clear of the face (feet 0.4065 · tan(angle) + 0.05 m above the face), no input. 44°: wait for FLOOR (settle), then 128 ticks of no input, then 128 ticks of W uphill. 46°: 128 ticks of no input from spawn; assert RAMP once it lands, and downhill movement.
- `test_jump_ledge.gd`: a box 4 m wide whose top is at 1.593 m (then 1.633 m). Spawn the player facing it, hull front 1 cm from the face. Settle. W held for 10 ticks (presses into the face), then W + jump for 1 tick, then W for 150 ticks. Assert behaviour 7a / 7b on the last tick.
- `workflow/tools/check.ps1` must pass. These are real-time tests: expect about 20–25 s more.
- **Stop-and-report rule** (same as #8 and #10): if a measurement is out of tolerance, the Implement chat stops and reports measured against expected. It doesn't change tolerances, expected numbers or pass rules, and it doesn't edit `addons/`. The user decides: an accepted SUCC quirk (reason recorded in this plan) or a bug issue.
- Proof: GUT output for the four new files and the rig file. No screenshot: nothing visual changes.

## Out of scope
- The course scene itself, its texture and signs, deleting the demo course, and the main-scene switch (feature 5b).
- Seams on surf ramps ("rampbug"): issue #9.
- Crouch-jump ledge limit and crouch-jump apex: issue #7.
- The game's own `max_floor_angle` in `src/player/player.tscn`: bug issue #13.
- Air step-up onto stairs mid-bhop, step climbing speed, and slopes between 44° and 46°.
- Printing these numbers for the shipped config in `test_movement_report.gd`.
- Fixing any snag found. A snag becomes its own bug issue.

## Appendix: how the expected numbers were computed
Python, stepping SUCC's jump arc and air step-up per tick at dt = 1/128 (T):

```python
import math
dt = 1/128; g, h = 20.32, 1.143
step_height, margin = 0.45, 0.02                  # succ_config.gd:88, succ.gd:31

lifts = []; p = margin                            # succ.gd:584-589
while p <= step_height + margin:
    lifts.append(p); p += step_height * 0.25
# lifts = [0.02, 0.1325, 0.245, 0.3575, 0.47]

v0 = math.sqrt(2 * g * h)                         # same arc as #8: the -g*dt/2
y = lambda k: v0 * k * dt - g * (k * dt)**2 / 2   # start makes tick heights exact
apex = max(y(k) for k in range(90))               # 1.143 m at k = 43
# Air step-up runs before the move, from the height after the previous tick,
# so the best climb is from the apex with the top lift:
limit = apex + lifts[-1]                          # 1.613 m
```
