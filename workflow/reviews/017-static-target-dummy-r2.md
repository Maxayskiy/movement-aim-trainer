# Review: 017-static-target-dummy (#17), round 2

- Plan: workflow/plans/017-static-target-dummy.md
- Reviewed commit: `74ed5f4600f4d48b7e72960a2e4df58afb172f44` (round-one base and current HEAD).
- Diff reviewed: the two uncommitted files shown by `git diff 74ed5f4 -- src/targets/dummy.gd tests/targets/test_dummy.gd`. Their Git blob hashes were `67154bb39199de38ca1f6f181ccddffa91090cee` and `08ad8f9150cf71327ff5d385a9ca371dd427374e`, respectively.
- Reviewer: Codex (GPT-6)
- check.ps1: passed

## Findings

No findings. The changes address both round-one issues and add a regression test for each. Checked physics ordering against the rifle and player, initial sizing, live resizing, and collision recovery when the player occupies the respawn spot. The diff adds two tests and preserves the existing assertions.

## Previous findings

1. **Fixed — Held fire on the respawn tick.** In the running course, Dummy05 died on tick 340. The next three shots hit the floor. On tick 468, Dummy05 respawned before the rifle fired. That shot hit Dummy05 for 25 damage, leaving 75 HP. The new test checks the hit's tick, remaining health and wall hit count. [F3 screenshot after the respawn-tick hit](C:/Users/maxay/AppData/Local/Temp/feat017-r2-ed03131274d6456482a5d1b23d20c22b/respawned.png)
2. **Fixed — Collision shape updates while idle.** The dummy caches the config width and height after applying them. Over 128 idle ticks with the shipped config, the capsule emitted zero change notifications, down from 768 in round one. The mesh also emitted zero. The idle regression and the existing live-resize test both passed.

## Verification

The focused dummy suite passed all 15 tests at a fixed 60 FPS with 128 Hz physics. The push-out test recorded overlap on the respawn tick and clearance one tick later. The full repository check passed formatting, lint, import, typechecking and GUT.

```text
Scripts              32
Tests               197
Passing Tests       197
Asserts            5014
ALL CHECKS PASSED
```

## Verdict

ready to merge
