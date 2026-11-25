# Debug overlay
Issue: #5
Status: approved

Second feature of roadmap phase 1 (movement base). It is a developer tool: it shows the movement and performance numbers we need for tuning, proof screenshots and the feature 3–4 playtests. A player-facing speedometer setting comes in phase 4 and can reuse this code.

Approach (chosen): **a child of the player scene.** `src/debug/debug_overlay.tscn` is a CanvasLayer instanced in `src/player/player.tscn` next to `Respawn` and `InputSetup`. It reads its parent SUCC through SUCC's public API, the same pattern as feature 1. The logic lives in two small pure classes (`BhopTracker`, `PerfSampler`) so unit tests can drive them with made-up frame numbers and times. The overlay script only connects signals and draws text.

Facts from SUCC this plan relies on (`addons/SUCC/scripts/succ.gd`, read-only):
- Public state: `velocity`, `movement_state` (`:62`, enum `MovementState` `:18`), `floor_type` (`:65`, enum `FloorType` NONE/FLOOR/RAMP `:17`), `crouched` (`:72`).
- Signal `jumped` (`:11`) is emitted inside `_jump` (`:479–484`), after the jump impulse is set and before the body moves.
- Signal `landed(fall_velocity)` (`:12`) is emitted in `_move_body` (`:510`, `:526`, `:539`) on the tick the body touches the floor.
- On the tick after landing, a held jump calls `_jump` instead of friction (`_set_velocity`, `:414–422`). So a perfect hop means `jumped` fires exactly one physics frame after `landed`. **Ground ticks** of a hop = jump physics frame − land physics frame − 1, using `Engine.get_physics_frames()`. A perfect hop has 0 ground ticks.
- `SUCCConfig.SOURCE_MULT = 39.37` (`addons/SUCC/scripts/succ_config.gd:6`) converts m/s to Source units per second (u/s).

## Behaviour
1. **Speedometer.** The player's horizontal speed (x/z only) shows as a whole number of u/s with no unit text (e.g. `400` at 10.16 m/s), in white, font size 28, centred horizontally, its top 40 px below the screen centre (just under the crosshair). It updates every rendered frame. It is always on: F3 does not hide it.
2. **Debug panel.** A panel in the top-left corner, monospace font size 18, on a semi-transparent dark background. It updates every rendered frame (except the performance lines, see 6). It shows:
   - `vert` vertical speed, whole-number u/s with sign (falling is negative).
   - `state` the movement state name (`IDLE`, `WALKING`, `CROUCHING`, `JUMPING`, `FALLING`, …).
   - `floor` the floor type name (`NONE`, `FLOOR`, `RAMP`).
   - `crouch` `yes` / `no`.
   - The bhop lines (3–5).
   - The performance lines (6).
   - A row of key boxes (7).
3. **Takeoff speed.** On every jump, the horizontal speed at the moment `jumped` fires is stored and shown as `takeoff` in whole-number u/s. Before the first jump it shows `—`.
4. **Hops in a row.** `hops` counts jumps in a chain. A jump extends the chain only if all of these hold:
   - there was a previous jump in this chain;
   - exactly one landing happened since that previous jump (walking off a ledge and landing again breaks the chain);
   - the hop's ground ticks are ≤ `max_chain_ground_ticks` (default 0, so only perfect hops).
   Otherwise the jump starts a new chain at 1. The panel also shows `ground` = the last hop's ground ticks, or `—` if there was no landing before that jump (for example the first jump after spawning).
5. **Gain.** `gain` = this takeoff speed − the previous takeoff speed in the same chain, in whole-number u/s with a sign (`+12`, `-8`, `+0`). On the first hop of a chain it shows `—`.
6. **Performance lines.** Refreshed every 0.25 s, not every frame, so they are readable:
   - `fps`: frames counted in the last window ÷ the window's real length.
   - `frame`: the average frame time over the window, in ms, 2 decimals.
   - `process` and `physics`: Godot's `Performance.TIME_PROCESS` and `Performance.TIME_PHYSICS_PROCESS`, in ms, 2 decimals.
   - `ticks/s`: physics ticks counted in the last window ÷ the window's real length (measured with `Time.get_ticks_usec()`, not read from the project setting), so it proves 128 Hz really runs. Shown as a whole number.
   Before the first window ends, these show `—`.
7. **Key boxes.** Six boxes labelled `W`, `A`, `S`, `D`, `JUMP`, `CROUCH`. A box is lit (fully opaque) while its action (`forward`, `left`, `back`, `right`, `jump`, `crouch`) is held, and dim (alpha 0.3) otherwise.
8. **F3 toggle.** Pressing F3 (a new `toggle_debug` action, physical key) hides the panel. Pressing it again shows it. The speedometer stays visible either way. The panel is visible when the game starts (`start_visible`, default true). The state lasts through respawns for the session and is not saved to disk.
9. **Respawn clears the bhop stats.** Respawning (R or falling below the kill height) resets takeoff, gain, hops and ground ticks to their start state (`—`, `—`, 0, `—`).
10. **Doesn't get in the way.** No overlay control catches the mouse: clicking anywhere, including on the panel, still captures the mouse as before.
11. Every level that uses `player.tscn` gets the overlay. No level changes are needed.

## Files to touch
New:
- `src/debug/bhop_tracker.gd`: `class_name BhopTracker extends RefCounted`. Pure logic, no nodes.
  - `var max_chain_ground_ticks: int = 0`
  - Read-only results: `hops: int` (0 at start), `has_takeoff: bool`, `last_takeoff_speed: float` (m/s), `has_gain: bool`, `last_gain: float` (m/s), `last_ground_ticks: int` (−1 = no landing before the last jump).
  - `func on_landed(physics_frame: int) -> void`: stores the frame and counts landings since the last jump.
  - `func on_jumped(physics_frame: int, horizontal_speed: float) -> void`: applies the rules in Behaviour 3–5, then clears the landing count.
  - `func reset() -> void`: back to the start state.
- `src/debug/perf_sampler.gd`: `class_name PerfSampler extends RefCounted`. Pure logic, no nodes, no `Performance` or `Time` calls (the caller passes times in).
  - `var interval: float = 0.25` (seconds).
  - `func add_frame(delta: float, now_usec: int) -> bool`: the very first call only records `now_usec` as the window start and returns false. Every later call counts a frame and its delta. When `now_usec` is at least `interval` past the window start, it computes `fps` (frames ÷ elapsed seconds), `frame_ms` (mean delta × 1000) and `ticks_per_second` (ticks ÷ elapsed seconds), sets `has_sample`, starts a new empty window at `now_usec`, and returns true. Otherwise it returns false.
  - `func add_tick() -> void`: counts a physics tick in the current window.
  - Results: `has_sample: bool`, `fps: float`, `frame_ms: float`, `ticks_per_second: float`.
- `src/debug/debug_overlay.gd`: `class_name DebugOverlay extends CanvasLayer`.
  - @exports: see Sliders.
  - `_ready`: takes `get_parent() as SUCC` (if null: `push_error("DebugOverlay: parent must be a SUCC.")`, turn off processing, return). Connects `jumped` and `landed`. Connects `respawned` on the sibling `Respawn` node if it exists (`get_parent().get_node_or_null("Respawn") as PlayerRespawn`). Applies font sizes, offset and visibility from the exports. Creates its `BhopTracker` and `PerfSampler`.
  - `_on_jumped`: `tracker.on_jumped(Engine.get_physics_frames(), SpeedUtils.horizontal_speed(player.velocity))`.
  - `_on_landed(_fall_velocity: float)`: `tracker.on_landed(Engine.get_physics_frames())`.
  - `_on_respawned`: `tracker.reset()`.
  - `_physics_process`: `sampler.add_tick()`.
  - `_process(delta)`: `sampler.add_frame(delta, Time.get_ticks_usec())`. When it returns true, also store `Performance.get_monitor(Performance.TIME_PROCESS)` and `TIME_PHYSICS_PROCESS` (seconds → ms). Then set the speedometer text, the panel text and the key-box alphas.
  - `_unhandled_input`: on `toggle_debug` pressed, flip the panel's visibility and mark the input handled.
  - `var panel_visible: bool` (read-only getter) for tests.
- `src/debug/debug_overlay.tscn`: root `DebugOverlay` (CanvasLayer, `layer = 10`, script above). Children:
  - `Speedometer` (Label): centre-anchored horizontally at the screen centre, text centred.
  - `Panel` (PanelContainer, top-left, margin 8 px) with a `StyleBoxFlat` background `Color(0, 0, 0, 0.55)`, holding a VBoxContainer with:
    - `Stats` (Label, multi-line).
    - `Keys` (HBoxContainer) with six Labels named `KeyW`, `KeyA`, `KeyS`, `KeyD`, `KeyJump`, `KeyCrouch`, each with a small bordered `StyleBoxFlat`.
  - Font: a `SystemFont` sub-resource with `font_names = ["Consolas", "Cascadia Mono", "Courier New", "monospace"]`, used by `Stats`, the key boxes and `Speedometer`.
  - Every Control has `mouse_filter = MOUSE_FILTER_IGNORE` (Behaviour 10).
- `tests/unit/test_bhop_tracker.gd`, `tests/unit/test_perf_sampler.gd`, `tests/debug/test_debug_overlay.gd`, `tests/movement/test_bhop_tracking.gd` (see How to test).

Changed:
- `src/debug/speed_utils.gd`: add `static func to_ups(meters_per_second: float) -> int`, returning `roundi(meters_per_second * SUCCConfig.SOURCE_MULT)`.
- `src/player/respawn.gd`: add `signal respawned`, emitted at the end of `respawn()`. Nothing else changes.
- `src/player/player.tscn`: add a `DebugOverlay` child, an instance of `res://src/debug/debug_overlay.tscn`, after `InputSetup`.
- `project.godot`: new Input Map action `toggle_debug` with one key event, physical keycode F3 (`keycode` 0).
- `tests/unit/test_speed_utils.gd`: add the `to_ups` tests below (new test functions only).
- `tests/unit/test_project_setup.gd`: add a new test function `test_toggle_debug_is_f3`. Don't change the existing tests.

Not touched: anything in `addons/`, `levels/test_course/test_course.tscn` (the crosshair stays where it is).

## Sliders
None of these change movement feel. They are @exports on the `DebugOverlay` node so phase 4 can turn them into settings.

| Name | Where | Default | Range |
|------|-------|---------|-------|
| start_visible | DebugOverlay | true | on/off |
| show_speedometer | DebugOverlay | true | on/off |
| panel_font_size | DebugOverlay | 18 | 10–48 |
| speedometer_font_size | DebugOverlay | 28 | 12–96 |
| speedometer_offset | DebugOverlay | 40 px | 0–400 |
| perf_refresh_interval | DebugOverlay (passed to PerfSampler.interval) | 0.25 s | 0.05–2.0 |
| max_chain_ground_ticks | DebugOverlay (passed to BhopTracker) | 0 | 0–10 |

## How to test
Unit tests (GUT). Each one maps to a Behaviour line:
- `tests/unit/test_speed_utils.gd` (new functions):
  - `to_ups(10.16)` is 400. `to_ups(0.0)` is 0. `to_ups(-5.0)` is −197. (1, 2)
- `tests/unit/test_bhop_tracker.gd`:
  - A new tracker: hops 0, no takeoff, no gain, ground ticks −1. (3, 4, 5)
  - First jump with no landing before it (`on_jumped(50, 8.0)`): hops 1, takeoff 8.0, no gain, ground ticks −1. (3, 4, 5)
  - Perfect hop: jump at 50 with speed 8.0, land at 100, jump at 101 with speed 9.0: hops 2, ground ticks 0, gain +1.0, takeoff 9.0. (3, 4, 5)
  - Three perfect hops in a row: hops 3. (4)
  - Late hop with the default limit: jump at 50, land at 100, jump at 102: hops 1, ground ticks 1, no gain. (4, 5)
  - Same timing with `max_chain_ground_ticks = 1`: hops 2. (4)
  - Two landings between jumps (jump at 50, land at 100, land at 140, jump at 141): hops 1, no gain. (4)
  - `reset()` after a chain: back to the new-tracker state. (9)
- `tests/unit/test_perf_sampler.gd`:
  - With interval 0.25: the first `add_frame(0.01, 0)` call returns false and `has_sample` stays false. (6)
  - Then `add_frame(0.01, t)` for t = 10 000, 20 000 … 240 000 µs returns false each time, with 32 `add_tick` calls spread between them. The call at t = 250 000 returns true, and gives `fps` 100 (±0.01), `frame_ms` 10.00 (±0.01) and `ticks_per_second` 128 (±0.01). (The window-start call is not counted; the 25 calls after it are.) (6)
  - The window after that starts from zero: another 25 frames at 20 000 µs steps (delta 0.02) with 32 ticks give `fps` 50, `frame_ms` 20.00, `ticks_per_second` 64. Counts from the first window don't carry over. (6)
- `tests/unit/test_project_setup.gd`, new `test_toggle_debug_is_f3`: `toggle_debug` exists, has exactly one key event, physical keycode `KEY_F3`, keycode `KEY_NONE`. (8)

Scene tests:
- `tests/debug/test_debug_overlay.gd`: instance `player.tscn`, add it to the tree, then `set_physics_process(false)` on the player so velocity stays where the test puts it.
  - The player has a `DebugOverlay` child of type `DebugOverlay`. (11)
  - Set `velocity = Vector3(10.16, -5.0, 0.0)` and wait 1 process frame: `Speedometer.text` is `400`; `Stats.text` contains `-197`, the current state name and floor type name. (1, 2)
  - Every Control under the overlay has `mouse_filter == MOUSE_FILTER_IGNORE`. (10)
  - The speedometer is visible and the panel is visible at start. (1, 8)
  - Send a `toggle_debug` press (`Input.parse_input_event` with an `InputEventAction`): the panel is hidden, the speedometer is still visible. Send it again: the panel is visible. (8)
  - A fresh overlay with `start_visible = false` (set before it enters the tree): the panel starts hidden, the speedometer visible. With `show_speedometer = false`: the speedometer is hidden. (1, 8)
  - `Input.action_press("forward")`, wait 1 process frame: `KeyW` alpha is 1.0, `KeyS` alpha is 0.3. Release it in `after_each`. (7)
  - Set a non-zero velocity and emit `player.jumped`: the tracker has hops 1 and a takeoff. Then call the `Respawn` node's `respawn()` and wait 1 process frame: the tracker is back to its start state, and `Stats.text` shows `—` for takeoff. (3, 9)
  - After waiting 0.3 s, `Stats.text` has numbers (not `—`) for fps, frame, process, physics and ticks/s. (6)
- `tests/movement/test_bhop_tracking.gd`: integration with real SUCC physics. Put a `StaticBody3D` floor (BoxShape3D 20×1×20, top at y = 0) and `player.tscn` at y = 1 in the tree. `Input.action_press("jump")` (bhop buffered jump is on), wait 2.0 s of physics frames, release jump in `after_each`.
  - The overlay's tracker has hops ≥ 2 and last ground ticks 0. (4)
  - Takeoff speed is set. (3)

Proof screenshots: run the game (`& $godot --path .`), bhop a few hops on the course's bhop strip, and take `editor_screenshot` with `source: "game"` mid-chain, showing the speedometer under the crosshair and the full panel (hops ≥ 2, ticks/s ≈ 128). Then press F3 and take a second screenshot showing only the speedometer.

Playtest checks (by hand, once):
- Standing still: speedometer 0, state `IDLE`, floor `FLOOR`.
- Running forward on flat ground tops out at 400.
- Holding jump on the bhop strip: `ground` stays 0 and `hops` keeps climbing. Releasing jump and re-pressing late starts a new chain.
- On a surf ramp: floor shows `RAMP`.
- F3 hides and shows the panel. Clicking on the panel still captures the mouse.

`workflow/tools/check.ps1` passes.

## Out of scope
- Speed-over-time graph (issue #2).
- 3D velocity and wish-direction arrows (issue #3).
- Speedometer gain/loss colour (issue #4).
- Saving the F3 state or any overlay setting; the settings menu and a player-facing speedometer option (feature 6 / phase 4).
- Position, the velocity vector, and a history list of past hops.
- Changing the crosshair, the course, or SUCC's demo theme.
- Gamepad buttons in the key boxes, and rebinding F3 in game.
