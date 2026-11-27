# Review: 018-hit-feedback (#18), round 2

- Plan: `workflow/plans/018-hit-feedback.md`
- Reviewed commit: `01c168f616cd3c3b2e821f81d4a3e68a027fdacc`
- Diff reviewed: `a35704194a344c93196a2f021da463d0da37dfae..01c168f616cd3c3b2e821f81d4a3e68a027fdacc`. The round 1 filter identifies `a357041` as the commit containing the working tree reviewed that round.
- Reviewer: Codex (GPT-6)
- check.ps1: passed

## Findings

No findings. Checked both sound players’ calls to `_play()`, live stream and volume settings, and the two regression cases below.

## Minor, not fixing

None.

## Previous findings

1. **Overlapping sounds — fixed.** The round 1 filter classified this as minor. The shared playback helper now assigns a stream only when the configured resource changes. The new test fires two shots at 64 shots/s with a one-second hitsound and verifies that the first voice’s playback position continues to advance after the second hit.
2. **Hit-marker alpha timing — fixed.** The test samples alpha in the synchronous hitsound callback, after the fade starts, and checks the view colour after processing. It keeps the planned threshold of `> 0.9`. All 17 hit-feedback tests passed at the 30 FPS cap that reproduced the round 1 failure.

## Verification

| Run | Tests passed | Assertions |
| --- | ---: | ---: |
| Full `check.ps1` on Godot 4.7.2 | 230/230 | 5,228 |
| Hit-feedback suite at 30 FPS | 17/17 | 105 |

## Verdict

ready to merge
