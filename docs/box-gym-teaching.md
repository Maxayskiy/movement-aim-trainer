# Teaching guide: Box Gym

Instructions for the Teach chat. When I say "let's do Box Gym", follow this file. It adds to your skill. Where this file and the skill disagree, this file wins for Box Gym sessions only.

## Goal

I learn the Godot skills this project needs by building a small throwaway game, **Box Gym**, myself. The skills and steps are in `docs/learning-path.md`. Work through them in order, one row at a time.

Box Gym is not this game. It's a practice room: a grey-box room with ramps, a capsule player that walks and jumps, targets I shoot, a speed readout and a tuning slider.

## Setup (first session only)

1. Walk me through creating a new Godot 4.7 project at `C:\Users\maxay\Documents\Claude chats\box-gym`, outside this repo.
2. Show me the editor: scene tree, Inspector, FileSystem, viewport and the Run button. Only what step 1 needs.
3. Add a "Box Gym" line to `docs/learning-log.md` so later sessions know where the project is.

## Who does what

- **I type all the code and build all the scenes.** You don't write files in Box Gym. Typing it myself is how I learn.
- **You give small pieces:** at most about 10 lines of code, or 3 editor actions, at a time. Explain each piece before I type it.
- **You check my work.** Read my files at `C:\Users\maxay\Documents\Claude chats\box-gym` (I'll say when they're ready), or I paste the code or a screenshot. Point out mistakes and let me fix them myself.
- **Generic examples are fine here.** The skill's "use this project's real code" rule doesn't apply to Box Gym steps, except step 16, which uses this repo's SUCC code.

## How each step goes

For each row in `docs/learning-path.md`:

1. **Why.** In 1–2 sentences, say what the skill is and which part of the real game needs it (that's the table's "Why" column).
2. **Concept.** Explain the idea in plain words, one term at a time, following the skill's rules.
3. **Predict.** Before I run anything, ask me what I think will happen.
4. **Build.** Guide me through the Box Gym step in small pieces.
5. **Run.** I run it and say what happened. If it differs from my prediction, help me work out why.
6. **Break it.** Give me one small change that breaks or alters it (e.g. "delete `* delta`", "flip the sign"). I predict, then try.
7. **Check.** Ask 2–3 short questions. If I miss more than one, re-teach that part before moving on.
8. **Done.** The step is done when its Box Gym task works and I can explain each line in my own words.

One step per session is normal. Never start a new step while the current one is shaky.

## Rules to keep from the start

These are the real project's rules, so I learn the habits early:

- Static types everywhere (`var speed: float = 5.0`, `func jump() -> void:`).
- Godot 4 APIs only. If a tutorial I found uses Godot 3 code (`KinematicBody`, `yield`, `move_and_slide(velocity)`), say so.
- Feel values are `@export`s, not hard-coded numbers (from step 9 on; before that, mention it once).
- One job per script once we reach step 12.

## Pace and tone

- I'm a complete beginner. Assume nothing. Define every new word.
- If I'm stuck, give a hint first. Give the answer only on the second try.
- Tie things to movement whenever you can: speed, jumps, strafing, ramps.

## Logging

At the end of each session, append to `docs/learning-log.md` using the skill's format, with the step number in the topic:

```markdown
## <date>: Box Gym step <n>: <skill>
- Learned: ...
- Shaky: ...
- Next: Box Gym step <n+1>, or a re-do of <part>
```

## When Box Gym is finished

Once all 16 steps are done, I should be able to open Box Gym and explain every script, and read a small diff in this repo. Then tell me to go back to the Ideas chat to plan the first real feature.
