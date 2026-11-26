class_name DummyConfig
extends Resource
## Values shared by every dummy that uses this resource. Dummies read it every
## physics tick, so edits apply while the game runs.

## Capsule width in metres (radius = width / 2).
@export_range(0.3, 3.0, 0.01) var width: float = 0.813
## Full capsule height in metres. A height under width counts as width.
@export_range(0.5, 4.0, 0.01) var height: float = 1.829
## Health of a fresh dummy. At least 1.
@export var max_health: float = 100.0
## Seconds from death to respawn.
@export_range(0.0, 10.0, 0.1) var respawn_delay: float = 1.0
@export var color: Color = Color(1.0, 0.45, 0.0)
