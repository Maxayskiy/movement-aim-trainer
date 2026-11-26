# Hitscan rifle
Issue: #16
Status: approved

Feature 1 of roadmap phase 2 (aim base). The player gets Rifle1: hold left mouse to fire perfect hitscan shots at 4 shots per second (sps). The rifle script also supports tap-only fire (`full_auto` off), which Rifle2 (#26) uses later. Hit targets get a `take_hit(damage)` call; dummies (#17), feedback (#18) and stats (#20) build on it. The game is offline and single-player, so there is no networking or lag compensation.

Branch `feat/016-hitscan-rifle` from main.

Approach (chosen): **fire on the 128 Hz physics tick, with the click's aim saved.** Shots only fire on physics ticks. A click is latched as it arrives, together with the aim at that moment: the view direction and the on-screen camera position. The next tick casts the ray from those saved values. Later shots of a held trigger follow the tick schedule and aim from the physics eye with the current view direction.

Facts this plan relies on:
- Physics runs at 128 ticks per second (`project.godot`, `physics/common/physics_ticks_per_second`). Every collision body is on the default layer 1.
- SUCC turns the view as soon as each mouse-motion event arrives. Body yaw and `CameraRig.pitch` change inside `_unhandled_input` (`addons/SUCC/scripts/succ.gd:240-244`, `addons/SUCC/scripts/succ_camera.gd:102-135`). So at the moment a click is read, yaw and pitch include all earlier motion.
- SUCC places the camera once per render frame, at a point interpolated between the last two physics positions (`succ.gd:780-791`, `succ_camera.gd:41-46`). Between frames, `Camera3D.global_position` is therefore the eye position the player last saw.
- When the mouse is not captured, SUCC captures it on any mouse-button press (`succ.gd:246-250`). Esc frees it (`succ.gd:251-253`).
- A child's `_physics_process` runs after its parent's in the same tick. A rifle under the Player root therefore sees the position after SUCC's move.
- `tests/helpers/movement_rig.gd` spawns the real `player.tscn` and sets `SUCC.command` every tick. A command overwrites yaw and pitch on every tick (`succ.gd:288-292`). Tests that turn the view with `CameraRig.turn()` must set `player.command = null` first.
- Probe of Godot 4.7.2 headless in a scratch project (2026-11-26):
  - Setting `Input.mouse_mode` to captured has no effect: it stays visible. So in headless tests SUCC ignores mouse motion (`succ_camera.gd:105`), and a "fire only while captured" check would block every shot.
  - Godot hands parsed events out one at a time and in order: `_input` on all nodes, then `_unhandled_input`, then the next event.
  - With `use_accumulated_input` on, only motion events that come back to back merge. A button event splits them: the sequence M1 M2 press M3 M4 release M5 arrived as M1+M2, press, M3+M4, release, M5.
- The existing `+` crosshair is a Label in the course's HUD (`levels/movement_course/movement_course.tscn:827`), centred by a 32 × 28 px box.

## Behaviour
1. **Fire input.** A new Input Map action, `fire`, is bound to the left mouse button. The rifle reads it as events in `_input`: a press sets "held" and latches a click, and a release clears "held". It never polls the input.
2. **Fire only while captured.** A press counts only while the mouse is captured. `_input` runs before SUCC's `_unhandled_input`, so the click that recaptures the mouse after Esc still sees a free mouse and does not fire. If the mouse stops being captured while fire is held (Esc), the next tick clears "held" and any latched click.
3. **Click latch and saved aim.** The first press since the last tick is latched. At that moment the rifle saves:
   - the aim direction: from body yaw and `CameraRig.pitch`, without roll;
   - the on-screen eye: `Camera3D.global_position`.

   A press and release between two ticks still counts as one click. Later presses before the same tick don't replace the saved aim.
4. **Click shot.** On the next physics tick, if the cooldown allows a shot, the rifle casts the ray from the saved eye along the saved direction. If the cooldown blocks it, the click and its saved aim are dropped and nothing fires.
5. **Held shots.** With `full_auto` on and fire still held, every later shot fires on the tick schedule. It aims from the **physics eye** (`player.global_position + UP × CameraRig.view_height`) along the current yaw and pitch. If a click was dropped by the cooldown but fire stays held, the first ready tick fires a held shot.
6. **Tap only.** With `full_auto` off, only click shots fire. Holding fires once. A click during the cooldown does nothing; there is no buffer.
7. **Cadence** (pure class `FireTimer`).
   - The interval is `ticks_per_second ÷ shots_per_second` ticks, a float.
   - A click shot starts a new schedule from the current tick: next due = this tick + interval.
   - A held shot schedules from when the previous shot was *due*: next due += interval. The fraction carries over, so 10 sps fires with gaps of 12 and 13 ticks and exactly 10 shots per 128 ticks.
   - A shot fires on the first tick ≥ next due, at most one per tick.
   - A guard keeps next due above the current tick, so a long idle never causes a catch-up burst.
   - At 4 sps the shots are exactly 32 ticks apart.
8. **Rate limit.** The fire rate is capped at the tick rate, 128 sps. A higher value is clamped to 128 with a `push_warning`, and a value under 1 is clamped to 1 the same way. Damage uses the clamped rate.
9. **Perfect shots.** No spread, recoil, movement inaccuracy, ammo or reload. Shooting doesn't change movement.
10. **The ray.**
    - The ray is 10 km long (constant `RAY_LENGTH_M`), which stands in for infinite range: it is longer than any map, and there is no damage falloff.
    - It hits every solid body on any layer, ignores areas, and excludes the player's own body.
11. **One aim function.** `aim(origin_source)` returns the ray origin and direction together. `origin_source` is `VIEW` (on-screen eye, used when a click is saved) or `PHYSICS_EYE` (held shots). Changing where shots come from means editing only this function.
12. **Hit report.**
    - Damage per shot = `dps ÷ shots_per_second` (float, no rounding). With the default dps of 100 at 4 sps, that is 25.0.
    - If the hit collider has `take_hit`, the rifle calls `take_hit(damage)` on it.
    - Every shot emits `shot_fired(origin, direction, hit_position, collider)`. On a miss, `collider` is null and `hit_position` is the far end of the ray.
13. **Debug hit markers.**
    - While the F3 debug panel is visible, each hit leaves a red, unshaded sphere 8 cm across at the hit point. It lasts 2 s, with at most 64 at once (the oldest is removed first).
    - Misses leave nothing, and there is no tracer.
    - Hiding the panel hides the markers.
    - Respawn (R or kill height) clears them.
14. **Crosshair.** The existing `+` stays. Check that it sits on the exact screen centre, which is where shots go. If it is off, change only that label's offsets.

## Files to touch
New:
- `src/weapons/fire_timer.gd`: `class_name FireTimer extends RefCounted`. Pure cadence logic (behaviour 7–8), with no scene access.
  - Properties: `ticks_per_second`, `shots_per_second` (its setter clamps), `full_auto`.
  - `tick(t: int, pressed: bool, held: bool) -> Result`, where `Result` is `NONE`, `CLICK_SHOT`, `HELD_SHOT` or `CLICK_DROPPED`.
- `src/weapons/rifle_config.gd`: `class_name RifleConfig extends Resource` with `shots_per_second`, `full_auto` and `dps`. Rifle2 (#26) reuses it later.
- `src/weapons/rifle1_config.tres`: 4 sps, `full_auto` on, dps 100.
- `src/weapons/rifle.gd`: `class_name Rifle extends Node`, a child of the Player root.
  - Contents: the click latch in `_input`, `_physics_process`, `aim()`, the ray query, `damage()`, the `take_hit` call and the `shot_fired` signal.
  - It copies the config into its `FireTimer` every tick, so changes made while the game runs apply at once.
  - Its tick counter is `Engine.get_physics_frames()`.
  - `@export var config: RifleConfig`.
  - `@export var require_captured_mouse: bool = true`. Headless tests set it to false, because headless Godot can't capture the mouse.
- `src/debug/hit_markers.gd`: `class_name HitMarkers extends Node3D`, `top_level`, a child of the Player root (behaviour 13).
  - It listens to the sibling `Rifle.shot_fired` and `Respawn.respawned`, and reads the sibling `DebugOverlay.panel_visible` every frame.

Changed:
- `src/player/player.tscn`: add a `Rifle` node (config = `rifle1_config.tres`) and a `HitMarkers` node.
- `project.godot`: add the `fire` action on the left mouse button.
- `levels/movement_course/movement_course.tscn`: the `Crosshair` label's offsets, and only if the centre check fails.

Tests (new files; no existing test is edited):
- `tests/unit/test_fire_timer.gd`
- `tests/weapons/test_rifle.gd`
- `tests/weapons/test_rifle_input_order.gd`
- `tests/weapons/test_rifle_scene.gd`
- `tests/debug/test_hit_markers.gd`
- `tests/helpers/hit_target.gd`: a `StaticBody3D` with `take_hit(damage: float)` that records every call.
- `tests/helpers/motion_turner.gd`: a Node whose `_input` turns `player.camera_rig` by each mouse-motion event's `screen_relative`, through `CameraRig.turn()`. It stands in for SUCC's own handler, which ignores motion in headless runs.

## Sliders
| Name | Where | Default | Range | Notes |
|---|---|---|---|---|
| `shots_per_second` | `RifleConfig` | 4.0 (Rifle1) | 1–20, step 0.5 | Player slider. Hard cap 128 (tick rate), clamped with a warning. |
| `full_auto` | `RifleConfig` | on (Rifle1) | on/off | Off = tap only (Rifle2 in #26). |
| `dps` | `RifleConfig` | 100.0 | none | Not a player slider. An `@export` so it isn't hard-coded; the real value is set at balancing. |

Debug-only exports on `HitMarkers` (not feel values): `marker_diameter` 0.08 m, `marker_lifetime` 2.0 s, `max_markers` 64, `marker_color` red.

No range slider: range is infinite. `RAY_LENGTH_M` (10 km) is a constant, not a feel value.

## How to test
Run `powershell -NoProfile -ExecutionPolicy Bypass -File workflow/tools/check.ps1`. It must pass. Positions are checked to ±1 mm, damage to ±0.001, and ticks exactly.

**`tests/unit/test_fire_timer.gd`** (pure, ticks counted by hand; `ticks_per_second` 128):
- 4 sps, held from tick 0 for 128 ticks: shots at 0, 32, 64 and 96. The first is `CLICK_SHOT`, the rest `HELD_SHOT`. (behaviour 7)
- 10 sps, held for 128 ticks: shots at 0, 13, 26, 39, 52, 64, 77, 90, 103 and 116. Held for 1280 ticks: exactly 100 shots. (7)
- Idle restart at 4 sps: press at 0 and release at 1, then press and hold at 50. Shots at 0, 50 and 82, with no extra shot at 50. (7)
- Long idle at 10 sps: press at 0 and release, then press and hold at 1000. Shots at 1000, 1013, 1026: one shot per tick at most, no burst. (7)
- Cooldown, `full_auto` off, 10 sps: a press at 0 gives `CLICK_SHOT`; a press at 5 gives `CLICK_DROPPED`; a press at 13 gives `CLICK_SHOT`. (6)
- `full_auto` off, held for 128 ticks: one shot. (6)
- `full_auto` on, 4 sps: press at 0 and release, then press at 10 and keep holding. Tick 10 gives `CLICK_DROPPED`, then `HELD_SHOT` at 32 and 64. (5)
- Rate cap: 200 sps is clamped to 128 (one shot every tick while held, warning raised). 128 sps fires every tick. 0 sps is clamped to 1. (8)

**`tests/weapons/test_rifle.gd`** (MovementRig, real `fire` events through `Input.parse_input_event` + `Input.flush_buffered_events()`, `require_captured_mouse` false). Setup: the player at the origin facing −Z, and a 10 × 10 × 1 m wall whose near face is at z = −20 (a `hit_target`). The expected eye height is read from `camera_rig.view_height`.
- Hold for 128 ticks: 4 `shot_fired`, 32 ticks apart. Each hits the wall at (0, eye, −20). `take_hit` gets 25.0 four times. (1, 7, 12)
- **Saved aim:** press and release (yaw 0), then set the rig command's yaw to 30° before the next tick. SUCC applies the 30° in that tick before the rifle runs, yet the shot still hits at x = 0. (3, 4)
- **Saved camera position:** in the same frame, set `player.camera_rig.global_position` to the physics eye + (0.5, 0, 0), then inject and flush the press. No `_process` runs in between, so SUCC doesn't move the camera back. The shot's origin is the set position, and it hits at x = 0.5. If SUCC moves the camera before the click is read, stop and report. (3, 11)
- **Held shots use the tick aim:** hold fire, and after the first shot set the command yaw to 10°. The second shot's origin is the physics eye at that tick, and it hits where the 10° ray from there meets the wall. (5)
- **Press and release between ticks:** exactly one shot, then none for the next 100 ticks. (3)
- **Dropped tap leaves nothing behind** (4 sps): a click at yaw 0 fires. A click 10 ticks later at yaw 20° does not fire. A click 40 ticks after the first, at yaw −20°, fires along −20°, not 20°. (4)
- `full_auto` off, held for 128 ticks: one shot. (6)
- Straight down (pitch −89°): hits the floor below the feet, and the collider is the floor, not the player. (10)
- An `Area3D` between the player and the wall: the shot still hits the wall. (10)
- A wall 5000 m away: hit. A shot at the empty sky (pitch +45°): `collider` is null and `hit_position` is 10 km along the ray. (10, 12)
- `require_captured_mouse` true in headless (the mouse can't be captured): a click fires nothing. (2)

**`tests/weapons/test_rifle_input_order.gd`** (real events, no `SUCC.command`, `motion_turner` turns the view):
- Run twice, with `Input.use_accumulated_input` false and then true. In one batch, parse: motion +a, press, motion +b, release, motion +c. Flush, then wait one tick. Expected: exactly one shot, whose direction is the yaw after +a only. (2, 3)
- If the shot uses any of +b or +c, Godot didn't keep the order: stop and report it. Don't work around it. The probe above suggests it will pass.

**`tests/weapons/test_rifle_scene.gd`:**
- `player.tscn` has a `Rifle` child whose config is `rifle1_config.tres` (4 sps, `full_auto` on, dps 100), and a `HitMarkers` child.
- The `fire` action exists and is bound to the left mouse button.

**`tests/debug/test_hit_markers.gd`** (rifle and walls as above, `marker_lifetime` set short):
- A hit with the panel visible gives one marker at the hit point.
- A hit with the panel hidden gives none.
- A miss gives none.
- The 65th marker removes the oldest.
- A marker is gone after its lifetime.
- Respawn clears all markers.

**Screenshot proof** (game running, `editor_screenshot` with `source: "game"`):
- F3 on. Hold fire at a lane wall for about 2 s while strafing: the red markers show.
- Zoom on the screen centre: the `+` glyph's centre pixel is at (960, 540) at 1920 × 1080, with a marker under it. If it isn't, fix the label offsets (behaviour 14) and screenshot again.

**Playtest** (by the user, after the merge):
- Esc, then click to recapture: no shot.
- Esc while holding fire: firing stops.
- A single click feels instant.
- Holding fire while bhopping: shots go where the `+` is.

## Out of scope
- Rifle2 and weapon switching (#26).
- Shot sound, muzzle flash, view model (#25).
- Hit marker, hitsound, killsound (#18).
- Target dummies (#17, #19).
- Stats and score (#20).
- Crosshair settings (#24).
- Raw input, sensitivity, FOV (#22).
- Laser (#23).
- Tuning panel UI (#15).
- Spread, recoil, ammo, reload, falloff: the rifle never has them.
- Networking and lag compensation: the game is offline and single-player.
- Interpolated origin for held shots: held shots use the physics eye by design.
