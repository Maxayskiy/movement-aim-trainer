# Review: 017-static-target-dummy (#17), round 1

- Plan: workflow/plans/017-static-target-dummy.md
- Reviewed commit: `74ed5f4600f4d48b7e72960a2e4df58afb172f44`
- Diff reviewed: `main...74ed5f4600f4d48b7e72960a2e4df58afb172f44`
- Reviewer: Codex (GPT-6)
- check.ps1: passed

## Findings

1. **Bug — A held shot passes through the dummy on its respawn tick.** `src/targets/dummy.gd:65`
   - The course processes the player's rifle before the dummy. With Rifle1 held on a target, the 128-tick respawn delay is exactly four shot intervals. The shot due on the respawn tick therefore queries the world while the capsule is still disabled. The existing respawn test releases the trigger and clicks again after the signal, so it misses this case.
   - In the running course, Dummy05 died on tick 340. The shot on tick 468 hit the floor and Dummy05 respawned that same tick with 100 HP. In a second run, setting the dummy's physics priority to −1 made the tick-468 shot hit Dummy05 and leave 75 HP. Run the dummy update before the rifle and cover a continuous hold through respawn.

2. **Bug — Unchanged dimensions keep updating the collision shape.** `src/targets/dummy.gd:79`
   - The guard compares the capsule's single-precision dimensions with the config's GDScript floats using exact equality. The shipped radius of 0.4065 m and height of 1.829 m both compare unequal after the engine stores them. Each idle physics tick then writes the capsule dimensions again.
   - With the default config untouched, one dummy emitted 768 `Shape3D.changed` notifications in 128 ticks. This work repeats for each of the five targets, even when the player is elsewhere. Cache the last applied config dimensions or compare at the precision the shape stores.

## Verification

Traced the rifle ray through damage, signal order, collision removal, respawn and player contact. Checked the config defaults, per-instance resources, live edits, F3 labels, station layout, firing line, sign and sight lines against the plan. The diff preserves the existing tests and stays within the planned gameplay files.

In a running-course probe, changing the shared colour updated all five materials. Dropping the player onto the centre of Dummy05 left the feet at y = 1.829134 m with floor contact. The suite covers walking into a living capsule and the two-tick push-out after respawn. The new tests check the saved colour value, while the runtime probe checked application to each material.

```text
Scripts              32
Tests               195
Passing Tests       195
Asserts            5006
ALL CHECKS PASSED
```

Captured the running game's viewport with F3 visible at the firing line. [Five targets](C:/Users/maxay/AppData/Local/Temp/feat017-review-3b02dfd623e941a2babfb109678cc61e/range.png) · [Dummy10 at 50 HP](C:/Users/maxay/AppData/Local/Temp/feat017-review-3b02dfd623e941a2babfb109678cc61e/two-hits.png) · [Dummy05 dead](C:/Users/maxay/AppData/Local/Temp/feat017-review-3b02dfd623e941a2babfb109678cc61e/dead.png) · [Dummy05 respawned at 100 HP](C:/Users/maxay/AppData/Local/Temp/feat017-review-3b02dfd623e941a2babfb109678cc61e/respawned.png)

## Verdict

fix and run round 2
