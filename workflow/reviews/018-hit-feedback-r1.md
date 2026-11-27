# Review: 018-hit-feedback (#18), round 1

- Plan: `workflow/plans/018-hit-feedback.md`
- Reviewed commit: `d19432136b5f2bb2a18142a646e4e7fd1044f1a4` (base)
- Diff reviewed: `main...HEAD` was empty. Reviewed the tracked and untracked feature changes in `src/` and `tests/` against that base. The working tree also contained separate edits to the review and implementation instructions.
- Reviewer: Codex (GPT-6)
- check.ps1: passed

## Findings

1. **Bug — A second hit cuts off the first sound before the voice limit.** `src/ui/hit_feedback.gd:56`

   `_play()` assigns the stream on every hit. On the project's Godot 4.7.2 build, I started the shipped hitsound with eight voices available. Reassigning that same stream immediately changed `has_stream_playback()` from true to false. The next `play()` therefore starts with all previous voices cleared. The same helper handles kills. [Godot stream setter](https://github.com/godotengine/godot/blob/master/scene/audio/audio_stream_player_internal.cpp#L224-L235)

   For a concrete firing case, set the supported rifle rate to 64 shots/s and hold fire on a dummy. Hits arrive 15.625 ms apart and the shipped hitsound lasts 18.87 ms. The second shot cuts off the first while seven voice slots are still available. A longer configured sound also exposes this at the default firing rate. Only assign the stream when it changes, and cover two hits while the first voice is still playing. The existing voices test checks the property value alone.

2. **Plan mismatch — The hit test samples initial alpha after a render delay.** `tests/ui/test_hit_feedback.gd:174`

   The plan checks alpha above 0.9 at impact, then checks the view colour after processing. The test waits for both physics and render frames in `_click()` before sampling alpha. At the default 0.25 s fade, the assertion has a 25 ms window. Running this test at 30 FPS returned **0.863804** against the required **> 0.9**. A correct fade can therefore fail the merge check on a slower run. Sample alpha when the hit is delivered and keep the colour assertion after the render update. The planned threshold can stay as written.

## Minor, not fixing

None.

## Verification

Traced dummy damage through both rifle signals and the feedback scene. Checked hit classification and signal order, marker geometry and fade, layer order, live config, toggles, sound selection and volume, the CC0 audio ledger, debug spheres, and the independent player respawn path. The gameplay diff preserves existing tests and exposes the planned feel settings.

```text
Typecheck            59 scripts
GUT scripts          37
Tests               229
Passing Tests       229
Asserts            5224
ALL CHECKS PASSED
```

Captured the running course viewport with F3 visible and the marker duration set to 1 s in memory. One click left Dummy10 at 75 HP. The fourth shot killed Dummy05. The detail is an 8× nearest-neighbour crop of the hit frame. [White hit marker](C:/Users/maxay/AppData/Local/Temp/feat018-review-d9dbb35d9639445f9deebd0e03a03888/hit.png) · [Red kill marker](C:/Users/maxay/AppData/Local/Temp/feat018-review-d9dbb35d9639445f9deebd0e03a03888/kill.png) · [Gap and outline](C:/Users/maxay/AppData/Local/Temp/feat018-review-d9dbb35d9639445f9deebd0e03a03888/detail.png)

## Verdict

fix and run round 2

## Filter result
| # | Verdict | Reason (one line) |
|---|---|---|
| 1 | minor | Real: `_play()` sets `player.stream` on every hit (`src/ui/hit_feedback.gd:56`), and Godot's stream setter stops all voices, so behaviour 7 (up to 8 overlapping voices) is broken. But the shipped hitsound lasts 18.9 ms and the killsound 11.6 ms. Hits come 250 ms apart at the default 4 shots/s and at least 50 ms apart at the slider max of 20, so the first sound has always ended before the next hit. The 64 shots/s case needs a config edit past the slider, and custom sounds are phase 4 (out of scope). No player hears a cut-off in real play. |
| 2 | keep | Confirmed: `test_hit` checks `alpha > 0.9` (line 174) only after `_click()` has waited 2 physics ticks and 2 render frames. The plan's order is to check alpha at the hit, then check the colour after `_process`. With a 0.25 s fade, that leaves about 10 to 17 ms before the assertion fails, so a slow frame or hitch can fail check.ps1 even though the fade is correct. The plan asked for this test, so the player bar doesn't apply. |

Kept: 1 of 2.

Notes: the report says it reviewed `d194321`, but it actually reviewed the uncommitted changes. Those are now commit `a357041`, and I checked both findings against `a357041`. Sound lengths were measured from `assets/audio/hitsound.wav` and `assets/audio/killsound.wav`. The fire-rate range is from `src/weapons/rifle_config.gd:6`.
