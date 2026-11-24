# Roadmap
Status: draft

The order we build things in and how much effort each part gets. Each phase ends with a **gate**: a check that must pass before the next phase starts. A "feature" is half a day of work with one plan file in `docs/plans/`. Sizes are rough guesses, and we'll correct them as we go.

## Principles

1. **Movement first, and most effort on it.** Everything else sits on top of it, and the design doc's quality bar is "a movement test course that feels right". About 40% of the effort before the extras goes here.
2. **Grey boxes until late.** No art, sound or menu polish until the game is fun with plain boxes.
3. **One thing at a time.** One feature → plan → build → review → you understand it (Teach chat) → next.
4. **Playable at the end of every phase.** Never more than a phase away from something you can play.
5. **Add a tech only when the current ones feel right.** A new tech on a bad base hides the problem.

## Phases

| # | Phase | What's in it | Size | Gate |
|---|-------|--------------|------|------|
| 1 | **Movement core** | Player on SUCC, mouse look, debug overlay (speed, velocity line), ground move + friction, jump, **bhop**, **air strafe**, a settings resource with all feel values, test course v1. | ~10 features | You play the course, and bhop + air strafe feel right to you. Speed gain matches expected numbers in tests. |
| 2 | **Aim core** | Hitscan gun, targets, one drill (static targets while moving), stats (accuracy, hits, time), sensitivity + FOV matching. | ~6 features | First playable: move + shoot + see your score. |
| 3 | **More techs** | One tech at a time, each with its own section on the test course: **surf** → **tap strafe** → **wall bounce** → **superglide** → **rocket jump** → **grapple**. | Surf, tap strafe, wall bounce: ~2 each. Superglide: ~2. Rocket jump: ~3. Grapple: ~5. | Each tech passes its own tests and feels right before the next one starts. |
| 4 | **Game shell** | Main menu, settings menu with sliders, save/load settings, presets ("Source", "Apex"…), course/drill select, pause. | ~5 features | Someone else can start the game, tune it and play without your help. |
| 5 | **Arcade: Exhaust** | Enemies that chase, bullets to dodge, life steal, endless waves, score. | ~8 features | A run is fun for 5 minutes. |
| 6 | **Extras** | Pick from: user maps/models, pixel look, movement items, more drills and modes. | Plan each one when we get there | — |
| 7 | **Steam** | Polish pass (art, sound, UI), export builds, Steam page, playtests. Remove the `_mcp_game_helper` autoload. | ~6+ features | Release. |

## Why this order

- **Techs order (phase 3):** cheapest first, and each one builds on the last. Surf reuses air strafing on slopes. Tap strafe and wall bounce are small tweaks. Rocket jump needs projectiles and explosions. Grapple is the biggest (rope physics, momentum keeping), so it comes last.
- **Aim before more techs:** after phase 2, the game is a real (small) aim trainer. More techs make it better, but you have a game at every step.
- **Shell after techs:** menus are cheap to build but slow to change. Build them once the list of settings has settled.

## How much effort per feature

- Each feature is timeboxed to half a day. If it runs over, stop and split it.
- Feel work (phases 1 and 3) gets playtest time on top: play, tune the sliders, write down what feels off, then plan a fix.
- Everything else gets "good enough". Make it work and test it, then move on.

## Next step

Plan the first phase-1 feature, **Player on SUCC + mouse look + debug overlay**, once you're at about Box Gym step 6.
