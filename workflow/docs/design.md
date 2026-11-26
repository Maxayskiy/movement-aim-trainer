# Movement Aim Trainer — design (1 page)

## Pitch
A first-person **customizable movement aim trainer**. Fast Source-style movement plus aiming practice, where players tune the movement themselves.

## Engine
Godot 4.7.2+, typed GDScript. Movement is built on the SUCC addon (github.com/bearlikelion/SUCC, MIT).

## Core: movement
Source-style movement that keeps momentum:
- Run and jump
- Bunny hopping (bhop) and air strafing (balanced somehow; how is open)
- Surfing (SUCC surf, switched on)
- Sliding
- Double jump
- Down dash: dashing down into a slope converts the speed, so you ricochet off the slope at the matching angle
- Grapple that keeps momentum and retracts on a button press (open: rope swing, or stick into a surface and pull)
- Rocket jumps

**Players can tune it.** Every value that affects feel is exposed as a setting (sliders), not hard-coded.

## Core: aim
Targets and aim drills played while moving. Raw mouse input, hitscan weapons with infinite range and no damage falloff: Rifle1 (4 shots per second default, slider, hold to fire), Rifle2 (10 shots per second default, tap only) and a laser. Rifle damage per shot = DPS ÷ fire rate, so DPS stays the same when the fire rate changes. Stats, sensitivity and FOV matching to other games.

## Core: customisation
Beyond movement sliders, players can change:
- Enemy dummies: size, movement speed, gravity
- Crosshair: a builder, or import your own
- Hitsounds and killsounds
- Wall, floor and ceiling looks: texture, colour, roughness, transparency, emission
- Skybox

## Planned extras
- **Arcade modes**, for example **Exhaust**: dodge bullets, hit enemies, life steal, endless chasing enemies.
- Players load **their own models and maps**.
- Maybe: movement items.
- Maybe: a pixelated low-res look.
- Eventually: a **Steam release**.

## Quality bar
One finished piece first: a movement test course that feels right before anything else is built.
