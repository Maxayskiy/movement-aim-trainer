class_name SpeedUtils
extends RefCounted
## Small helpers for reading the player's speed (used later by the speed meter).


## Speed along the ground plane, ignoring vertical (Y) movement.
static func horizontal_speed(velocity: Vector3) -> float:
	return Vector2(velocity.x, velocity.z).length()


## Converts m/s to whole Source units per second (u/s).
static func to_ups(meters_per_second: float) -> int:
	return roundi(meters_per_second * SUCCConfig.SOURCE_MULT)
