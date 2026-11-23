# Movement Aim Trainer — design (1 page)

## Pitch
A first-person **customizable movement aim trainer**. Fast Source-style movement plus aiming practice, where players tune the movement themselves.

## Engine
Godot 4.7.2+, typed GDScript. Movement is built on the SUCC addon (github.com/bearlikelion/SUCC, MIT).

## Core: movement
Source-style movement that keeps momentum:
- Bunny hopping (bhop) and air strafing
- Surfing
- Tap strafing
- Wall bounces
- Superglide
- Rocket jumps
- Grapple that keeps momentum (Titanfall 2 style)

**Players can tune it.** Every value that affects feel is exposed as a setting (sliders), not hard-coded.

## Core: aim
Targets and aim drills played while moving. Stats, sensitivity and FOV matching to other games (M4).

## Planned extras
- **Arcade modes**, for example **Exhaust**: dodge bullets, hit enemies, life steal, endless chasing enemies.
- Players load **their own models and maps**.
- Maybe: movement items.
- Maybe: a pixelated low-res look.
- Eventually: a **Steam release**.

## Quality bar
One finished piece first: a movement test course that feels right before anything else is built (M1).

## Non-goals (for now)
Multiplayer, story, monetization.
