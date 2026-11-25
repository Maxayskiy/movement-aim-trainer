# Ground and jump number tests
Issue: #8
Status: approved

Third feature of roadmap phase 1 (movement base). It proves SUCC's ground and jump mechanics give the numbers Source's formulas predict, so later work (player.gd, techs, tuning) can't silently change how movement feels. It also builds a movement test rig that feature 4 (bhop/air-strafe tests) reuses. It adds no game code.

Approach (chosen): **literal expected numbers.** The tests use a fixed test config. The expected values below were worked out offline by stepping Source's per-tick formulas at 128 Hz (script in the appendix) and are written into the tests as constants. Retuning `src/player/player_config.tres` never breaks these tests.

Facts from SUCC this plan relies on (`addons/SUCC/scripts/succ.gd`, read-only):
- `command: SUCCInput` (`:77`): when set, `simulate()` reads move/jump/crouch/sprint/yaw/pitch from it instead of `Input` (`:259–265`). `move` is x = right, y = back, normalized or zero (`succ_input.gd:7`). Yaw and pitch are applied from the command every tick (`:288–292`), so keep `yaw` at the spawn yaw.
- Tick order in `simulate()` (`:315–352`): read input → classify floor → gravity (only when not `FLOOR`, `:390`) → `_set_velocity` → `move_and_slide` → classify floor again.
- On a `FLOOR` tick without jump: vertical speed is set to 0, then `_friction` then `_accelerate` (`:418–422`, `:425–452`). Friction uses `max(speed, stop_speed)` (`:430`).
- On a `FLOOR` tick with jump: `_jump` sets vertical speed to `sqrt(2·gravity·jump_height) − gravity·dt/2` (`:479–482`), then air acceleration. No friction on the takeoff tick.
- Air ticks (`NONE`): gravity, then `_air_accelerate`, which adds nothing when the wish points along the current velocity (`:471–474`). There is no air friction.
- With `bhop_buffered_jump` on, holding jump re-jumps on the landing frame (`:257`, `:264`). The tests must release jump after takeoff unless they want a hop.
- Crouch: `_wish_speed` uses `max_speed × crouch_speed_modifier` while crouched (`:301–306`). The first crouched tick still uses the standing wish, because input is read before `_crouch()` runs (`:332`, `:400–401`).
- Sprint: `_wish_speed` uses `max_speed × sprint_speed_modifier` when sprint is wished and the `sprint` action exists (`:304`). It exists in project.godot (feature 1).
- Signals `jumped` (`:11`, emitted in `_jump`) and `landed` (`:12`, emitted in `_move_body` on the touchdown tick).
- `SUCCConfig.SOURCE_MULT = 39.37` converts m/s to u/s (`succ_config.gd:6`).
- GUT 9.7.1 only runs files named `test_*.gd`, so `tests/helpers/` files are not run as tests. A test with no asserts is marked risky; use `pass_test()` where a test only prints.

## Behaviour
All numbers are at 128 ticks/s (dt = 1/128 s). "Speed" means horizontal speed (x/z). T = the test config, S = the second config (see Sliders).

1. **Top speed.** Holding forward on flat ground for 1 s from standstill: speed never goes above max_speed, and ends at max_speed. T: 400.0 u/s. S: 315.0 u/s. Holding forward + right (diagonal) gives the same top speed with T, not √2 times it.
2. **Time to top speed.** From standstill, holding forward, speed reaches max_speed (within 0.01 m/s) on tick 25 (0.195 s), after 1.138 m (T).
3. **Stopping.** From top speed, releasing every key, speed reaches 0 (below 0.001 m/s) on tick 62 (0.484 s), after 1.976 m (T). S: tick 36 (0.281 s).
4. **Crouch walk.** Holding crouch + forward for 2 s from standstill: speed never goes above 133.3 u/s and ends at 133.3 u/s (T; reached by tick 40).
5. **No sprint.** Holding sprint + forward for 1 s from standstill: speed never goes above 400.0 u/s and ends at 400.0 u/s (T, sprint modifier 1.0).
6. **Jump apex and airtime.** A standing jump (jump held for 1 tick) peaks 1.143 m above the standing height (T) or 2.000 m (S). Airtime, counted as the `landed` tick minus the `jumped` tick, is 85 ticks (0.664 s) (T).
7. **Takeoff keeps speed.** Jumping while running at top speed: the speed on the `jumped` tick equals the speed on the tick before (change 0 u/s; ground friction would have cost 12.5 u/s) (T).
8. **No air friction, landing keeps speed.** After that jump, with every key released from the tick after takeoff: speed stays 400.0 u/s on every air tick and on the `landed` tick. On the tick after landing, friction applies once: 387.5 u/s (T).
9. **Falling.** Dropped from rest in the air, vertical speed after k ticks is −gravity·k/128. After 64 ticks (0.5 s): −400.0 u/s (−10.16 m/s) (T).
10. **Report.** The test run prints the shipped config's (`player_config.tres`) numbers, measured the same way, with no asserts on them:
    ```
    Movement numbers: res://src/player/player_config.tres @ 128 Hz
    top speed        400 u/s
    0 -> top speed   25 ticks   0.195 s   1.138 m
    stop from top    62 ticks   0.484 s   1.976 m
    jump apex        1.143 m
    airtime          85 ticks   0.664 s
    ```
    (Today's values shown. They change when the config is retuned; that's the point.)

Tolerances for every assert: speeds ±1 u/s, heights ±0.01 m, distances ±0.02 m, ticks ±1.

## Files to touch
New:
- `tests/helpers/movement_rig.gd`: `class_name MovementRig extends Node`. The reusable rig (feature 4 builds on it).
  - `static func test_config() -> SUCCConfig`: a new `SUCCConfig` with every value in the Sliders "T" column set explicitly (frozen; don't load `player_config.tres`).
  - `static func second_config() -> SUCCConfig`: `test_config()` with max_speed 8.0, jump_height 2.0, friction 6.0.
  - `func spawn(config: SUCCConfig, at: Vector3 = Vector3(0.0, 0.01, 0.0)) -> SUCC`: builds a flat floor once (`StaticBody3D` + `BoxShape3D` 200 × 1 × 200 m, top face at y = 0) as a child of the rig, instances `res://src/player/player.tscn`, sets `config` **before** adding it to the tree, sets `command` to an idle `SUCCInput` (yaw 0) so SUCC never reads real input, connects `jumped`/`landed`, and adds it as a child.
  - `func settle() -> bool` (await it): waits until `floor_type == FLOOR` on 2 ticks in a row, up to 64 ticks. Returns false if it doesn't settle; tests call `assert_true(await rig.settle())`.
  - `func play(steps: Array[Step]) -> void` (await it): runs the steps in order. Each `Step` (inner class) holds one `SUCCInput` and a tick count. Clears the trace first.
  - The trace: `trace: Array[Sample]` (inner class `Sample`: `tick: int`, `position: Vector3`, `velocity: Vector3`, `floor_type: SUCC.FloorType`, `jumped: bool`, `landed: bool`, `input: SUCCInput`). `trace[0]` is the state when `play()` starts (tick 0). `trace[i]` is the state after the i-th tick of the play, with the input that tick used. So `trace[i].input` is step 1's input for i = 1…step 1's count, and so on.
  - Recording: the rig sets `process_physics_priority = 1` so its `_physics_process` runs **after** SUCC's tick in the same physics frame. There it records a `Sample`, then switches `command` to the next step's input when a step's ticks are used up (so the switch applies from the next tick).
  - Helpers: `static func ups(mps: float) -> float` (m/s × 39.37), `static func horizontal_speed(v: Vector3) -> float`, `static func horizontal_distance(a: Vector3, b: Vector3) -> float`.
  - Constants for the tolerances: `SPEED_TOL_UPS = 1.0`, `HEIGHT_TOL_M = 0.01`, `DISTANCE_TOL_M = 0.02`, `TICK_TOL = 1`.
- `tests/movement/test_movement_rig.gd`: tests of the rig itself (see How to test).
- `tests/movement/test_ground_numbers.gd`: behaviours 1–5.
- `tests/movement/test_jump_numbers.gd`: behaviours 6–9.
- `tests/movement/test_movement_report.gd`: behaviour 10.

Each test file adds a fresh `MovementRig` with `add_child_autofree` in `before_each` and sets `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE` in `after_all` (SUCC captures the mouse in `_ready`), like the existing movement tests.

Changed: none. Not touched: `addons/`, `src/`, `project.godot`, `player_config.tres`. Doesn't depend on the debug overlay (#5); if #5 is merged first, the overlay child in `player.tscn` is harmless here.

## Sliders
No gameplay value changes, so no new sliders. For reference, the frozen test configs the tests use (not feel settings):

| Value | T (test config = today's defaults) | S (second config) |
|-------|-----|-----|
| gravity | 20.32 m/s² | same |
| jump_height | 1.143 m | **2.0 m** |
| bhop_buffered_jump | true | same |
| acceleration | 7.5 | same |
| friction | 4.0 | **6.0** |
| stop_speed | 4.0 m/s | same |
| max_speed | 10.16 m/s (400 u/s) | **8.0 m/s (315 u/s)** |
| air_acceleration | 100.0 | same |
| max_air_speed | 0.762 m/s | same |
| enforce_max_velocity | false | same |
| crouch_speed_modifier | 1/3 | same |
| sprint_speed_modifier | 1.0 | same |
| everything else | `SUCCConfig` defaults | same |

## How to test
The new test files are the deliverable. Each test drives the player only through the rig (`play` with `Step`s) and reads results from the trace. Below, `Step(forward, 10)` is shorthand for `MovementRig.Step.new(input, 10)` with `input.move = Vector2(0, -1)`; "idle" is an empty `SUCCInput`. Every play except (9) starts after `spawn` + `settle`. Every Behaviour line has a test:

- `test_movement_rig.gd`
  - `test_config()` and `second_config()` hold exactly the table's values.
  - After `spawn` + `settle`, `floor_type` is `FLOOR` and speed is below 0.001 m/s.
  - `play([Step(forward, 10), Step(idle, 5)])` gives `trace.size() == 16`, `trace[i].tick == i`, `trace[1..10].input.move` = forward, `trace[11..15].input.move` = zero.
  - With forward, `trace[1]` speed is 0.5953 m/s (23.4 u/s ±1): proves sample 1 is the first tick that used step 1's input.
- `test_ground_numbers.gd`
  - (1) T, forward 128 ticks: max speed over the trace ≤ 401 u/s; `trace[128]` speed 400.0 ±1 u/s.
  - (1) T, forward + right (`Vector2(1, -1).normalized()`) 128 ticks: same asserts.
  - (1) S, forward 128 ticks: max ≤ 316.0 u/s; `trace[128]` 315.0 ±1 u/s.
  - (2) T, forward 64 ticks: the first i with speed ≥ max_speed − 0.01 m/s is 25 ±1; `horizontal_distance(trace[0], trace[25])` 1.138 ±0.02 m.
  - (3) T, forward 64 then idle 80: the first idle sample with speed < 0.001 m/s is idle tick 62 ±1; the distance from `trace[64]` to that sample is 1.976 ±0.02 m.
  - (3) S, forward 64 then idle 80: stops on idle tick 36 ±1.
  - (4) T, crouch + forward 256 ticks: max ≤ 134.3 u/s; `trace[256]` 133.3 ±1 u/s.
  - (5) T, sprint + forward 128 ticks: max ≤ 401 u/s; `trace[128]` 400.0 ±1 u/s.
- `test_jump_numbers.gd`
  - (6) T, jump 1 tick then idle 128: `trace[1].jumped`; max of (y − `trace[0]` y) is 1.143 ±0.01 m; the `landed` sample's index − the `jumped` sample's index = 85 ±1.
  - (6) S, same play: apex 2.000 ±0.01 m.
  - (7) T, forward 64, then forward + jump 1 tick, then idle 128: on the `jumped` sample, speed − the previous sample's speed = 0 ±1 u/s.
  - (8) Same play: every sample from the `jumped` one up to and including the `landed` one has speed 400.0 ±1 u/s; the sample after `landed` has 387.5 ±1 u/s.
  - (9) T, spawn at (0, 10, 0) without `settle`, idle 64: for every k in 1…64, `trace[k].velocity.y` = −20.32·k/128 (±1 u/s); `trace[64]` −400.0 ±1 u/s.
- `test_movement_report.gd`
  - (10) Loads `res://src/player/player_config.tres`, spawns with it, and measures top speed, ticks/time/distance to top speed, stop ticks/time/distance, apex and airtime the same way. Prints the block in Behaviour 10 with `gut.p()`, then `pass_test()`.

**If a number is out of tolerance:** stop and report measured vs expected. Don't widen a tolerance, change an expected value, or touch `addons/`. The user decides: an accepted SUCC quirk (the reason is then written into this plan) or a bug issue.

Proof: paste the GUT output of the five new files, including the printed report block. No screenshot: this feature has nothing visual.

`workflow/tools/check.ps1` passes. Expect it to take roughly 10–15 s longer (the tests run in real time; speeding up time would change dt and the numbers).

## Out of scope
- Counter-strafe stop time (#6) and crouch-jump apex (#7).
- Step height, max floor angle, seams and ramp edges (feature 5).
- Bhop, air strafing and surf numbers (feature 4).
- A reference model that predicts numbers for any config (approach B, not chosen; feature 4 may add one).
- Changing SUCC, `player_config.tres` or any gameplay value. If a test exposes a SUCC bug, it becomes its own issue.
- Testing real key input. The key bindings are covered by feature 1's `test_project_setup.gd`; these tests drive SUCC through `command`.
- Saving the report to a file, or asserting on the shipped config's numbers.

## Appendix: how the expected numbers were computed
Python, stepping SUCC's formulas per tick at dt = 1/128 (T shown; S uses w = 8.0, h = 2.0, f = 6.0):

```python
import math
dt = 1/128; g, h, a, f, s, w = 20.32, 1.143, 7.5, 4.0, 4.0, 10.16

def ground_tick(v, wish):                      # _friction then _accelerate
    if v > 0:
        v = max(v - max(v, s) * f * dt, 0.0)
    if wish > 0 and wish - v > 0:
        v += min(a * wish * dt, wish - v)
    return v

v = d = 0.0; k = 0                             # 0 -> top: 25 ticks, 1.138 m
while v < w - 1e-9:
    v = ground_tick(v, w); d += v * dt; k += 1

v = w; d = 0.0; k = 0                          # stop: 62 ticks, 1.976 m
while v > 0:
    v = ground_tick(v, 0); d += v * dt; k += 1

v0 = math.sqrt(2 * g * h)                      # jump: the -g*dt/2 start makes
y = lambda k: v0 * k * dt - g * (k * dt)**2 / 2   # tick heights exact
# apex = max y(k) = 1.143 m at k = 43; first y(k) < 0 at k = 86 -> airtime 85 ticks
```
