# Learning path: Godot skills for this game

The skills you need to understand this project, in learning order. Each one adds a piece to a throwaway practice game, **Box Gym**. The Teach chat uses this list.

**Box Gym:** a grey-box room with ramps. You walk and jump around it, shoot targets, and watch a speed readout. Keep it in its own Godot project, outside this repo (e.g. `Documents/Claude chats/box-gym`). Throw it away when you're done.

| # | Skill | Why this game needs it | Box Gym step |
|---|-------|------------------------|--------------|
| 1 | **Editor, nodes, scenes.** The scene tree, saving a scene, instancing one scene inside another. | Everything in Godot is built this way: the player, levels and targets. | Make a room scene from a floor and walls. Make a separate `target.tscn` and place 3 copies of it. |
| 2 | **GDScript basics with static types.** Variables, functions, `if`, loops, `: float` / `-> void`. | All code. Project rule: static types everywhere. | A script that prints the target count when the game starts. |
| 3 | **The game loop.** `_ready`, `_process` and `_physics_process`, plus `delta`. | Movement runs in physics frames. Feel depends on frame-rate-independent maths. | Rotate a cube at the same speed at 30 fps and at 144 fps. |
| 4 | **Input.** Input Map actions, `Input.is_action_pressed`, `_unhandled_input`, capturing the mouse. | Strafing keys, jumping, mouse look. | Map WASD, Space and Escape. Escape frees the mouse. |
| 5 | **3D vectors and transforms.** `Vector3`, `normalized()`, `dot()`, `basis`, local vs global directions. | **The core of air strafing and bhop.** Air strafing is built on one dot product. | Print the player's speed and "forward" direction. Draw them as lines. |
| 6 | **CharacterBody3D.** `velocity`, `move_and_slide()`, `is_on_floor()`, collision shapes, floor angle, slide collisions. | The player body. Bhop, surfing (steep slopes) and wall bounces all live here. | A capsule player that walks, jumps and slides down a steep ramp. |
| 7 | **First-person camera.** Yaw on the body, pitch on a head node, sensitivity, FOV. | Mouse look, sensitivity matching, FOV matching. | Mouse look with a sensitivity value and pitch clamped at ±89°. |
| 8 | **Raycasts, collision layers and Area3D.** `RayCast3D`, space-state queries, layers and masks. | Hitscan aiming, grapple attach point, rocket-jump blast, trigger zones. | Click to shoot. A hit target changes colour. A trigger zone at the finish line. |
| 9 | **Exports and Resources.** `@export`, custom `Resource` classes, saving settings with `ConfigFile`. | Project rule: every feel value is a slider. A settings resource holds them. | Put jump height and gravity in a `MoveSettings` resource and tune them in the Inspector. |
| 10 | **UI.** Control nodes, a CanvasLayer HUD, `Label`, `HSlider`, signals from UI. | Speedometer, stats, the tuning sliders menu. | A speed label on screen, plus an in-game slider that changes jump height live. |
| 11 | **Signals.** Defining, emitting and connecting them. | Target hit → score. Slider changed → setting. Loose coupling between parts. | The target emits `hit`. A score label listens for it. |
| 12 | **Composition: small nodes with one job.** Child nodes as components. A simple state machine. | Project rule: one movement tech per file in `src/player/techs/`. | Split "jump" and "walk" into two child-node scripts that the player calls. |
| 13 | **Autoloads and scene switching.** Global singletons, `change_scene_to_file`. | Settings shared everywhere, menu → course → arcade mode. | A main menu scene with a Play button, and a global `Settings` autoload. |
| 14 | **Debugging.** `print`, breakpoints, the remote scene tree, on-screen debug draws. | Reading why movement feels wrong. Proof screenshots with overlays. | Pause on a breakpoint mid-jump and inspect `velocity`. |
| 15 | **Tests with GUT.** Writing a test, running it, reading a failure. | Project rule: `tools/check.ps1` must pass. Implement writes tests you'll review. | A test that checks your jump reaches the expected height. |
| 16 | **Reading an addon.** Finding your way around someone else's code. | Movement sits on top of SUCC (`addons/SUCC/`). | (In this repo, not Box Gym.) The Teach chat walks you through SUCC's player script. |

## Later, when a feature needs it

Skip these for now. Learn each one when a plan uses it.

- Spawning scenes at runtime (rockets, enemies): `instantiate()`, `queue_free()`.
- Timers and tweens (cooldowns, effects).
- Audio.
- Shaders (the pixelated low-res look).
- Loading user files at runtime (custom maps and models).
- Exporting builds and Steam.

## Done when

You can open Box Gym, explain what each script does line by line, and read a small diff in this repo and say what it changes in how the game feels.
