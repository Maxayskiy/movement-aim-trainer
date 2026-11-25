class_name BhopTracker
extends RefCounted
## Tracks bhop chains from jump and landing physics frames. Pure logic, no nodes.

## A hop with more ground ticks than this starts a new chain.
var max_chain_ground_ticks: int = 0

## Jumps in the current chain (0 before the first jump).
var hops: int = 0
var has_takeoff: bool = false
## Horizontal speed (m/s) at the last jump.
var last_takeoff_speed: float = 0.0
var has_gain: bool = false
## Takeoff speed change (m/s) from the previous hop in the chain.
var last_gain: float = 0.0
## Ground ticks before the last jump; -1 = no landing before it.
var last_ground_ticks: int = -1

var _last_land_frame: int = 0
var _landings_since_jump: int = 0


func on_landed(physics_frame: int) -> void:
	_last_land_frame = physics_frame
	_landings_since_jump += 1


func on_jumped(physics_frame: int, horizontal_speed: float) -> void:
	if _landings_since_jump > 0:
		last_ground_ticks = physics_frame - _last_land_frame - 1
	else:
		last_ground_ticks = -1
	var extends_chain: bool = (
		hops > 0 and _landings_since_jump == 1 and last_ground_ticks <= max_chain_ground_ticks
	)
	if extends_chain:
		hops += 1
		has_gain = true
		last_gain = horizontal_speed - last_takeoff_speed
	else:
		hops = 1
		has_gain = false
		last_gain = 0.0
	has_takeoff = true
	last_takeoff_speed = horizontal_speed
	_landings_since_jump = 0


func reset() -> void:
	hops = 0
	has_takeoff = false
	last_takeoff_speed = 0.0
	has_gain = false
	last_gain = 0.0
	last_ground_ticks = -1
	_last_land_frame = 0
	_landings_since_jump = 0
