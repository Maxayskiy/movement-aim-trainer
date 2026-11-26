# Player sticks on 45–50° slopes
Issue: #13
Status: approved

Bug found by #12 (behaviour 6b). A player resting on a slope between 45° and 50° is stuck instead of sliding. This fix moves the walkable limit to Source's value, 45.57°, and makes Godot's floor limit end exactly there.

**Start after #12 is merged.** This builds on #12's rig changes (`add_ramp`, `with_floor`, the pinned angles). Branch `fix/013-slope-stick` from main.

Approach (chosen): **values only.** Set both angles on the player root in `src/player/player.tscn`, and change #12's rig pins to match. Linking the two into one slider is left to feature 6 (tuning panel).

Facts this plan relies on:
- SUCC (`addons/SUCC/scripts/succ.gd`, read-only): on Godot floor, the type is RAMP when the floor angle ≥ `ramp_angle_threshold` (`:52`, `:812–820`). Off Godot floor, any contact with normal y > 0.01 is RAMP (`:828–841`). Both are player-root @exports in radians, shown in degrees. `max_floor_angle` (`:55`) sets Godot's `floor_max_angle`. It also caps step-up landings (`:650`) and step-down snaps (`:682`): a surface steeper than `max_floor_angle` is refused. With 45° both now refuse what is a ramp anyway.
- Godot (`character_body_3d.cpp`): a contact counts as floor up to `floor_max_angle` + 0.01 rad (0.573°). On floor contact it removes vertical velocity every tick, and `floor_stop_on_slope` zeroes a resting body's velocity. So a surface that is Godot floor but SUCC RAMP holds a resting player: gravity can never build up.
- Source: ground means the surface normal's up component is ≥ 0.7, so the walkable limit is acos(0.7) = 45.573°.
- Probe (2026-11-25, headless, config T, player resting on the face, 160 ticks):

| Slope | Today: max 50°, threshold 45° | max 45°, threshold 45° | **Chosen: max 45°, threshold 45.57°** |
|---|---|---|---|
| 44.0° | holds, FLOOR | holds, FLOOR | holds, FLOOR |
| 45.3° | 0.000 m, RAMP (stuck) | 0.000 m, RAMP (stuck) | holds, FLOOR |
| 45.8° | 0.000 m, RAMP (stuck) | slides 11.3 m | slides 11.3 m |
| 46.0° | 0.000 m, RAMP (stuck) | slides 11.3 m | slides 11.3 m, 18.2 m/s |

## Behaviour
1. **Steeper than 45.57° slides.** A player resting on a 46° slope (scene values, no input) is on RAMP and slides more than 1 m downhill in 128 ticks.
2. **Up to 45.57° holds.** A player resting on a 44° or a 45.3° slope (scene values, no input) is on FLOOR and moves less than 1 cm in 128 ticks.
3. **Shipped values.** The player root in `src/player/player.tscn` has `ramp_angle_threshold` = acos(0.7) (45.573°) and `max_floor_angle` = 45°, so the two limits meet: 45° + 0.573° = 45.573°.
4. **Tests pin the same values.** The rig pins `ramp_angle_threshold` = acos(0.7) and `max_floor_angle` = 45°, so #12's tests run on the shipped limits.

## Files to touch
- `src/player/player.tscn` (changed): root sets `ramp_angle_threshold = 0.7953988` (rad, = acos(0.7)) and `max_floor_angle = 0.7853982` (rad, = 45°). No script change.
- `tests/helpers/movement_rig.gd` (changed):
  - The pinned angle constants from #12 change to acos(0.7) and 45°. The comment on them points to this plan and #13 instead of plan 012's Decision.
  - `spawn()` gains `pin_angles: bool = true`. When false, the player keeps the angles from `player.tscn`. Existing callers don't change.
- `tests/movement/test_movement_rig.gd` (changed): #12's assertion on the pinned angles changes to acos(0.7) and 45°. **This is a planned spec change, not an edit to make a test pass.** It also gains a test that `pin_angles = false` keeps the scene's values.
- `tests/movement/test_player_scene.gd` (changed): adds a test for behaviour 3.
- `tests/movement/test_slope_stick.gd` (new): behaviours 1–2, with `pin_angles = false` so it tests the shipped scene.

## Sliders
No new sliders. Two existing player-root @exports get new defaults:

| Name | Old default | New default | Range |
|---|---|---|---|
| `ramp_angle_threshold` | 45° | 45.573° (acos 0.7) | 0–89° |
| `max_floor_angle` | 50° | 45° | 0–89° |

Rule they must keep: `max_floor_angle` + 0.573° = `ramp_angle_threshold`. Otherwise a stuck band comes back. Feature 6 exposes them as one linked "walkable slope" slider.

## How to test
1. **Reproduce first.** Write `test_slope_stick.gd` before changing `player.tscn`, and run it alone: `& $godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/movement/test_slope_stick.gd -gexit`. Show the failing output: 46° moves 0.000 m, and 45.3° is RAMP instead of FLOOR. Then make the fix.
2. `test_slope_stick.gd`: rig floor off (`with_floor` false), `pin_angles` false, config T. For each slope (44°, 45.3°, 46°): `add_ramp` 10 m along the slope. Spawn the player above the middle of the face with the hull's uphill bottom edge 5 cm clear (feet 0.4065 · tan(angle) + 0.05 m above the face). No input for 160 ticks. Measure from the first tick that isn't NONE.
   - 46°: RAMP, moved more than 1 m.
   - 44° and 45.3°: FLOOR on every tick after landing, moved less than 1 cm.
3. `test_player_scene.gd`: instantiate `player.tscn`. `ramp_angle_threshold` = acos(0.7) ±0.0001 rad, `max_floor_angle` = deg_to_rad(45) ±0.0001 rad.
4. `test_movement_rig.gd`: `spawn()` pins acos(0.7) and 45°. `spawn(…, pin_angles = false)` keeps the scene's values.
5. #12's tests (`test_steps_slopes.gd` 6a/6b, ramp edges at 15°/30°) pass unchanged with the new pins.
6. `workflow/tools/check.ps1` passes.
7. Proof: the failing output from step 1, then the passing output. No screenshot: nothing visual changes.

Stop-and-report rule (same as #8, #10, #12): if a measurement is out of tolerance after the fix, stop and report measured against expected. Don't change tolerances, expected numbers or `addons/`.

## Out of scope
- Linking the two angles into one slider: feature 6 (tuning panel).
- Moving players on 45.57–50° slopes (surfing them), and surf numbers in general: issue #9.
- Changing SUCC's own defaults in `addons/`.
- The course's slope station (5b). Its 44° and 46° slopes still sit on either side of the new limit.
