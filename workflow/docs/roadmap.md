# Roadmap
Status: approved

The order we build things in and how much effort each part gets. Each phase has a **goal**, a **pool** of example directions to pick from, and a **gate** that must pass before the next phase starts. The pools are examples, not commitments: when a phase starts, we choose its contents in the Ideas chat, and anything that fits the goal is allowed. A "feature" is half a day of work with one plan file in `workflow/plans/`. Sizes are rough guesses.

## Principles

1. **Movement first, and most effort on it.** Everything sits on top of it, and the design doc's quality bar is "a movement test course that feels right".
2. **Grey boxes until late.** No art, sound or menu polish until the game is fun with plain boxes.
3. **One thing at a time.** Feature → plan → build → review → you understand it (Teach chat) → next.
4. **Playable at the end of every phase.**
5. **Build on a base that feels right.** Don't add to movement or aim that feels wrong. Fix it first.
6. **Decide late.** Pick a phase's contents when it starts, using what we learned in the phases before.

## Phases

| # | Phase | Goal | Pool (examples) | Size | Gate |
|---|-------|------|-----------------|------|------|
| 1 | **Movement base** | A player you can control, and simple momentum-keeping movement that feels good. | Player on SUCC, mouse look, debug overlay, ground movement and friction, jumping, bhop, air strafing, a settings resource, a first test course. | ~8–12 features | You play the course and the base movement feels right. Key numbers are covered by tests. |
| 2 | **Aim base** | You can shoot while you move, and see how well you did. | Hitscan rifle and laser, target dummies (static, moving), hitsounds, basic crosshair settings, 1–2 drills, stats, raw input, sensitivity and FOV matching. | ~5–8 features | First playable: move, shoot, see your score. |
| 3 | **Movement depth** | Add **1–3 complex movement techs** that give the movement a skill ceiling. | Sliding, double jump, down dash (slope conversion), grapple, rocket jumps, bhop balance, or something new. | ~2–5 features per tech | Each tech feels right and passes its tests before the next one starts. |
| 4 | **Game shell** | Someone else can start, tune and play the game without help. | Main menu, settings menu with sliders, save/load, presets, course/drill select, pause, onboarding, crosshair builder and import, hitsound import. | ~4–6 features | A friend plays it without you explaining anything. |
| 5 | **Content and modes** | Add **1–2 things to do** beyond the base drills. | An arcade mode (e.g. Exhaust), new drills, new courses, time trials, a score/leaderboard loop. | ~5–10 features per mode | Each one is fun for 5 minutes on its own. |
| 6 | **Second pass** | Go back and deepen whatever playtests say is weakest. | More movement techs, more aim drills, more modes, movement items, user maps/models, wall/floor/ceiling looks and skybox, a visual style (e.g. pixelated low-res). | Plan each one when we get there | — |
| 7 | **Release** | Ship it on Steam. | Polish (art, sound, UI), export builds, Steam page, playtests, performance. Remove the `_mcp_game_helper` autoload. | ~6+ features | Release. |

Phases 3–6 can repeat in loops (depth → content → depth) for as long as the game gets better from it.

## Choosing within a phase

When a phase starts, pick its contents in the Ideas chat using these questions:
- **Does it fit the goal?** If not, put it in the backlog.
- **What does the gate need?** Pick the smallest set of features that passes it.
- **What's cheapest given what we have?** Prefer options that reuse what's built (e.g. surfing reuses air strafing).
- **What does playtesting say?** Fix the weakest part before adding a new one.

## How much effort per feature

- Each feature gets half a day. If it runs over, stop and split it.
- Feel work (phases 1 and 3) gets playtest time on top: play, tune the sliders, write down what feels off, then plan a fix.
- Everything else gets "good enough". Make it work and test it, then move on.

## Next step

Phase 2 started 2026-11-26, before the phase 1 gate (your call). Phase 1's tuning panel and gate playtest wait in the backlog.
