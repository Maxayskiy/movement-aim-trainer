# Review: 001-player-base (#1), round 1

- Plan: workflow/plans/001-player-base.md
- Reviewed commit: 8f53169f6a30e3bf6b1b91235e51af5cf5a6dc32
- Diff reviewed: main...8f53169f6a30e3bf6b1b91235e51af5cf5a6dc32
- Reviewer: Codex (GPT-6)
- check.ps1: passed (20 tests, 78 assertions)

## Findings

1. **bug**: `src/player/respawn.gd:24` — A grounded player can jump in midair immediately after respawn.
   - What's wrong: Respawn clears velocity and restores the transform. The body retains its previous floor contact, which SUCC reads when deciding whether to accept a jump on the next physics tick.
   - Failure scenario: Stand on the spawn pad and press R and Space before the next physics tick. In the running course, the player returned to y = 1.0 with zero velocity, 0.65 m above the pad, while `is_on_floor()` still returned true. One tick later the player had emitted a jump and reached y = 1.052626 with upward velocity 6.73616 m/s. Refresh floor contact at the destination and cover this grounded respawn case. Holding Space should trigger the first jump on landing.

2. **plan mismatch**: `tests/movement/test_respawn.gd:60` — The fall test checks only the return position.
   - What's wrong: Behaviour 9 requires falling to restore the same yaw, pitch and velocity as pressing R. Only the R and direct-call tests assert those values.
   - Failure scenario: If the fall handler only assigned the start position, a player looking down while falling would arrive still looking down and moving downward. All existing assertions would pass. Displace and rotate the player, set pitch and downward velocity, then reuse `_assert_at_start()` after the kill-height tick.

## Verification

The branch preserves the course geometry and spawn transform. The new player uses the SUCC root script and default configuration with the planned sprint override. The physical key bindings, input accumulation setting, 128 Hz physics rate, movement flags and HUD match the plan. The diff adds four test scripts and edits no existing tests or addon files.

`check.ps1` output:

```text
Scripts               5
Tests                20
Passing Tests        20
Asserts              78
ALL CHECKS PASSED
```

The 300-frame headless boot exited successfully. Its complete output was:

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
```

A scripted run of the actual course exercised walking, jumping, held-Space bhopping, Left Ctrl crouching, R, falling through the kill height, and Esc/click mouse release and recapture. W and W+Shift both reached 10.16 m/s. A fall with nonzero velocity, yaw and pitch restored all four values in the reviewed build. The game viewport capture with `--debug-collisions` showed the first-person spawn view with the crosshair as the only HUD element.

## Verdict

fix and run round 2

## Filter result
| # | Verdict | Reason (one line) |
|---|---|---|
| 1 | keep | Confirmed. `respawn.gd:22-26` only sets velocity and calls `teleport()`, and `teleport()` (`succ.gd:177-180`) sets the transform without refreshing floor contact. On the next tick, `simulate` calls `_set_floor_type`, which reads the stale `is_on_floor()` (`succ.gd:813`) and sets FLOOR. `_set_velocity` then accepts `wish_jump` (`succ.gd:414`). `was_on_floor` also stays true. Holding Space with buffered bhop is enough to trigger the mid-air jump after a grounded respawn. |
| 2 | drop | The failure is hypothetical: the fall path calls the same `respawn()` as R (`respawn.gd:36-37`), so yaw, pitch and velocity are already reset. The test also does what the plan's "How to test" asks for the fall case (respawn at y = -31). This is a wish for more test coverage, not a real bug or plan mismatch. |

Kept: 1 of 2.

## Owner decision
- Finding 1: dropped by the owner, who could not replicate it in play. Not fixed.

No findings left to fix in round 1.
