# Player base
Issue: #1
Status: approved

First feature of roadmap phase 1 (movement base). It gives us a player of our own, built from SUCC without editing `addons/`, and puts it in the test course. Later phase 1 features: (2) debug overlay, (3) ground/jump number tests, (4) bhop/air-strafe tests, (5) our own grey-box course, (6) in-game tuning panel.

Approach (chosen): **compose around SUCC.** The player scene's root keeps SUCC's own script (`addons/SUCC/scripts/succ.gd`) unchanged. New behaviour lives in small child nodes that read the parent SUCC through its public API. There is no `player.gd` yet. It arrives with the first tech that needs a hook into SUCC's movement loop.

## Behaviour
1. Pressing Play opens the test course with our player in it (first person) instead of SUCC's demo character. The course geometry is unchanged.
2. Movement feels like SUCC's default ("SurfsUp") preset: top ground speed 10.16 m/s, gravity 20.32 m/s², jump apex 1.143 m, air acceleration 100.
3. Bhop (holding jump re-jumps on landing), air strafing and surfing are all on.
4. There is no sprint. Holding Shift does nothing, and speed never goes above the normal top speed because of sprint.
5. Keys (physical keys, so they work on any keyboard layout): W/A/S/D move, Space jumps (no mouse-wheel jump), Left Ctrl crouches, R respawns.
6. Physics runs at 128 ticks per second.
7. Mouse look reads every mouse event, not one merged event per frame (`Input.use_accumulated_input = false`).
8. Pressing R puts the player back where they started the level, facing the start direction, with the view level (pitch 0) and zero velocity.
9. Falling below −30 m respawns the player in the same way. At −29 m nothing happens.
10. The demo level's script, jump sound and HUD (speed meter, preset panel, hint text) are gone. The crosshair stays.
11. Booting the game prints no `SUCC: input action ... not defined` warnings.

## Files to touch
New:
- `src/player/player.tscn`: a copy of `addons/SUCC/scenes/succ_character.tscn` (as SUCC's README says, step 3). Changes from the copy: `config` points to `player_config.tres`, plus two child nodes, `Respawn` (`respawn.gd`) and `InputSetup` (`input_setup.gd`). The root script stays `res://addons/SUCC/scripts/succ.gd`. `enable_bhop` and `enable_surf` stay `true`.
- `src/player/player_config.tres`: a copy of `addons/SUCC/resources/default_config.tres` (a `SUCCConfig`), with one change: `sprint_speed_modifier = 1.0`.
- `src/player/respawn.gd`: `class_name PlayerRespawn extends Node`.
  - `@export var kill_height: float = -30.0`.
  - In `_ready`, it stores the parent SUCC's `global_transform` as the start.
  - `respawn()` sets velocity to zero, calls the parent's `teleport(start)` (`succ.gd:177`, which also resets camera interpolation), and sets `camera_rig.pitch = 0.0`.
  - It calls `respawn()` on the `respawn` action (in `_unhandled_input`), and in `_physics_process` when the parent's `global_position.y < kill_height`.
- `src/player/input_setup.gd`: `class_name PlayerInputSetup extends Node`, with `@export var use_accumulated_input: bool = false`. In `_ready` it sets `Input.use_accumulated_input` from that value. (Godot has no project setting for this.)
- `tests/unit/test_project_setup.gd`, `tests/movement/test_player_scene.gd`, `tests/movement/test_respawn.gd`, `tests/movement/test_course_scene.gd` (see How to test).

Changed:
- `project.godot`:
  - `physics/common/physics_ticks_per_second = 128`.
  - Input Map actions, all with physical keycodes:
    - `forward` W, `back` S, `left` A, `right` D
    - `jump` Space only
    - `crouch` Left Ctrl
    - `respawn` R
    - `sprint` with **no events**: it exists only so SUCC doesn't warn (`succ.gd:1064` warns on missing actions and switches them off).
- `levels/test_course/test_course.tscn`:
  - The `Player` node becomes an instance of `res://src/player/player.tscn`. Keep its transform (8, 1, 24) and the node name `Player`.
  - Remove the root script (`addons/SUCC/demo/test_level.gd`), the `JumpSound` node, and every `UI/HUD` child except `Crosshair`. Remove any ext_resources nothing uses any more.
  - Keep all the geometry, and the `demo.tres` theme the crosshair uses.

Not touched: anything in `addons/`.

## Sliders
`player_config.tres` keeps every `SUCCConfig` @export editable. Defaults are SUCC's `default_config.tres` unless marked. Ranges are what the feature 6 tuning panel should allow.

| Name | Where | Default | Range |
|------|-------|---------|-------|
| gravity | player_config | 20.32 m/s² | 5–40 |
| jump_height | player_config | 1.143 m | 0.3–3.0 |
| bhop_buffered_jump | player_config | true | on/off |
| acceleration | player_config | 7.5 | 1–20 |
| friction | player_config | 4.0 | 0–12 |
| stop_speed | player_config | 4.0 m/s | 0–10 |
| max_speed | player_config | 10.16 m/s | 3–20 |
| air_acceleration | player_config | 100 | 1–1000 |
| max_air_speed | player_config | 0.762 m/s | 0.1–5 |
| max_velocity | player_config | 127.0 m/s | 20–300 |
| enforce_max_velocity | player_config | false | on/off |
| crouch_speed_modifier | player_config | 0.333 | 0.1–1.0 |
| sprint_speed_modifier | player_config | **1.0** (changed from 1.6) | 1.0–3.0 |
| step_height | player_config | 0.45 m | 0–1 |
| mouse_sensitivity | player_config | 3.0 | 0.01–20 |
| degrees_per_unit | player_config | 0.022 | 0.001–0.1 |
| bob_amount / tilt_angle | player_config | 0 / 0 (off) | SUCC's @export_range |
| enable_bhop / enable_surf | Player root (SUCC) | true / true | on/off |
| ramp_angle_threshold | Player root (SUCC) | 45° | 0–89° |
| max_floor_angle | Player root (SUCC) | 50° | 0–89° |
| kill_height | Respawn node | −30 m | −200–0 |
| use_accumulated_input | InputSetup node | false | on/off |
| physics_ticks_per_second | project.godot | **128** (changed from 60) | 60–240 |

## How to test
Unit and scene tests (GUT). Each one maps to a Behaviour line:
- `tests/unit/test_project_setup.gd`
  - `physics/common/physics_ticks_per_second` is 128. (6)
  - `forward`/`back`/`left`/`right`/`jump`/`crouch`/`respawn` each have exactly one key event, with the physical keycodes W/S/A/D/Space/Left Ctrl/R. `jump` has no mouse-button event. (5)
  - `sprint` exists and has zero events. (4, 11)
- `tests/movement/test_player_scene.gd`: instance `player.tscn` and add it to the tree.
  - The root is a `SUCC`, and its `config` is `res://src/player/player_config.tres`. (1)
  - The config has max_speed 10.16, gravity 20.32, jump_height 1.143, air_acceleration 100, and sprint_speed_modifier 1.0. (2, 4)
  - `enable_bhop`, `enable_surf` and `bhop_buffered_jump` are true. (3)
  - It has a `PlayerRespawn` child and a `PlayerInputSetup` child.
  - After `_ready`, `Input.use_accumulated_input` is false. (7)
- `tests/movement/test_respawn.gd`: the player is placed at a known start position and yaw before it enters the tree, with no floor under it.
  - Move it, set a non-zero velocity and pitch, then call `respawn()`. Position and yaw are back at the start, velocity is zero and pitch is 0. (8)
  - Send a `respawn` action press (GUT `InputSender` or `Input.parse_input_event` with an `InputEventAction`). The player respawns. (8)
  - Put it at y = −31 and wait 1 physics frame: it respawns. Put it at y = −29 with zero velocity and wait 1 physics frame: it does not respawn. (9)
- `tests/movement/test_course_scene.gd`: load `levels/test_course/test_course.tscn`.
  - The main scene is still this course.
  - `Player`'s `scene_file_path` is `res://src/player/player.tscn`. (1)
  - The root has no script, and there are no `JumpSound`, `Speedo`, `PresetPanel` or `Hint` nodes. `UI/HUD/Crosshair` exists. (10)

Boot check (11): run `& $godot --headless --path . --quit-after 300`. The output has no line containing `SUCC: input action`. Paste the output as proof.

Playtest checks (no automated test, done once by hand):
- Walk, jump, crouch and bhop around the demo course.
- Shift does nothing.
- R and falling off the map both respawn you.
- Esc frees the mouse and a click captures it again (SUCC's own behaviour, just confirm it still works).

Proof screenshot: run the game with collision shapes visible (`& $godot --path . --debug-collisions`). Take `editor_screenshot` with `source: "game"` from the spawn point, showing the course, the crosshair, and no demo HUD.

`workflow/tools/check.ps1` passes.

## Out of scope
- The debug overlay / speed meter (feature 2).
- Tests of movement numbers: time to top speed, stopping distance, bhop gain (features 3 and 4).
- New or changed course geometry (feature 5).
- The in-game tuning panel, and saving settings (feature 6).
- FOV and sensitivity matching (phase 2). The camera stays at SUCC's 90° vertical FOV.
- `player.gd` and anything in `src/player/techs/`.
- Sounds (the demo jump sound is removed, not replaced).
- Third-person mode, gamepad, rebinding keys in game.
- Removing the course's dependence on SUCC's demo texture and theme.
