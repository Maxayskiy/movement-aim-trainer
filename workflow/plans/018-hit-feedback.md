# Hit feedback: hit marker, hitsound, killsound
Issue: #18
Status: approved

Feature 3 of roadmap phase 2 (aim base). Every shot that damages a live target shows a short "X" around the crosshair and plays a hitsound. A killing shot shows a red X and plays a killsound instead. The player can switch each part off and set both volumes. Stats (#20) reuse the rifle's new `target_hit` signal.

**Start after #17 (merged).** Branch `feat/018-hit-feedback` from main.

**Prerequisite: the two default sounds.** The /assets chat delivers `assets/audio/hitsound.<ogg|wav>` and `assets/audio/killsound.<ogg|wav>` (CC0 or credit-free, listed in the `workflow/state/assets.md` ledger) before this plan is built. If either file is missing, stop and tell the user. Don't download, record or generate sounds yourself. Never copy sounds from an installed game (the repo is public).

Approach (chosen): **the rifle reports hits.** `take_hit` returns what the hit did, as a `TargetHealth.Result`. The Rifle emits a new signal, `target_hit(collider, killed)`, for every hit that counted. A new `HitFeedback` CanvasLayer in `player.tscn` listens to it, draws the X and plays the sounds. The fade timing is a pure class, `HitMarkerFade`, that tests check without a scene (like `FireTimer` and `BhopTracker`). All values sit in one `HitFeedbackConfig` resource, read live.

Facts this plan relies on:
- The rifle calls `take_hit(damage())` on a hit collider that has the method, and ignores the return value (`src/weapons/rifle.gd:126-133`). Then it emits `shot_fired(origin, direction, hit_position, collider)` (`rifle.gd:134`). Shots fire only on physics ticks (128 per second), at most one per tick.
- `Dummy.take_hit(damage: float) -> void` (`src/targets/dummy.gd:62-70`) gets a `TargetHealth.Result` (`IGNORED`, `DAMAGED`, `KILLED`) from `health.take` (`src/targets/target_health.gd:6`, `:50-60`). A dead dummy's collision is off, so rays pass through it.
- The test helper `HitTarget.take_hit(damage: float) -> void` records each call (`tests/helpers/hit_target.gd:20-21`). Existing tests use it as a wall and call `take_hit` as a statement. The project only turns `untyped_declaration` into an error (`project.godot:24`). A discarded return value is not a warning, so existing calls keep compiling.
- The player scene has `Rifle`, `HitMarkers` (the F3 debug spheres) and `DebugOverlay` (a CanvasLayer on layer 10) as children of the Player root (`src/player/player.tscn:78-86`). `HitMarkers` finds the Rifle as a sibling: `get_parent().get_node_or_null("Rifle")` (`src/debug/hit_markers.gd:27-30`).
- The `+` crosshair is a Label in the course scene, `UI/HUD/Crosshair`, on the default CanvasLayer (layer 1). Plan 016 checked that it sits on the exact screen centre. Its theme outline colour is (0.16, 0.16, 0.18) (`assets/ui/hud_theme.tres:25`).
- There is no display stretch mode (`project.godot` `[display]`). The base viewport is 1920 × 1080, so UI sizes are real screen pixels.
- Only the Master audio bus exists. Headless Godot uses a dummy audio driver: `play()` works but nothing is heard, so tests check calls and settings, not sound output.
- `AudioStreamPlayer.max_polyphony` sets how many copies of its sound play at once. Calling `play()` past that number cuts off the oldest copy.

## Behaviour
1. **What counts.** Feedback comes only from a rifle shot that damages a live target, meaning `take_hit` returns `DAMAGED` or `KILLED`. A shot that hits a wall, the floor or anything without `take_hit`, or that misses, gives no feedback. The killing shot is the one that returns `KILLED`. Today the only target is the dummy.
2. **Marker shape.** An "X" of 4 straight lines on the diagonals around the screen centre. Each line starts `marker_gap` px from the centre (measured along the diagonal) and is `marker_length` px long and `marker_thickness` px thick. Defaults are 8, 8 and 2, so with defaults each line runs from (±5.66, ±5.66) to (±11.31, ±11.31) px from the centre. The lines are antialiased. Sizes are real screen pixels, with no scaling by resolution. A dark outline `marker_outline` px wide surrounds each line (default 1 px, colour (0.16, 0.16, 0.18)). At 0 there is no outline. The X draws over the course HUD and under the F3 panel.
3. **Marker colour and fade.** A hit shows the X in `hit_color` (white). A kill shows it in `kill_color` (red, (1, 0.15, 0.15)). It appears at full strength and fades linearly to nothing over `marker_duration` (default 0.25 s): alpha = 1 − elapsed / duration, and at 0 once elapsed ≥ duration. Each new hit restarts the fade at full strength in the newest hit's colour. A kill turns a fading white X red, and a hit right after a kill turns it white again. The outline fades with the lines.
4. **Marker toggle.** With `marker_enabled` off, no X is drawn, and an X that is showing disappears at once. Sounds are not affected.
5. **Hitsound.** A hit that doesn't kill plays the hitsound once.
6. **Killsound.** A killing shot plays the killsound once and not the hitsound. If `killsound_enabled` is off, the killing shot plays the hitsound instead (if the hitsound is on).
7. **How sounds play.** Sounds are flat: they don't depend on where the target is, and their volume is the same at any distance. The pitch is the same every time. Every hit plays its own sound. Up to `max_voices` (default 8) copies of each sound overlap, and a further one cuts off the oldest copy.
8. **Sound settings.** `hitsound_enabled` and `killsound_enabled` switch each sound on and off. `hitsound_volume` and `killsound_volume` run from 0 to 100 % in 1 % steps, default 100 %. The player volume is `linear_to_db(volume / 100)`. At 0 % that sound doesn't play at all.
9. **Default sounds.** `hitsound` and `killsound` in the shipped config are `assets/audio/hitsound.*` and `assets/audio/killsound.*` (prerequisite). If a sound is empty (null) in the config, it is silent with no error.
10. **Live settings.** `HitFeedback` reads the config every frame (marker) and on every hit (sounds). Changes made while the game runs apply at once.
11. **Rifle signal for #20.** The Rifle emits `target_hit(collider: Object, killed: bool)` for every shot whose `take_hit` returned `DAMAGED` (`killed` false) or `KILLED` (`killed` true). It comes right after that shot's `shot_fired` on the same tick. If `take_hit` returns `IGNORED` or anything that is not an int, there is no `target_hit`. A non-int return also raises a `push_warning` naming the collider.
12. **Unchanged.** The F3 debug spheres (`HitMarkers`) work exactly as before. The player's respawn (R) doesn't touch the X.

## Files to touch
New:
- `src/ui/hit_feedback_config.gd`: `class_name HitFeedbackConfig extends Resource`. Every field is in Sliders.
- `src/ui/hit_feedback_config.tres`: the defaults, with `hitsound` and `killsound` set to the two asset files.
- `src/ui/hit_marker_fade.gd`: `class_name HitMarkerFade extends RefCounted`. Pure fade state, with times in seconds passed in by the caller (behaviour 3).
  - `var duration: float = 0.25`. Values under 0.01 are clamped to 0.01.
  - `var killed: bool` (read-only): whether the X shows the kill colour.
  - `show(was_kill: bool, now: float) -> void`: restarts at full strength.
  - `alpha(now: float) -> float`: `clampf(1 − (now − shown_at) / duration, 0, 1)`. It is 0 before the first `show` and after `clear`.
  - `clear() -> void`.
- `src/ui/hit_marker_view.gd`: `class_name HitMarkerView extends Control`. It draws the X (behaviour 2).
  - `static func segments(center: Vector2, gap: float, length: float) -> PackedVector2Array`: 8 points, as start/end pairs for the 4 diagonals, in the order up-left, up-right, down-right, down-left. Direction `(±1, ±1) / √2`, start = centre + dir × gap, end = centre + dir × (gap + length).
  - `var config: HitFeedbackConfig`, `var color: Color`, `var alpha: float`, set by `HitFeedback`.
  - `_draw`: if `alpha` ≤ 0, draw nothing. Otherwise, when the outline is > 0, first draw each segment in the outline colour, `thickness + 2 × outline` wide and extended by `outline` px at both ends. Then draw the segment in `color` at `thickness`. Both are multiplied by `alpha` and antialiased. The centre is `size / 2`.
- `src/ui/hit_feedback.gd`: `class_name HitFeedback extends CanvasLayer`. A child of the Player root.
  - `@export var config: HitFeedbackConfig`. If it is null, it uses `HitFeedbackConfig.new()`.
  - Signals `hitsound_played` and `killsound_played`, emitted exactly when `play()` is called on that player. Tests watch them.
  - `var fade: HitMarkerFade`.
  - `_ready`: finds the sibling `Rifle` the same way `HitMarkers` does and connects `target_hit`. If there is no Rifle, it does nothing and raises no error.
  - On `target_hit(collider, killed)`: calls `fade.show(killed, now)` with `now = Time.get_ticks_usec() / 1e6`. Then it picks the sound by behaviours 5, 6 and 8, sets that player's `stream`, `volume_db` and `max_polyphony` from the config, and calls `play()` unless the stream is null.
  - `_process`: copies the config into `fade.duration` and into the view, sets the view's colour (`kill_color` if `fade.killed`, else `hit_color`) and alpha (0 if `marker_enabled` is off), then calls `queue_redraw()`.
- `src/ui/hit_feedback.tscn`: root `HitFeedback` (CanvasLayer, `layer = 2`, script `hit_feedback.gd`, `config` = `hit_feedback_config.tres`). Children:
  - `Marker`: `HitMarkerView`, full-rect anchors, `mouse_filter = IGNORE`.
  - `HitSound` and `KillSound`: `AudioStreamPlayer`, bus Master.
- Tests: `tests/unit/test_hit_marker_fade.gd`, `tests/unit/test_hit_marker_view.gd`, `tests/weapons/test_rifle_target_hit.gd`, `tests/ui/test_hit_feedback.gd` (see How to test).

Changed:
- `src/weapons/rifle.gd`:
  - Add `signal target_hit(collider: Object, killed: bool)` with a doc comment.
  - In `_fire`, keep the `take_hit` result as `var result: Variant`. Emit `shot_fired` as now, then `target_hit` per behaviour 11.
  - Nothing else changes.
- `src/targets/dummy.gd`: `take_hit(damage: float) -> TargetHealth.Result`, which returns the result of `health.take`. Signals and hide logic are unchanged. Update the doc comment.
- `tests/helpers/hit_target.gd`: add `var result: TargetHealth.Result = TargetHealth.Result.DAMAGED`. `take_hit` still records the damage and now returns `result`. This is a helper, not a test, and no existing test changes.
- `src/player/player.tscn`: add a `hit_feedback.tscn` instance named `HitFeedback` as a child of the Player root.

Not touched: `src/targets/target_health.gd`, `src/debug/`, the course scene, every existing test file, anything in `addons/`.

## Sliders
All live in `HitFeedbackConfig` as `@export`s. #15 Tuning panel and the phase 4 settings show them later.

| Name | Default | Range | Notes |
|---|---|---|---|
| `marker_enabled` | true | on/off | Player setting. |
| `marker_gap` | 8 px | 0–50, step 1 | Player setting. From the centre to each line's start, along the diagonal. |
| `marker_length` | 8 px | 1–50, step 1 | Player setting. |
| `marker_thickness` | 2 px | 1–10, step 1 | Player setting. |
| `marker_outline` | 1 px | 0–5, step 1 | Player setting. 0 = no outline. |
| `marker_outline_color` | (0.16, 0.16, 0.18, 1) | any | Matches the crosshair outline. |
| `marker_duration` | 0.25 s | 0.05–1.0, step 0.01 | Player setting. Full fade time. |
| `hit_color` | (1, 1, 1, 1) | any | Customisable later (phase 4). |
| `kill_color` | (1, 0.15, 0.15, 1) | any | Customisable later (phase 4). |
| `hitsound_enabled` | true | on/off | Player setting. |
| `killsound_enabled` | true | on/off | Player setting. |
| `hitsound_volume` | 100 % | 0–100, step 1 (int) | Player setting. |
| `killsound_volume` | 100 % | 0–100, step 1 (int) | Player setting. |
| `max_voices` | 8 | 1–16, step 1 | Copies of one sound that overlap. Not a player setting. |
| `hitsound` | `assets/audio/hitsound.*` | AudioStream | Import of your own sounds is phase 4. |
| `killsound` | `assets/audio/killsound.*` | AudioStream | Same. |

## How to test
Run `powershell -NoProfile -ExecutionPolicy Bypass -File workflow/tools/check.ps1`. It must pass. Pixels are checked to ±0.01 px, alpha to ±0.001, dB to ±0.01, and ticks exactly.

**`tests/unit/test_hit_marker_fade.gd`** (pure, times by hand):
- Before any `show`: `alpha(0)` and `alpha(5)` are 0. (3)
- `show(false, 10.0)` with duration 0.25: alpha 1 at 10.0, 0.5 at 10.125, 0 at 10.25 and at 11.0. `killed` is false. (3)
- Restart: `show(false, 10.0)`, then `show(true, 10.2)`: alpha 1 at 10.2, 0.5 at 10.325, and `killed` is true. Then `show(false, 10.3)`: `killed` is false and alpha is 1 at 10.3. (3)
- Duration 1.0: alpha 0.75 at 0.25 s after `show`. Duration 0 is clamped to 0.01. (3, 10)
- `clear()` while showing: alpha 0. (4)

**`tests/unit/test_hit_marker_view.gd`** (static `segments`):
- Centre (960, 540), gap 8, length 8: 8 points. The up-left start is (954.343, 534.343) and its end is (948.686, 528.686). The other three are mirrored in the order up-right, down-right, down-left. Every segment is 8 px long and every start is 8 px from the centre. (2)
- Gap 0, length 20: every start equals the centre and every segment is 20 px long. (2)

**`tests/targets/test_dummy_hit_result.gd`** (a `dummy.tscn` in the tree with its own `DummyConfig` copy, max health 100):
- `take_hit(25)` three times returns `DAMAGED`, the fourth returns `KILLED`, and a fifth (dead) returns `IGNORED`. `take_hit(0)` on a live dummy returns `IGNORED`. (1, 11)

**`tests/weapons/test_rifle_target_hit.gd`** (MovementRig with `player.tscn`, `require_captured_mouse` false, real `fire` events as in `tests/weapons/test_rifle.gd`, player at the origin facing −Z, each test using its own `RifleConfig` and `DummyConfig` copies):
- **Dummy kill:** a dummy with feet at (0, 0, −10). Hold fire for 4 shots. `target_hit` arrives 4 times with the dummy as collider and `killed` = false, false, false, true. Each one arrives on the same tick as its `shot_fired` and right after it (record order and `Engine.get_physics_frames()`). (1, 11)
- **Plain wall:** a `StaticBody3D` box with no `take_hit` at z = −20. One click: `shot_fired` with the wall as collider, and no `target_hit`. (1, 11)
- **Miss:** nothing in front. One click: no `target_hit`. (1)
- **Ignored:** a `HitTarget` with `result = IGNORED`. One click: it records the damage, and there is no `target_hit`. (11)
- **Default HitTarget:** one click on a default `HitTarget` gives `target_hit(target, false)`. With `result = KILLED` it gives `target_hit(target, true)`. (11)
- **Non-int return:** a test-local `StaticBody3D` whose `take_hit` returns nothing. One click: no `target_hit`, no crash. (11)

**`tests/ui/test_hit_feedback.gd`** (same rig and fire events, the dummy at (0, 0, −10), and a copy of the shipped config so tests can change it; use `watch_signals` on `HitFeedback`):
- **Scene defaults:** `player.tscn` has `HitFeedback` (layer 2) with `Marker`, `HitSound` and `KillSound`. The shipped config matches every default in Sliders, and its `hitsound` and `killsound` are the two files under `assets/audio/`, which load as `AudioStream`s. (2, 9)
- **Hit:** one click on a fresh dummy. `hitsound_played` fires once, `killsound_played` doesn't, `fade.killed` is false, `fade.alpha(now)` is > 0.9, and after the next `_process` the view's colour is `hit_color`. (1, 3, 5)
- **Kill:** 4 held shots. `hitsound_played` fires 3 times, then `killsound_played` once on the 4th, with no hitsound on that shot. `fade.killed` is true and the view's colour is `kill_color`. (3, 6)
- **Wall:** one click on a plain `StaticBody3D` wall: no sound signal, and fade alpha stays 0. (1)
- **Fade in game:** after a hit, wait more than `marker_duration` of real time (0.3 s with the default). The view's alpha is 0. (3)
- **Marker off:** `marker_enabled` false. A hit still plays the hitsound, and the view's alpha is 0 after the next `_process`. Switching it off while an X shows sets the alpha to 0 on the next `_process`. (4)
- **Sound toggles:** hitsound off, so a hit gives no `hitsound_played`. Killsound off, so a kill gives `hitsound_played` (not `killsound_played`). Both off, so a kill gives no sound signal. (6, 8)
- **Volume:** hitsound volume 50, then a hit: `HitSound.volume_db` = `linear_to_db(0.5)` (−6.02 dB). Volume 100 gives 0 dB. Volume 0 gives no `hitsound_played`. Killsound volume 25, then a kill: `KillSound.volume_db` = −12.04 dB. (8, 10)
- **Voices:** `max_voices` 3, then a hit: `HitSound.max_polyphony` is 3. Default: 8. (7)
- **Null stream:** `hitsound` set to null. A hit gives no `hitsound_played`, no error, and the X still shows. (9)
- **Live colour:** `kill_color` changed to blue while a kill X shows. After the next `_process` the view's colour is blue. (10)
- **No Rifle:** a `hit_feedback.tscn` alone in the tree: `_ready` raises no error. (Robustness for #21 scenes.)
- **Debug spheres unchanged:** with the F3 panel visible, a hit on the dummy still adds one `HitMarkers` sphere. (12)

**Stop-and-report rule** (as in #8 to #17): if a test can't pass as written, stop and report measured against expected. Don't change tolerances, expected numbers or `addons/`. The user decides.

**Screenshot proof** (game running, `editor_screenshot` with `source: "game"`, F3 on, on the target range firing line facing north). For these screenshots only, set `marker_duration` to 1.0 in the running game. Don't commit that change.
- One shot on `Dummy10`: a white X around the `+`, centred on it, with the red F3 sphere on the dummy and its label at 75.
- The 4th shot that kills `Dummy05`: a red X.
- Zoom in on the X (`zoom` region around the screen centre) to show the 1 px outline and 8 px gap.

**Playtest** (by the user, after the merge):
- Hold fire on a dummy: 3 hitsounds and a killsound, with white X, white X, white X, red X.
- Shoot walls: silence, no X.
- Change sizes, colours and volumes in `hit_feedback_config.tres` while the game runs: the X and sounds follow.

## Out of scope
- Damage numbers and a hit flash on the target (decided: not wanted, not filed).
- Headshot marker or sound (#27).
- A master volume, audio buses or an audio settings menu (#15, phase 4).
- Importing your own hitsounds and killsounds, and a marker builder beyond these sliders (phase 4).
- Positional (3D) sounds, pitch variation, and per-weapon sounds.
- Shot sound, muzzle flash and view model (#25).
- Feedback for Rifle2 and weapon switching (#26): `HitFeedback` listens to one Rifle.
- Stats, score, accuracy (#20): they reuse `target_hit` later.
