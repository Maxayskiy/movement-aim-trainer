class_name PerfectStrafer
extends RefCounted
## Inputs for a perfect air strafe: only A or D held, yaw set so the wish
## direction is at the optimal angle to the horizontal velocity.

const MIN_SPEED_MPS: float = 0.001


## Optimal wish angle to the velocity, in radians. a = per-tick air push,
## cap = max_air_speed: PI/2 when a >= cap, else acos((cap - a) / speed).
static func optimal_angle(config: SUCCConfig, speed: float, dt: float) -> float:
	var a: float = config.air_acceleration * config.max_speed * dt
	var cap: float = config.max_air_speed
	if a >= cap:
		return PI / 2.0
	return acos(clampf((cap - a) / speed, -1.0, 1.0))


## side +1 = D (wish to the right of the velocity), -1 = A (to the left).
static func input(player: SUCC, side: int, jump: bool) -> SUCCInput:
	var cmd: SUCCInput = SUCCInput.new()
	cmd.move = Vector2(float(side), 0.0)
	cmd.jump = jump
	cmd.pitch = 0.0
	cmd.yaw = player.rotation.y
	var h_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
	var speed: float = h_velocity.length()
	if speed < MIN_SPEED_MPS:
		return cmd
	var dt: float = 1.0 / Engine.physics_ticks_per_second
	var theta: float = optimal_angle(player.config, speed, dt)
	# A negative turn about UP is to the right.
	var wish: Vector3 = (h_velocity / speed).rotated(Vector3.UP, -float(side) * theta)
	# SUCC's wish is Vector3(side, 0, 0).rotated(UP, yaw) = side * (cos, 0, -sin).
	cmd.yaw = atan2(-float(side) * wish.z, float(side) * wish.x)
	return cmd
