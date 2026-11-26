# Static target dummy
Issue: #17
Status: approved

Feature 2 of roadmap phase 2 (aim base). Orange capsule dummies stand in a new Target range station. Rifle shots damage them. At 0 health a dummy vanishes and comes back after 1 s. All dummies share one `DummyConfig` resource. The moving dummy (#19), hit feedback (#18) and stats (#20) build on this.

**Start after #16 (merged).** Branch `feat/017-static-target-dummy` from main.

Approach (chosen): **a pure health class with a thin dummy body.** `TargetHealth` is a `RefCounted` with no scene access. It holds health, damage, death and the respawn countdown, counted in physics ticks, so tests check it exactly without a scene (like `FireTimer` and `BhopTracker`). `Dummy` is a `StaticBody3D`. It connects a `TargetHealth` to its capsule shape, mesh, health label and signals. #19's moving dummy will be a different body type and reuses `TargetHealth` unchanged.

Facts this plan relies on:
- Physics runs at 128 ticks per second (`project.godot`). Every body is on the default layer 1, and the player's movement collides with layer 1.
- The rifle's ray hits every body on any layer except the player. If the collider has `take_hit`, it calls `take_hit(damage: float)` on it (`src/weapons/rifle.gd:126-134`). With Rifle1 (4 sps, dps 100) a shot does 25.0 damage, 32 ticks apart (plan 016). The rifle counts ticks with `Engine.get_physics_frames()` (`rifle.gd:79`).
- The player hull is a 0.813 × 1.829 m box (`src/player/player.tscn:14`). The eye is 1.711 m above the feet (`player.tscn:54`).
- `CapsuleShape3D.height` and `CapsuleMesh.height` are the full height including both caps, and must be at least 2 × radius.
- `DebugOverlay` is a child of the Player (`player.tscn:78`). Its F3 panel state is `panel_visible` (`src/debug/debug_overlay.gd:32-34`). `HitMarkers` finds it because it is a sibling (`src/debug/hit_markers.gd:27`). Dummies are not, so the overlay joins a group they can look it up by.
- `tests/movement/test_movement_course.gd:66-84` requires every `StaticBody3D` under `Floor` and `Stations` to be a `CourseBox`. Dummies are `StaticBody3D`s, so they go under a new root node `Targets`, not under `Stations`.
- Course axes: −Z is north, +X is east, the floor top is y = 0, and the floor spans −100 … 100 on x and z (plan 014). The area x 20 … 95, z −95 … −25 is empty floor.
- **Probe** (Godot 4.7.2 headless, default physics engine, 2026-11-26): a capsule `StaticBody3D` (radius 0.4065, height 1.829) added on top of an idle player standing on the floor. `move_and_slide` pushed the player out within 2 ticks: 0.81 m sideways when the capsule was centred on the player, 0.31 m when it was 0.5 m off-centre. Velocity stayed zero and the player stayed on the floor throughout.

## Behaviour
1. **Look.** A dummy is a plain capsule in one colour (default orange, `Color(1.0, 0.45, 0.0)`), shaded, with no head. Its origin is at its feet, so it grows upward when its height changes. Default size = the player hull: 0.813 m wide (radius 0.4065) × 1.829 m tall.
2. **Solid.** The player collides with a living dummy: you can't walk through it, and you can land on its head (on the rounded top you only stay up near the centre). Shots hit it.
3. **One hit zone.** The whole body takes the same damage. No headshots (#27).
4. **Health.** A dummy starts with 100 health (`max_health`). Each `take_hit(damage)` subtracts the damage, as a float with no rounding.
   - Damage ≤ 0, or any hit while dead, does nothing.
   - Overkill is ignored: the damage that counts is capped at the health left.
   - No regen: a damaged dummy stays damaged until it dies.
   - Rifle1 kills a fresh dummy with 4 shots (1 s).
5. **Death.** When health reaches 0 the dummy dies at once: it is hidden, label included, and its collision is turned off, so later shots and the player pass through.
6. **Respawn.** It comes back in the same spot with full health after `respawn_delay` (default 1.0 s = 128 ticks).
   - The respawn tick is fixed at the moment of death: death tick + `max(1, round(respawn_delay × 128))`. A delay of 0 brings it back on the next tick.
   - It respawns even if the player stands in its spot. The physics pushes the player out (probe: within 2 ticks, no change in velocity).
   - The player's own respawn (R or kill height) doesn't touch dummies.
7. **Signals** (for #18 and #20):
   - `damaged(damage: float, health_left: float)` on every hit that counts. `damage` is the amount that counted (overkill removed).
   - `died` right after the `damaged` of the killing hit.
   - `respawned` when it comes back.
8. **Shared live settings.** All dummies use one `DummyConfig` resource (`src/targets/dummy_config.tres`). Each dummy reads it every physics tick, so changes made while the game runs apply as follows:
   - Width or height: every dummy resizes on the next tick (shape, mesh and label position). Height is never less than width: if it is, the capsule's height = width (a sphere).
   - Max health: a living dummy's health is capped to the new max at once, and it never rises. Each respawn fills health to the current max.
   - Respawn delay: applies from the next death. A dummy that is already dead keeps its respawn tick.
   - Colour: applies on the next tick.
9. **Debug health label.** While the F3 debug panel is visible, each living dummy shows its health 0.3 m above its head: a whole number rounded up (so a living dummy never shows 0), white with a dark outline, always facing the camera. Hidden when the panel is hidden or when no `DebugOverlay` exists.
10. **Target range station.** In the empty north-east of the course:
    - A white firing line on the floor, no collision: centre (50, 0.005, −30), 13 m along x.
    - Five dummies straight ahead (north). Each one's distance from the line's centre to its centre on the z axis, and its position:

      | Node | Distance | Feet at (x, y, z) |
      |---|---|---|
      | `Dummy05` | 5 m | (48, 0, −35) |
      | `Dummy10` | 10 m | (52, 0, −40) |
      | `Dummy20` | 20 m | (46, 0, −50) |
      | `Dummy40` | 40 m | (54, 0, −70) |
      | `Dummy60` | 60 m | (50, 0, −90) |

      They are shifted sideways so that from the eye at the line's centre none hides another (each ray to a dummy's centre clears the nearer dummies by ≥ 1 m).
    - A sign like the other stations': "TARGET RANGE / 5–60 m" at (50, 3, −26), rotation y = −62.5° (facing the hub), not billboard.

## Files to touch
New:
- `src/targets/target_health.gd`: `class_name TargetHealth extends RefCounted`. Pure logic (behaviour 4, 6, 8), no scene access.
  - `enum Result { IGNORED, DAMAGED, KILLED }`.
  - `var ticks_per_second: int = 128`.
  - `var max_health: float = 100.0`. Its setter clamps values under 1 to 1 with a `push_warning`. While alive it caps `health` to the new max, and never raises it.
  - `var respawn_delay: float = 1.0` (seconds). The setter clamps values under 0 to 0.
  - Read-only state: `health: float`, `alive: bool`, `last_damage: float` (the damage that counted in the last `take`).
  - `reset() -> void`: alive, health = max.
  - `take(damage: float, t: int) -> Result`: applies a hit on tick `t`. On a kill it stores the respawn tick `t + max(1, roundi(respawn_delay × ticks_per_second))`.
  - `tick(t: int) -> bool`: true exactly once, on the first tick ≥ the stored respawn tick. It then sets alive and full health.
- `src/targets/dummy_config.gd`: `class_name DummyConfig extends Resource` with `width`, `height`, `max_health`, `respawn_delay`, `color` (see Sliders).
- `src/targets/dummy_config.tres`: the defaults.
- `src/targets/dummy.gd`: `class_name Dummy extends StaticBody3D`.
  - `@export var config: DummyConfig`. If it is null, it uses `DummyConfig.new()`.
  - Signals `damaged`, `died`, `respawned` (behaviour 7).
  - `var health: TargetHealth`. `_ready` copies the config into it and calls `reset()`. `ticks_per_second` = `Engine.physics_ticks_per_second`.
  - `_ready` gives this instance its own shape, mesh and material (duplicates of the scene's), so instances never share them.
  - `take_hit(damage: float)`: calls `health.take(damage, Engine.get_physics_frames())`. On `DAMAGED` it emits `damaged`. On `KILLED` it emits `damaged`, hides itself, sets `Collision.disabled = true` and emits `died`.
  - `_physics_process`: copies the config into its shape, mesh, material, label position and `health` (behaviour 8). If `health.tick(Engine.get_physics_frames())` is true, it shows itself, re-enables collision and emits `respawned`.
  - `_process`: finds the overlay with `get_tree().get_first_node_in_group(DebugOverlay.GROUP)` (cached while it is valid). Sets the label's visibility from `panel_visible` and its text to `str(ceili(health.health))`.
  - Debug-only exports: `label_offset` 0.3 m, `label_font_size` 64, `label_pixel_size` 0.004 (about 0.25 m tall text), `label_outline_size` 12.
- `src/targets/dummy.tscn`: root `Dummy` (`StaticBody3D`, script `dummy.gd`, `config` = `dummy_config.tres`). Children:
  - `Collision`: `CollisionShape3D`, a `CapsuleShape3D` of radius 0.4065 and height 1.829, centred at y = 0.9145.
  - `Mesh`: `MeshInstance3D`, a `CapsuleMesh` of the same size and centre, with a `StandardMaterial3D` in the config colour.
  - `HealthLabel`: `Label3D`, billboard enabled, white with a dark outline, at y = 2.129.

  The scene sizes are only there to show it in the editor. The script sets the real sizes from the config.
- `tests/unit/test_target_health.gd`, `tests/targets/test_dummy.gd`, `tests/targets/test_target_range.gd` (see How to test).

Changed:
- `src/debug/debug_overlay.gd`: add `const GROUP: StringName = &"debug_overlay"`. The first line of `_ready` is `add_to_group(GROUP)`. Nothing else changes.
- `levels/movement_course/movement_course.tscn`:
  - New root child `Targets` (Node3D) with the five `dummy.tscn` instances from behaviour 10. Each keeps the scene's `config`, so all five share `dummy_config.tres`.
  - New `Stations/TargetRange` (Node3D) with:
    - `Sign`: Label3D with the same font size, pixel size and outline as the other station signs.
    - `FiringLine`: `MeshInstance3D`, 13 × 0.01 × 0.1 `BoxMesh`, material `levels/movement_course/materials/line.tres`. Like the strafe lane lines, it is not a CourseBox and has no collision.

Not touched: `src/weapons/`, `src/player/`, `tests/helpers/`, every existing test, anything in `addons/`. `test_movement_course.gd` keeps passing because dummies aren't under `Stations` and its sign test only checks the stations it lists.

## Sliders
| Name | Where | Default | Range | Notes |
|---|---|---|---|---|
| `width` | `DummyConfig` | 0.813 m | 0.3–3.0, step 0.01 | Player slider (customisation: dummy dimensions). Capsule radius = width / 2. |
| `height` | `DummyConfig` | 1.829 m | 0.5–4.0, step 0.01 | Player slider. Never below width (behaviour 8). |
| `max_health` | `DummyConfig` | 100.0 | none (min 1) | Not a player slider. An `@export` so it isn't hard-coded; set at balancing, like dps. |
| `respawn_delay` | `DummyConfig` | 1.0 s | 0–10, step 0.1 | `@export`. |
| `color` | `DummyConfig` | `Color(1.0, 0.45, 0.0)` | any | Not a player slider yet (customisation later). |

Debug-only exports on `Dummy` (not feel values): `label_offset` 0.3 m, `label_font_size` 64, `label_pixel_size` 0.004, `label_outline_size` 12.

## How to test
Run `powershell -NoProfile -ExecutionPolicy Bypass -File workflow/tools/check.ps1`. It must pass. Health is checked to ±0.001, positions and sizes to ±1 mm, and ticks exactly.

**`tests/unit/test_target_health.gd`** (pure, tick numbers by hand, `ticks_per_second` 128):
- After `reset()`: alive, health 100. (4)
- `take(25, t)` three times: `DAMAGED`, health 75 / 50 / 25, `last_damage` 25 each time. A fourth: `KILLED`, health 0, not alive, `last_damage` 25. (4, 5)
- Overkill: at health 30, `take(50)` gives `KILLED` and `last_damage` 30. (4)
- Float damage: three hits of 33.333 leave 0.001 health and the target alive. (4)
- `take` while dead, `take(0)` and `take(−5)` each give `IGNORED` and change nothing. (4)
- Respawn: killed at t = 1000 with a 1.0 s delay. `tick(1127)` is false, `tick(1128)` is true (alive, health = max), and `tick(1129)` is false. (6)
- Delay 0: killed at t = 10. `tick(10)` is false and `tick(11)` is true. (6)
- 0.5 s delay: back at death + 64. (6)
- The delay changed from 1.0 to 3.0 while dead: still back at death + 128. The next death uses 3.0 (death + 384). (8)
- `max_health` lowered from 100 to 50 at health 80: health 50. Raised to 150 at health 50: health stays 50. After the next death and respawn: health 150. (8)
- `max_health` set to 0: clamped to 1, warning raised. `respawn_delay` set to −1: clamped to 0. (4, 6)

**`tests/targets/test_dummy.gd`** (MovementRig with `player.tscn`, `require_captured_mouse` false on the Rifle, real `fire` events as in `tests/weapons/test_rifle.gd`). Setup: the player at the origin facing −Z, a `dummy.tscn` with feet at (0, 0, −10), and a `hit_target` wall behind it at z = −20. Except for the scene-defaults test, every test uses its own `DummyConfig` copy, not the shipped `.tres`.
- **Scene defaults:** the shipped `dummy_config.tres` is width 0.813, height 1.829, max health 100, delay 1.0, colour (1.0, 0.45, 0.0). A dummy with it has capsule radius 0.4065 and height 1.829, shape and mesh centred at y = 0.9145, and the label at y = 2.129 with billboard on. (1, 9)
- **Rifle kill:** hold fire for 5 shots (32 ticks apart), then release. `damaged` arrives with (25, 75), (25, 50), (25, 25), (25, 0), and `died` arrives once, right after the last `damaged`. Then the dummy is not visible and `Collision.disabled` is true. The wall records no hits from the first 4 shots and gets the 5th. (2, 4, 5, 7)
- **Respawn timing:** `respawned` fires exactly 128 ticks after the killing tick (by `Engine.get_physics_frames()`). Then the dummy is visible, collision is on, and health is 100. A new click after `respawned` hits the dummy, not the wall. (6, 7)
- **Player's own respawn:** damage the dummy to 50, then call the player's `Respawn.respawn()`. The dummy still has 50. (6)
- **Solid:** a fresh rig with the dummy at (0, 0, −3). Command W toward it for 128 ticks. The player's front face never gets past the dummy's near surface by more than 2 cm (z of the player's centre ≥ −3 + 0.4065 + 0.4065 − 0.02). (2)
- **Push-out on respawn:** a fresh rig. Add a dummy with feet at (0, 0, −5) and a 2.0 s respawn delay, and kill it with `take_hit(100)`. Then spawn the player with its feet at the same spot and `settle()`. When the dummy respawns, a box query of the player's hull no longer overlaps the dummy within 2 ticks. Velocity stays zero and `floor_type` stays FLOOR on every tick. (6)
- **Live resize:** set the config width to 2.0. After one physics tick the shape and mesh radius is 1.0, the height is 2.0 (raised to width), and the label is at y = 2.3. Then set height 3.0: height 3.0, centre y 1.5, label at y 3.3. (8)
- **Max health live:** damage to 80, then set the config's max health to 50. After one tick health is 50. (8)
- **Delay live:** set the delay to 0.5 before a kill: `respawned` comes 64 ticks after the kill. (8)
- **Instances don't share:** two dummies with different configs (width 0.813 and 2.0) keep different shape and mesh sizes. (8)
- **Health label** (toggle the panel the same way `tests/debug/test_hit_markers.gd` does with `_set_panel`):
  - Panel visible: the label is visible and reads "100". After one 25 hit it reads "75". After damage that leaves 0.4, it reads "1".
  - Panel hidden: the label is hidden.
  - A dummy in a scene with no `DebugOverlay`: the label is hidden.

  (9)

**`tests/targets/test_target_range.gd`** (loads `movement_course.tscn`):
- `Targets` has exactly five children, `Dummy05` … `Dummy60`. Each is an instance of `res://src/targets/dummy.tscn` at the position in the behaviour 10 table, and all five use the same `dummy_config.tres` resource. (10)
- `Stations/TargetRange/Sign` is a Label3D, billboard off, text "TARGET RANGE\n5–60 m", at (50, 3, −26). (10)
- `Stations/TargetRange/FiringLine` is a `MeshInstance3D` at (50, 0.005, −30) with no collision body. (10)
- **Line of sight:** after two physics frames, a ray from (50, 1.711, −30) to each dummy's centre (y = 0.9145) hits that dummy first. (10)

**Stop-and-report rule** (as in #8 to #16): if a measurement is out of tolerance, stop and report measured against expected. Examples: the push-out takes more than 2 ticks or moves the player off the floor, or the player slides around a dummy in the solid test instead of stopping. Don't change tolerances, expected numbers or `addons/`. The user decides.

**Screenshot proof** (game running, `editor_screenshot` with `source: "game"`):
- F3 on, standing on the firing line facing north: all five dummies are visible with "100" labels.
- After two shots on `Dummy10`: its label reads "50", with red hit markers on it.
- Right after killing `Dummy05`: it is gone. A second screenshot more than 1 s later shows it back with "100".

**Playtest** (by the user, after the merge):
- Kill each dummy with Rifle1. 4 shots each, and it comes back after 1 s.
- Walk into a dummy: blocked. Jump onto a head.
- Stand where a dead dummy was and wait: you get pushed out without your speed jumping.
- Change `dummy_config.tres` width and height in the inspector while the game runs: every dummy resizes.

## Out of scope
- Headshots and hit zones (#27).
- Hit marker, hitsound, killsound, death effects (#18).
- Moving dummies, dummy speed and gravity (#19).
- Kills, time to kill, accuracy, score (#20).
- The first aim drill and its arena (#21).
- A settings menu or tuning panel UI for dummy sliders (#15, phase 4).
- Health regen, health bars outside the F3 debug label, damage numbers.
- Dummies taking damage from anything but `take_hit`, and dummies that move or are pushed.
- Delaying a respawn until the spot is clear: by decision, the dummy respawns and the physics pushes the player out.
