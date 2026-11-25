# Review: 005-debug-overlay (#5), round 1

- Plan: workflow/plans/005-debug-overlay.md
- Reviewed commit: 91c8d4b30c8d772f3336612a4accd090d9a2c3a5
- Diff reviewed: main...91c8d4b30c8d772f3336612a4accd090d9a2c3a5
- Reviewer: Codex (GPT-6)
- check.ps1: passed (46 tests, 195 assertions)

## Findings

1. **bug**: `src/debug/perf_sampler.gd:44` — The first `ticks/s` sample includes ticks from before its measurement window.
   - What's wrong: Godot can run physics before the overlay's first render callback. Each tick increments `_ticks`, and the first `add_frame` starts the clock with those ticks still in the counter.
   - Failure scenario: In Godot, four ticks before the first frame followed by 32 ticks during a 0.25 s window produced **144 ticks/s**. The measured window ran at **128 ticks/s**. Discard pre-window ticks and include that sequence in the sampler tests.

2. **plan mismatch**: `levels/test_course/test_course.tscn:407` — The branch changes the course collision boundaries and the game window.
   - What's wrong: The plan explicitly preserves the course and limits the project settings change to the F3 binding. The branch extends the floor, moves three barriers and sets a project-wide 1920×1080 viewport at `project.godot:27`.
   - Failure scenario: From x = 16, moving toward negative z used to meet the south barrier at approximately z = −44. The same player can now pass through that position and continue toward z = −168. Launching the game also requests the larger window. Split those changes into a separate issue so merging the overlay preserves the playtest baseline.

3. **plan mismatch**: `.claude/skills/teach/SKILL.md:7` — The branch also changes the teaching workflow.
   - What's wrong: Commit `91c8d4b` changes the learner level and session log format and adds an unrelated entry to `workflow/state/learning-log.md`. The branch also reserializes `src/player/player_config.tres` outside the approved file list. Its effective velocity-cap settings are equivalent at this commit.
   - Failure scenario: After merging #5, the next Teach session would assume intermediate experience and use a log template that omits the previous “Shaky” prompt. Keep the teaching changes in their own change and omit the unrelated resource diff.

4. **plan mismatch**: `tests/debug/test_debug_overlay.gd:141` — The performance-line test accepts an empty or nonnumeric reading.
   - What's wrong: The plan calls for the scene test to verify numbers for all five readings. The assertions only require a matching label and the absence of the em dash.
   - Failure scenario: A rendered line of `frame    ms` passes both assertions with no frame time displayed. Check the value on each line, including the two decimal places and unit for the three time readings.

## Verification

Reviewed all eleven behaviours, the player and respawn signal paths, the SUCC jump and landing call sites, all seven export defaults and ranges, and the scene layout and input map. The diff adds tests without weakening earlier assertions. The movement integration test exercises held-jump chains against live SUCC physics. The unit tests cover the chain limit, extra landings, gain, reset and consecutive sampling windows. The tracker tests check gain numerically, while the in-game capture below verifies its signed display at zero.

`check.ps1` completed formatting, lint, import, typechecking and GUT:

```text
Scripts               9
Tests                46
Passing Tests        46
Asserts             195
ALL CHECKS PASSED
```

The running course showed 0, IDLE and FLOOR at rest, 400 u/s running forward, and RAMP on the surf ramp. Clicking inside the panel recaptured the mouse. On the bhop strip, the panel showed three hops, zero ground ticks, +0 gain and 127 ticks/s. Physical F3 hid the panel and left the 400 speedometer visible. R cleared the chain and preserved the hidden panel. A second F3 restored it.

The viewport captures used a 1152×648 window and are stored outside the repository. [Mid-chain overlay](C:/Users/maxay/AppData/Local/Temp/review-005-1a7e9575f5564fc2a4a41e3ea369cf16/panel.png) · [After F3](C:/Users/maxay/AppData/Local/Temp/review-005-1a7e9575f5564fc2a4a41e3ea369cf16/speedometer.png)

## Verdict

fix and run round 2
