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

- 2026-11-26 (vault note): the user's Obsidian note "Movement aim trainer" is a live source of ideas (path in Intake below).
- 2026-11-26: phase 2 (aim base) starts now, before the phase 1 gate. Tuning panel → #15; the gate playtest follows it.
- 2026-11-26: the note's movement list replaces design.md's. Dropped: surfing, tap strafing, wall bounces, superglide. Added: sliding, double jump, down dash (slope conversion). design.md and roadmap.md updated; design.md also gains the note's aim items and a customisation section.
- 2026-11-26: customisation is split. Dummy settings, basic crosshair, hitsounds → phase 2. Crosshair builder/import, hitsound import → phase 4. Surface looks and skybox → phase 6.
- 2026-11-26: surfing is back in design.md (core movement). SUCC surf stays on, the course keeps its surf V-ramp, #9 Surf number tests stays open.
- 2026-11-26: file issues only for the phase that is starting. Phase 2 filed as #16–#24; later phases wait in Intake.

- 2026-11-26 (rifle #16): triaged vague (~half a day). Planning first in phase 2.
- 2026-11-26 (rifle): the vault note now has two rifles, in shots per second (sps): Rifle1 4 sps default, customisable, hold to fire; Rifle2 10 sps default, tap only (no holding).
- 2026-11-26 (rifle): new `fire` action on left mouse. Fires only while the mouse is captured; the click that recaptures after Esc doesn't fire.
- 2026-11-26 (rifle): cadence carries the leftover tick fraction (10 sps at 128 Hz = gaps of 12/13 ticks, exact average). Taps obey the cooldown.
- 2026-11-26 (rifle): perfect accuracy: no spread, recoil or move inaccuracy; shooting doesn't slow movement. Infinite ammo, no reload.
- 2026-11-26 (rifle): ray from the eye through the screen centre; hits every solid body except the player, ignores areas. Range is infinite, no damage falloff (round 2 replaced the 1000 m slider).
- 2026-11-26 (rifle): damage per shot = dps / sps, so dps stays the same when the fire rate changes. dps default 100, not a player slider, no range; the real dps is set in the balancing stage. Damage is a float, no rounding. The rifle calls `take_hit(damage)` on what it hits (if it has the method) and emits `shot_fired` (origin, direction, hit point, collider).
- 2026-11-26 (rifle): keep the existing `+` crosshair (course scene `UI/HUD/Crosshair`); no new centre dot.
- 2026-11-26 (rifle): debug hit marker: 8 cm red sphere, lasts 2 s, max 64, visible only with F3 debug on, cleared on respawn. No tracer.
- 2026-11-26 (rifle): no shot sound, muzzle flash or view model → issue #25.
- 2026-11-26 (rifle): #16 builds one rifle script with a `full_auto` export, tested both ways; the player carries Rifle1 only. Rifle2 + weapon switching → issue #26.
- 2026-11-26 (rifle): Rifle1 fire rate slider: default 4 sps, range 1–20, step 0.5.
- 2026-11-26 (rifle): the Implement chat checks with a screenshot that the `+` sits on the exact screen centre; if not, it adjusts only the label's offsets.
- 2026-11-26 (rifle): design.md aim line updated to the two rifles, infinite range, damage = dps ÷ fire rate.
- 2026-11-26 (rifle): with `full_auto` off, a click during the cooldown is dropped (no buffer); holding fires once. Grilling done.
- 2026-11-26 (rifle): approach A + saved click aim. Shots fire on the 128 Hz tick. A click is latched in `_input` with the aim direction and on-screen (interpolated) camera position; the next tick casts from those. A tap the cooldown blocks is dropped with its saved aim. Held shots use the physics eye + current yaw/pitch. One `aim()` function returns origin + direction.
- 2026-11-26 (rifle): FireTimer schedules held shots from when the last was due; after idle it restarts from the current tick, no catch-up burst. Rate capped at 128 sps (tick rate), clamped with a warning; under 1 clamped to 1.
- 2026-11-26 (rifle): the game is offline single-player; no networking. Claims about how Source does hitscan were unverified: don't rely on them.
- 2026-11-26 (rifle): probe facts (Godot 4.7.2 headless): mouse can't be captured headless; events stay in order, and accumulated input merges only back-to-back motion (a click splits it). Plan tests the order with real events and stops if it fails.

- 2026-11-26 (static dummy #17): triaged vague (~half a day).
- 2026-11-26 (dummy): plain orange capsule, no head; one hit zone, no headshots (→ issue #27); default size = player hull 0.813 × 1.829 m, grows up from its feet.
- 2026-11-26 (dummy): health 100 default (@export, not a player slider, set at balancing); dies at 0 → vanishes, collision off, overkill ignored; respawns same spot, full health, after 1.0 s (@export 0–10 s); no regen; player R leaves dummies alone.
- 2026-11-26 (dummy): the player collides with dummies (solid, not passable).
- 2026-11-26 (dummy): all dummies share one `DummyConfig` resource (width, height, health, respawn delay), live changes; #19 adds speed and gravity.
- 2026-11-26 (dummy): new "Target range" station in the course; #21 gets its own arena.
- 2026-11-26 (dummy): debug health label above each dummy, only with F3 on.
- 2026-11-26 (dummy): signals `damaged(damage, health_left)`, `died`, `respawned` for #18/#20.
- 2026-11-26 (dummy): respawn happens even if the player stands in the spot; the physics pushes the player out. Probe (Godot 4.7.2 headless, default engine, idle player, capsule appears on top): pushed out in 2 ticks (centred: 0.81 m sideways; 0.5 m offset: 0.31 m), velocity unchanged, stays on floor.
- 2026-11-26 (dummy): standing on a dummy's head is fine as is. Width 0.3–3.0 m, height 0.5–4.0 m, step 0.01, height ≥ width. Size changes apply at once; new max health at next respawn (current capped); new delay from next death.
- 2026-11-26 (dummy): target range in the empty north-east of the course: floor line, 5 dummies at 5/10/20/40/60 m staggered sideways, flat floor, sign "TARGET RANGE / 5–60 m".
- 2026-11-26 (dummy): health label = whole number rounded up, white with dark outline, billboard, 0.3 m above the head. Colour = `color` in `DummyConfig` (not a player slider). Grilling done.
- 2026-11-26 (dummy) fact: `tests/movement/test_movement_course.gd:66-84` requires every StaticBody3D under `Floor` and `Stations` to be a CourseBox, so dummies must sit outside `Stations`.

- 2026-11-26 (hit feedback #18): triaged vague (~half a day). Grilling started. Facts: no display stretch mode (HUD in real pixels, 1920×1080 base); only the Master audio bus; `assets/` has no audio; assets ledger empty.
- 2026-11-26 (hit feedback): 2D X of 4 diagonal lines around the crosshair, white on a hit, red on a kill, with an on/off toggle; more marker customisation maybe later (Intake, phase 4).
- 2026-11-26 (hit feedback): a hit = a shot that damages a live target (anything with `take_hit`); walls/floor give nothing. The kill shot plays only the killsound. Sounds are flat 2D, same pitch every time, every hit plays (overlap up to 8 voices, oldest cut).
- 2026-11-26 (hit feedback): player controls: on/off for marker, hitsound, killsound; separate hitsound and killsound volume (0–100%). All values in one `HitFeedbackConfig` resource (@exports, live edits). F3 debug spheres unchanged.
- 2026-11-26 (hit feedback): out of scope, not filed: damage numbers, target hit flash. Also out: headshot sound (#27), master volume/audio buses.
- 2026-11-26 (hit feedback): the user first picked KovaaK's `blip 1.ogg` (hit) and `killConfirmed07.ogg` (kill); they are proprietary and the repo is public, so not committed. Decision: the /assets chat finds CC0 sounds like them; those are the committed defaults (added to assets.md Wanted). KovaaK's sounds come back via phase 4 import. CC0 defaults needed before any public build (Intake, phase 7).
- 2026-11-26 (hit feedback): marker in fixed real pixels: gap 8 px from centre, line length 8 px, thickness 2 px (sliders 0–50 / 1–50 / 1–10, step 1); dark outline 1 px, crosshair colour (0.16, 0.16, 0.18), slider 0–5 (0 = none). Full strength then linear fade, 0.25 s total (0.05–1.0 s); each hit restarts it, colour = newest hit. Colours: hit (1, 1, 1), kill (1, 0.15, 0.15), @exports. Volumes default 100%, step 1%, 0% = silent. Grilling done.
- 2026-11-26 (hit feedback): approach A: `take_hit` returns `TargetHealth.Result`; Rifle emits `target_hit(collider, killed)` right after `shot_fired`; `HitFeedback` CanvasLayer (layer 2) in `player.tscn`, pure `HitMarkerFade`, `HitMarkerView` draws the X, all values in `HitFeedbackConfig`. With killsound off, a kill plays the hitsound. Plan approved 2026-11-26.

- 2026-11-27 (quality checks #29): the recommended level of three. Four Godot warnings to Error (unused variable, unused private class variable, unreachable code, shadowed variable); current code passes them unchanged.
- 2026-11-27 (quality checks): gdradon gate over `src/` fails on grade C-F; B prints nothing; `tests/` not graded. gdradon has no threshold option and exits 0 on any grade, so check.ps1 parses its output; its line numbers are wrong, so none are printed.
- 2026-11-27 (quality checks): 029 trimmed to code quality only. The two speed changes moved out to #28's scope: (a) default check.ps1 typechecks only changed scripts plus transitive dependents by class_name/res:// path, with a `-Full` switch for Merge and phase gates; (b) `-IfChanged` skips a repeat check on a commit recorded green in `.godot/last-green`, used by 028's `review.ps1`. Their full text is in 029 at commit `35e361d` (old changes 3 and 6). 029 now has changes 1-4: warnings, gdradon, phase-gate audit, AGENTS.md patterns. Not yet added to plan 028.
- 2026-11-27 (quality checks): phase-gate audit uses its own checklist in `workflow/docs/quality-log.md` (Pocock's 12 Fowler smells restated with credit, plus 3 project checks), not improve-codebase-architecture (owner may run it after). Findings: one line each, `open` → `plan #N` or `accepted`. First audit = all of `src/`, at the end of phase 2.

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
  - Feature 5a **Hull and terrain tests**: `workflow/plans/012-hull-terrain-tests.md`, issue #12. **Done**: merged, issue closed 2026-11-26. Approach A: literal ledge limit 1.613 m; rig pins `max_floor_angle` 45°.
  - Bug **Player sticks on 45–50° slopes**: `workflow/plans/013-slope-stick.md`, issue #13. **Done**: merged, issue closed 2026-11-26. Walkable limit = Source's 45.573°.
  - Feature 5b **Movement course**: `workflow/plans/014-movement-course.md`, issue #14. **Done**: merged, issue closed 2026-11-26. Hand-placed `CourseBox` pieces; bhop gaps retuned (400 → 7.73 m, 600 → 11.44 m).
  - Feature 6 **In-game tuning panel**: issue #15, backlog, deferred 2026-11-26 (phase 2 first). The phase 1 gate playtest follows it.
- **Aim base (phase 2)**: started 2026-11-26. Issues #16–#26, all backlog (not planned); #16 Hitscan rifle: `workflow/plans/016-hitscan-rifle.md`, **Done**: merged to main, issue closed 2026-11-26. #17 Static target dummy: `workflow/plans/017-static-target-dummy.md`, **Done**: merged to main, issue closed 2026-11-26. Approach B: pure `TargetHealth` (RefCounted, tick-based) + thin `Dummy` StaticBody3D; dummies under a new root `Targets` node; overlay found via a new `DebugOverlay.GROUP`. #18 Hit feedback: `workflow/plans/018-hit-feedback.md`, **approved** 2026-11-26 (issue body rewritten from Behaviour). Next: the /assets chat delivers the two CC0 sounds, then the Implement chat on `feat/018-hit-feedback`. #25 shot sound/view model and #26 Rifle2/weapon switching split out of #16. Proposed build order: #16 Hitscan rifle → #17 Static target dummy → #18 Hit feedback → #20 Aim stats and score → #19 Moving target dummy → #21 First aim drill (phase 2 gate) → #22 Raw input, sensitivity and FOV matching → #23 Laser weapon → #24 Crosshair settings. Not confirmed by the user yet.

- **Tooling**: #28 Agent workflow efficiency: `workflow/plans/028-agent-efficiency.md`, changes 1-2 merged to main 2026-11-27 (`89c3d61`). #29 Code quality checks: `workflow/plans/029-code-quality-checks.md`, **approved** 2026-11-27, trimmed to code quality the same day (speed changes moved to #28's scope; issue body rewritten from the new Behaviour). Next: the Implement chat on `feat/029-code-quality-checks`.

## Docs written

- `workflow/docs/learning-path.md`: 16 Godot skills in learning order, each with a Box Gym step. Draft, waiting for the user's review.

- `workflow/docs/roadmap.md`: phases 1–7, kept broad on purpose. Each phase has a goal, a pool of example directions, a size range and a gate. We pick a phase's contents when it starts (e.g. phase 3 = "1–3 complex movement techs", not a fixed list). Approved 2026-11-24.

## Open questions

- Bhop balance: what does "balance it somehow" mean (speed cap, smaller gain at high speed, landing penalty, something else)? Decide after a playtest.
- Grapple: rope swing, or stick into a surface and pull (Titanfall 2)?
- Phase 3 order: suggested sliding → down dash → grapple. Not decided.
- #8 is still open although merged (merge commit lacked `Closes #8`).

## Intake (from the vault note, not filed yet)

Source: `C:\Users\maxay\Documents\obsidian stuff\Leo-main-2026\Movement aim trainer.md`, still being written. Re-read it each session for new items. File these as issues when their phase starts (decision 2026-11-26), then delete them here.

- Phase 3, movement techs: sliding; double jump; down dash with slope conversion (dash down into a slope, ricochet off at the matching angle); grapple (retracts on a button press); rocket jumping; bhop balance.
- Phase 3 gotcha: use `move_and_collide` (not only `move_and_slide`) for grapple and down dash, where we need the exact collision normal.
- Phase 4: crosshair builder and import; hitsound/killsound import; more hit marker customisation (from #18 grilling).
- Phase 7 (before any public build): make sure every shipped asset is CC0 or properly licensed (from #18).
- Phase 6: wall/floor/ceiling looks (texture, colour, roughness, transparency, emission); skybox.
