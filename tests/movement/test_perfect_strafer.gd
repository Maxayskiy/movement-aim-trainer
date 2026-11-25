extends GutTest
## PerfectStrafer helper of workflow/plans/010-bhop-strafe-tests.md.

const DT: float = 1.0 / 128.0
const ANGLE_TOL_DEG: float = 0.01

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _wish(cmd: SUCCInput) -> Vector3:
	return Vector3(cmd.move.x, 0.0, cmd.move.y).rotated(Vector3.UP, cmd.yaw)


func _player(config: SUCCConfig) -> SUCC:
	var player: SUCC = _rig.spawn(config)
	player.velocity = Vector3(0.0, 0.0, -10.16)
	return player


func test_optimal_angle_test_config() -> void:
	var theta: float = PerfectStrafer.optimal_angle(MovementRig.test_config(), 10.16, DT)
	assert_almost_eq(rad_to_deg(theta), 90.0, ANGLE_TOL_DEG)


func test_optimal_angle_air_config() -> void:
	var theta: float = PerfectStrafer.optimal_angle(MovementRig.air_config(), 10.16, DT)
	assert_almost_eq(rad_to_deg(theta), 87.94, ANGLE_TOL_DEG)


func test_side_right_is_90_deg_right() -> void:
	var player: SUCC = _player(MovementRig.test_config())
	var wish: Vector3 = _wish(PerfectStrafer.input(player, 1, false))
	assert_almost_eq(rad_to_deg(player.velocity.angle_to(wish)), 90.0, ANGLE_TOL_DEG)
	assert_lt(player.velocity.cross(wish).y, 0.0, "wish is right of velocity")


func test_side_left_is_90_deg_left() -> void:
	var player: SUCC = _player(MovementRig.test_config())
	var wish: Vector3 = _wish(PerfectStrafer.input(player, -1, false))
	assert_almost_eq(rad_to_deg(player.velocity.angle_to(wish)), 90.0, ANGLE_TOL_DEG)
	assert_gt(player.velocity.cross(wish).y, 0.0, "wish is left of velocity")


func test_air_config_angle() -> void:
	var player: SUCC = _player(MovementRig.air_config())
	var right: Vector3 = _wish(PerfectStrafer.input(player, 1, false))
	var left: Vector3 = _wish(PerfectStrafer.input(player, -1, false))
	assert_almost_eq(rad_to_deg(player.velocity.angle_to(right)), 87.94, ANGLE_TOL_DEG)
	assert_lt(player.velocity.cross(right).y, 0.0, "D wish is right of velocity")
	assert_almost_eq(rad_to_deg(player.velocity.angle_to(left)), 87.94, ANGLE_TOL_DEG)
	assert_gt(player.velocity.cross(left).y, 0.0, "A wish is left of velocity")


func test_jump_and_pitch() -> void:
	var player: SUCC = _player(MovementRig.test_config())
	var with_jump: SUCCInput = PerfectStrafer.input(player, 1, true)
	var without_jump: SUCCInput = PerfectStrafer.input(player, -1, false)
	assert_true(with_jump.jump)
	assert_false(without_jump.jump)
	assert_eq(with_jump.pitch, 0.0)
	assert_eq(without_jump.pitch, 0.0)
	assert_false(with_jump.crouch or with_jump.sprint)
