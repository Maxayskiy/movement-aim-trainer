# Review: 016-hitscan-rifle (#16), round 1

- Plan: workflow/plans/016-hitscan-rifle.md
- Reviewed commit: `88130d768c1db039621fd7d40a9d825a0e9dc993` (base)
- Diff reviewed: `main...88130d768c1db039621fd7d40a9d825a0e9dc993` was empty. The review includes the three modified tracked files and the untracked implementation and tests on `feat/016-hitscan-rifle`.
- Reviewer: Codex (GPT-6)
- check.ps1: passed, 164 tests and 4,770 assertions

## Findings

1. **Bug — Esc can leave the trigger held.** `src/weapons/rifle.gd:75`
   - The rifle clears the trigger on the next physics tick only if the mouse is still free. SUCC can recapture the mouse on another button press before that tick.
   - In the running course, I held left mouse, pressed Esc, then pressed right mouse before the next tick. Godot confirmed that Esc freed the mouse and right click recaptured it. The rifle fired three shots over the next 72 ticks without another left press. Clear the latch and held state when capture is lost.

2. **Plan mismatch — A live rate change keeps the old cooldown.** `src/weapons/fire_timer.gd:17`
   - The setter updates the rate used for damage and future intervals. The existing deadline still uses the previous interval.
   - I fired at tick 0 at 1 shot/s, switched to 20 shots/s before tick 1, and kept holding. The next shot fired at tick 128. At the new rate, an interval is 6.4 ticks. Updating the active cooldown when the rate changes would make the setting take effect during that hold.

3. **Bug — Fractional cadence depends on the starting tick.** `src/weapons/fire_timer.gd:38`
   - Repeatedly adding the fractional interval can place a mathematically integral deadline just above its tick. The strict readiness comparison then delays the shot by a tick.
   - A Godot probe starting at tick 100 and holding at 10 shots/s produced `100, 113, 126, 139, 152, 165`. The sixth shot is due at `100 + 5 × 12.8 = 164`. The current tests check exact ticks only for the first 128 ticks starting at zero. Check the sequence from a nonzero start as well.

4. **Bug — The dropped-tap test can inject its last click late.** `tests/weapons/test_rifle.gd:103`
   - Each call to `_ticks()` also waits for a render frame. Godot can run extra physics steps before that frame, so the waits used to schedule the three test inputs can exceed their stated tick counts.
   - Running the unchanged rifle suite with `--fixed-fps 60` produced 11/12 passing tests. Line 214 reported `[43] expected to equal [40]`. Schedule the test inputs against physics-frame numbers and retain the exact 40-tick assertion.

5. **Plan mismatch — The held-origin test cannot distinguish the two eyes.** `tests/weapons/test_rifle.gd:180`
   - The player stands still while the test changes yaw. The rendered and physics eyes therefore share a position when the second shot fires.
   - If the held-shot branch used `aim(OriginSource.VIEW)`, it would still pass the origin, direction and wall-hit assertions here. Separate the two positions at the held-shot tick and assert that the origin matches the physics eye.

6. **Bug — A zero marker limit still creates a marker.** `src/debug/hit_markers.gd:72`
   - The exported integer accepts zero. Once the eviction loop runs out of entries, the function always adds a mesh.
   - I set `max_markers = 0` with the panel visible and emitted a hit. `marker_count()` returned 1. Return before allocating for a zero limit, or enforce a positive minimum on the setting.

## Verification

Traced the fire binding through input dispatch, click latching, the parent physics update, the ray query, damage, and the shot and respawn signals. Checked the all-layer body mask, player exclusion, area filtering, miss endpoint, configuration defaults, marker expiry and eviction, and crosshair offsets. The gameplay and test files follow the approved file list. All feature tests are new.

The standard repository check completed formatting, lint, import, typechecking and GUT.

```text
Scripts              29
Tests               164
Passing Tests       164
Asserts            4770
ALL CHECKS PASSED
```

The off-screen game viewport showed the F3 panel and a trail of red hits on the strafe-lane wall. At 1920 × 1080 the white glyph spanned x = 956–964 and y = 536–544, centered at (960, 540). Hiding just the crosshair exposed a red marker at that same pixel. [Debug screenshot](C:/Users/maxay/AppData/Local/Temp/feat016-review-0bad093f533d49fc995afadb19e5df50/debug.png)

## Verdict

fix and run round 2

## Filter result
| # | Verdict | Reason (one line) |
|---|---|---|
| 1 | drop | `rifle.gd:75` does exactly what plan behaviour 2 says ("the next tick clears held"). Triggering it takes Esc plus another mouse press inside one input frame (about 8-16 ms) while holding left, which is not a realistic play scenario. |
| 2 | drop | Plan behaviour 7 sets the next shot time as "next due += interval" when a shot fires, and nothing asks to reschedule a cooldown already running. Live slider tuning is #15 (out of scope), and the worst case is a delay of up to 1 s once. |
| 3 | keep | Confirmed. Adding 12.8 five times to 100 gives 164.00000000000003, so the `now >= _next_due` check fires on tick 165. The rifle passes `Engine.get_physics_frames()`, which is never 0 in game, so behaviour 7 ("first tick >= next due") really breaks. |
| 4 | keep | `_ticks()` waits for a physics frame and then a process frame, and check.ps1 runs headless without `--fixed-fps`. A slow frame can run several physics steps, so the exact 40-tick assert at line 214 can fail at random on a loaded machine. |
| 5 | drop | The test follows the plan's own test spec, and the code being tested (`HELD_SHOT` -> `aim(PHYSICS_EYE)`) is correct. This asks for a stronger test, not a fix for a bug or a plan mismatch. |
| 6 | drop | `max_markers` is a debug-only export that defaults to 64 and no one sets it to 0. Guarding against it is a "could be more robust" idea with no current need. |

Kept: 2 of 6.
