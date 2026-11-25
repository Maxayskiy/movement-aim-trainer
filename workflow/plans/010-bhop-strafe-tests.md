# Bhop and air-strafe tests
Issue: #10
Status: approved

Fourth feature of roadmap phase 1 (movement base). It proves SUCC's bunny hop and air strafing give the numbers Source's formulas predict, so later work (player.gd, techs, tuning) can't silently change them. It adds no game code. It builds on the movement test rig from #8 (`tests/helpers/movement_rig.gd`); **#8 must be merged to main before this starts.**

Approach (chosen): **literal expected numbers**, like #8. The expected values were worked out offline by stepping SUCC's per-tick formulas at 128 Hz (script in the appendix) and are written into the tests as constants. The tests use frozen test configs, so retuning `src/player/player_config.tres` never breaks them.

Facts from SUCC this plan relies on (`addons/SUCC/scripts/succ.gd`, read-only), on top of the ones listed in `workflow/plans/008-ground-jump-tests.md`:
- Jump input (`:256–272`): buffered = `enable_bhop` (`:43`, an @export on the player root) **and** `config.bhop_buffered_jump` (`:257`). Buffered: `wish_jump` = jump held (`:264`), so holding jump re-jumps on the first `FLOOR` tick after landing. Not buffered: `wish_jump` = jump held this tick and not last tick, so only a fresh press jumps. A press on an air tick is lost: the jump branch only runs on `FLOOR` (`:406–416`).
- Landing: the `landed` tick starts in the air (air acceleration, no friction) and ends on `FLOOR` (`:538–539`). The next tick is the first `FLOOR` tick: it jumps if `wish_jump`, else friction + ground acceleration (`:414–422`). So a buffered hop has **0 ground ticks**.
- The jump tick runs `_jump` then `_air_accelerate` with that tick's wish (`:414–416`). So one hop gets air acceleration on 86 ticks with T: the `jumped` tick through the `landed` tick (airtime 85 ticks, from #8).
- Wish direction (`:274–276`): `Vector3(move.x, 0, move.y).normalized() × wish_speed`, rotated by the player's yaw around `Vector3.UP`. `wish_speed` = max_speed (10.16 m/s with T).
- `_air_accelerate` (`:455–476`), flat ground (no ramp): `p` = horizontal velocity · wish_dir; `max_accel` = max_air_speed − p; if ≤ 0, nothing; else adds `min(air_acceleration × wish_speed × dt, max_accel)` along wish_dir. Write `a` = air_acceleration × max_speed × dt (the per-tick push) and `cap` = max_air_speed. With T: a = 7.9375 m/s, cap = 0.762 m/s (30 u/s).
- `_friction` (`:425–434`): above stop_speed (4 m/s), one ground tick multiplies horizontal speed by (1 − friction × dt) = 0.96875 with T. Ground acceleration then adds nothing when the speed along the wish is already ≥ max_speed (`:444–447`), or when no key is held.

## Behaviour
All numbers are at 128 ticks/s (dt = 1/128 s). "Speed" means horizontal speed (x/z) in u/s (m/s × 39.37). T = the test config from #8; A = the air config (see Sliders). "Top speed" = 400 u/s, reached by holding W on the ground (the run-up, 64 ticks, see #8).

**Perfect strafe** (used below): every tick, only A or D is held (move x = −1 or +1), and yaw is set so the wish direction is at the optimal angle θ to the horizontal velocity, on the held key's side (D to the right of the velocity, A to the left). θ = 90° when a ≥ cap; otherwise cos θ = (cap − a) / speed. With T: θ = 90°, and the velocity turns 4.29° per tick at top speed (549°/s). With A: θ = 87.94° at top speed. In a chain, the side switches every hop (D on hop 1, A on hop 2, …).

Bhop:
1. **Bhop chain keeps speed (T).** From top speed, holding W + jump: the player hops again on the first floor tick after every landing (0 ground ticks), one hop every 86 ticks, and speed stays 400 u/s on every tick for 5 hops.
2. **W in the air adds nothing (T).** Behaviour 1 holds W through every air tick and speed never goes above 400 u/s.
3. **No buffer.** With `bhop_buffered_jump` off (and, separately, with `enable_bhop` off):
   - (a) Holding W + jump from top speed gives exactly one jump. After landing, the player stays on the floor.
   - (b) A jump press that starts on the `landed` tick (1 tick before the first floor tick) and is held gives no second jump.
   - (c) A jump press on the first floor tick after landing jumps on that tick, with no speed loss (400 u/s).
4. **Late jump above top speed costs speed (T).** After one perfect strafe hop lands at 487.2 u/s, 4 ground ticks with no keys give 472.0, 457.3, 443.0, 429.1 u/s (× 0.96875 per tick). A jump on the 5th tick keeps 429.1 u/s.
5. **Late jump at top speed costs nothing (T).** Holding W, a hop that spends 4 ground ticks before the next jump keeps 400 u/s on every tick.

Air strafe:
6. **One perfect strafe hop.** From top speed, a perfect strafe hop (jump on the first tick) lands at 487.2 u/s (T) or 468.6 u/s (A). Speed goes up on every tick from the `jumped` tick to the `landed` tick.
7. **Five perfect strafe hops (T).** Holding jump with perfect strafe (side switching each hop), the five landings are at 487.2, 561.1, 626.3, 685.3, 739.6 u/s, with 0 ground ticks between hops.
8. **Strafing without turning gains almost nothing (T).** Jump from top speed with W, then hold only D with yaw unchanged: speed is 401.1 u/s after the first D tick and never goes above 402.1 u/s before landing.
9. **Air brake (T).** Jump from top speed with W, then hold only S: speed is 87.5 u/s after 1 tick (still moving forward) and 30.0 u/s moving backward after 2 ticks, and stays 30.0 u/s on the 3rd tick.
10. **Report.** The report from #8 (shipped config `player_config.tres`, no asserts) gets five more lines, measured the same way as the behaviours above:
    ```
    hop period       86 ticks
    strafe 1 hop     487 u/s
    strafe 5 hops    740 u/s
    strafe turn      549 deg/s at top speed
    air brake        2 ticks
    ```
    (Today's values shown. They change when the config is retuned; that's the point.)

Tolerances for every assert (same as #8): speeds ±1 u/s, ticks ±1.

## Files to touch
New:
- `tests/helpers/perfect_strafer.gd`: `class_name PerfectStrafer extends RefCounted`. Static helpers only.
  - `static func optimal_angle(config: SUCCConfig, speed: float, dt: float) -> float`: θ in radians, as defined in Behaviour (a = `config.air_acceleration × config.max_speed × dt`, cap = `config.max_air_speed`). Return PI/2 when a ≥ cap. Otherwise `acos(clampf((cap − a) / speed, -1.0, 1.0))`.
  - `static func input(player: SUCC, side: int, jump: bool) -> SUCCInput`: side +1 = D (`move = Vector2(1, 0)`), −1 = A (`Vector2(-1, 0)`). Takes the player's horizontal velocity, turns its direction by θ toward the side (right for D, left for A; dt = `1.0 / Engine.physics_ticks_per_second`), and sets `yaw` so SUCC's wish direction (`Vector3(move.x, 0, move.y).rotated(Vector3.UP, yaw)`, `succ.gd:274–276`) points that way. `pitch` 0, `jump` as given, crouch and sprint false. If horizontal speed is below 0.001 m/s, it keeps the player's current yaw.
- `tests/movement/test_perfect_strafer.gd`: unit tests of the helper (see How to test).
- `tests/movement/test_bhop_numbers.gd`: behaviours 1–5.
- `tests/movement/test_strafe_numbers.gd`: behaviours 6–9.

Changed:
- `tests/helpers/movement_rig.gd`:
  - **Controlled steps.** `Step` gets `var controller: Callable` and `static func controlled(step_controller: Callable, step_ticks: int) -> Step`. `Step.new(input, ticks)` keeps working as before. For a controlled step, before each of its ticks the rig calls `controller.call(self, step_tick)` (`step_tick` = 0 for the step's first tick) and uses the returned `SUCCInput` for that tick. The call happens where the rig would switch `command` today: in `play()` for the play's first tick, else in `_physics_process` after recording the previous tick's sample. So the controller sees the state after the previous tick, including `trace`.
  - `trace[i].input` records the input tick i actually used (for a controlled step, the controller's result).
  - `static func air_config() -> SUCCConfig`: `test_config()` with `air_acceleration = 5.0`.
- `tests/movement/test_movement_rig.gd`: add tests for controlled steps and `air_config()` (see How to test). Existing tests stay unchanged.
- `tests/movement/test_movement_report.gd`: add the five lines of behaviour 10.

Not touched: `addons/`, `src/`, `project.godot`, `player_config.tres`, `workflow/tools/check.ps1`.

## Sliders
No gameplay value changes, so no new sliders. The tests use these frozen configs (not feel settings):

| Value | T (test config, from #8) | A (air config) |
|-------|-----|-----|
| air_acceleration | 100.0 | **5.0** |
| everything else | see the table in `workflow/plans/008-ground-jump-tests.md` | same as T |

The tests also switch two existing settings off, one at a time: `bhop_buffered_jump` (config) and `enable_bhop` (player root @export).

## How to test
The new and changed test files are the deliverable. Shorthand, as in #8: `Step(forward, 64)` = `MovementRig.Step.new(input, 64)` with `input.move = Vector2(0, -1)`; "forward+jump" adds `jump = true`; "right" = `Vector2(1, 0)`, "back" = `Vector2(0, 1)`; "idle" = an empty `SUCCInput`. Yaw is 0 unless a controller sets it. Every play starts after `spawn` + `settle`. `L` = the index of a `landed` sample. Every Behaviour line has a test:

- `test_movement_rig.gd` (added tests)
  - `air_config()` equals `test_config()` except `air_acceleration` 5.0.
  - A controlled step of 5 ticks whose controller returns forward and records each `step_tick` it gets: it is called with 0, 1, 2, 3, 4 in that order, and `trace[1..5].input` are the inputs it returned.
  - `play([Step(forward, 3), Step.controlled(c, 2)])`: the controller's first call happens after tick 3, and it sees `rig.trace.size() == 4`.
- `test_perfect_strafer.gd`
  - `optimal_angle(T, 10.16, 1/128)` = 90° (±0.01°). `optimal_angle(A, 10.16, 1/128)` = 87.94° (±0.01°).
  - With the player's velocity (0, 0, −10.16): for side +1, the wish direction from the returned input (`Vector3(move.x, 0, move.y).rotated(Vector3.UP, yaw)`) is at 90° to the velocity and to its right (`velocity.cross(wish).y < 0`). For side −1, at 90° and to its left (`> 0`). With config A, at 87.94°.
  - `jump` in the input matches the argument; `pitch` is 0.
- `test_bhop_numbers.gd` (T unless stated)
  - (1, 2) `Step(forward, 64)`, `Step(forward+jump, 430)`, `Step(forward, 20)`: at least 5 `jumped` samples during the held step, the first at 65; consecutive `jumped` samples are 86 ±1 apart; every `landed` sample during the held step is followed directly by a `jumped` sample; every sample from 64 to the end of the held step has speed 400 ±1 u/s.
  - (3) Each of these runs twice: once with `test_config()` and `bhop_buffered_jump = false`, once with `test_config()` and `player.enable_bhop = false` set after `spawn`.
    - (3a) `Step(forward, 64)`, `Step(forward+jump, 200)`: exactly one `jumped` sample (65); one `landed` sample at 150 ±1; every sample after it is `FLOOR`.
    - (3b) Play 1: `Step(forward, 64)`, `Step(forward+jump, 1)`, `Step(forward, 120)`; L = its `landed` index. Play 2: `Step(forward, 64)`, `Step(forward+jump, 1)`, `Step(forward, L − 66)`, `Step(forward+jump, 60)`. In play 2, `trace[L].landed` is true and its input has jump held (the press starts on the `landed` tick); exactly one `jumped` sample; every sample after L is `FLOOR`.
    - (3c) Play 1 as in (3b). Play 2: `Step(forward, 64)`, `Step(forward+jump, 1)`, `Step(forward, L − 65)`, `Step(forward+jump, 1)`, `Step(forward, 40)`. In play 2, `trace[L].landed` and `trace[L + 1].jumped`; `trace[L + 1]` speed 400 ±1 u/s.
    - Play 2 starts with the same 64-tick run-up as play 1, so idle ticks the rig may run between plays don't matter.
  - (4) `Step(forward, 64)`, then `Step.controlled(c, 120)` where c returns `PerfectStrafer.input(player, 1, step_tick == 0)` until a `landed` sample appears in this step; after that, idle for the 4 ticks after L, idle + jump on tick L + 5, then idle. Asserts: `trace[L]` 487.2; `trace[L + 1..L + 4]` 472.0, 457.3, 443.0, 429.1; `trace[L + 5].jumped` with 429.1 (all ±1 u/s).
  - (5) `Step(forward, 64)`, `Step(forward+jump, 1)`, `Step(forward, 89)`, `Step(forward+jump, 1)`, `Step(forward, 20)`: two `jumped` samples; 4 ±1 ground samples between the `landed` sample and the second `jumped` one; every sample from 64 to the end has speed 400 ±1 u/s.
- `test_strafe_numbers.gd`
  - (6) T: `Step(forward, 64)`, `Step.controlled(c, 100)` where c returns `PerfectStrafer.input(player, 1, step_tick == 0)` until a `landed` sample appears in this step, then idle. `trace[65].jumped`; L = 150 ±1; `trace[L]` 487.2 ±1 u/s; every sample from 65 to L is faster than the one before.
  - (6) A: same play with `air_config()`: `trace[L]` 468.6 ±1 u/s.
  - (7) T: `Step(forward, 64)`, `Step.controlled(c, 440)` where c holds jump and returns `PerfectStrafer.input(player, side, true)`, side = +1 while the number of `landed` samples so far in this step is even, −1 while odd; after the 5th `landed` sample, idle. Asserts: 5 `landed` samples with speeds 487.2, 561.1, 626.3, 685.3, 739.6 (±1 u/s each); each of the first 4 is followed directly by a `jumped` sample.
  - (8) T: `Step(forward, 64)`, `Step(forward+jump, 1)`, `Step(right, 90)`: `trace[66]` 401.1 ±1 u/s; max speed over samples 66…L ≤ 402.1 u/s.
  - (9) T: `Step(forward, 64)`, `Step(forward+jump, 1)`, `Step(back, 3)`, `Step(idle, 10)`: `trace[66]` 87.5 ±1 u/s with `velocity.z < 0` (still forward); `trace[67]` 30.0 ±1 u/s with `velocity.z > 0` (backward); `trace[68]` 30.0 ±1 u/s.
- `test_movement_report.gd` (behaviour 10, shipped config, run-up of 128 ticks so a retuned config still reaches top speed):
  - hop period: ticks between the first two `jumped` samples of a held forward+jump chain.
  - strafe 1 hop / 5 hops: speed at the 1st and 5th `landed` sample of the play in (7).
  - strafe turn: the angle in degrees between the horizontal velocity at the last run-up sample and at the first strafe sample of that play, × ticks per second.
  - air brake: ticks of S (after a W jump from top speed) until the velocity along the run direction is ≤ 0.
  - Prints the lines with `gut.p()` after #8's block; still `pass_test()`, no asserts.

**If a number is out of tolerance:** stop and report measured vs expected. Don't widen a tolerance, change an expected value, or touch `addons/`. The user decides: an accepted SUCC quirk (the reason is then written into this plan) or a bug issue.

Proof: paste the GUT output of the new and changed test files, including the printed report block. No screenshot: this feature has nothing visual.

`workflow/tools/check.ps1` passes. Expect it to take roughly 40 s longer: the tests run about 5,000 physics ticks in real time (speeding up time would change dt and the numbers).

## Out of scope
- Surf numbers (#9).
- Counter-strafe (#6) and crouch-jump apex (#7).
- Strafe gain at human (non-perfect) turn rates, W+A/W+D strafing, and strafing with a held W.
- The `max_velocity` clamp (`enforce_max_velocity`).
- A reference model that predicts numbers for any config (approach B, not chosen; a candidate when feature 6 needs predicted numbers).
- The debug overlay's bhop stats (`BhopTracker`, #5). These tests check SUCC, not the overlay.
- Faster test runs (for example GUT with `--fixed-fps 128` in `check.ps1`). Separate tools change if wanted.
- Changing SUCC, `player_config.tres` or any gameplay value. If a test exposes a SUCC bug, it becomes its own issue.

## Appendix: how the expected numbers were computed
Python, stepping SUCC's air formulas per tick at dt = 1/128 (T; A uses aa = 5.0). Airtime 85 ticks comes from #8, so one hop = 86 air-acceleration ticks.

```python
import math
dt = 1/128; U = 39.37
w, aa, cap, f = 10.16, 100.0, 0.762, 4.0

def air_acc(v, wish):                     # _air_accelerate, flat ground
    p = v[0]*wish[0] + v[1]*wish[1]
    m = cap - p
    if m <= 0: return v
    acc = min(aa * w * dt, m)
    return (v[0] + acc*wish[0], v[1] + acc*wish[1])

def theta(speed):                         # optimal wish angle
    a = aa * w * dt
    return math.pi/2 if a >= cap else math.acos(min(1.0, (cap - a) / speed))

def rot(v, ang):                          # rotate (x, z) about UP
    return (v[0]*math.cos(ang) + v[1]*math.sin(ang),
            -v[0]*math.sin(ang) + v[1]*math.cos(ang))

def strafe_tick(v, side):                 # side +1 = D (right), -1 = A (left)
    s = math.hypot(*v); n = (v[0]/s, v[1]/s)
    return air_acc(v, rot(n, -side * theta(s)))

v = (0.0, -w); side = 1                   # 5 perfect hops from 400 u/s
for hop in range(5):
    for t in range(86): v = strafe_tick(v, side)
    print(hop + 1, round(math.hypot(*v) * U, 1)); side = -side
# T: 487.2 561.1 626.3 685.3 739.6    A: 468.6 528.4 582.1 631.3 676.9
# turn on the first tick at 400 u/s: T 4.289 deg (549 deg/s), A 2.232 deg

# late jump: 487.24 * (1 - f*dt)**k  ->  472.0 457.3 443.0 429.1 (k = 1..4)
# no turn (D, yaw 0): air_acc((0, -w), (1, 0)) -> 401.12, then p = cap -> no more gain
# air brake (S): (0,-w) -> z = -2.2225 (87.5 u/s) -> z = +0.762 (30.0 u/s backward)
```
