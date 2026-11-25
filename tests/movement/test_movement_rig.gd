extends GutTest

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _forward() -> SUCCInput:
	var input: SUCCInput = SUCCInput.new()
	input.move = Vector2(0.0, -1.0)
	return input


func test_test_config_values() -> void:
	var c: SUCCConfig = MovementRig.test_config()
	assert_almost_eq(c.gravity, 20.32, 0.0001)
	assert_almost_eq(c.jump_height, 1.143, 0.0001)
	assert_true(c.bhop_buffered_jump)
	assert_almost_eq(c.acceleration, 7.5, 0.0001)
	assert_almost_eq(c.friction, 4.0, 0.0001)
	assert_almost_eq(c.stop_speed, 4.0, 0.0001)
	assert_almost_eq(c.max_speed, 10.16, 0.0001)
	assert_almost_eq(c.air_acceleration, 100.0, 0.0001)
	assert_almost_eq(c.max_air_speed, 0.762, 0.0001)
	assert_false(c.enforce_max_velocity)
	assert_almost_eq(c.crouch_speed_modifier, 1.0 / 3.0, 0.0001)
	assert_almost_eq(c.sprint_speed_modifier, 1.0, 0.0001)


func test_second_config_values() -> void:
	var c: SUCCConfig = MovementRig.second_config()
	assert_almost_eq(c.max_speed, 8.0, 0.0001)
	assert_almost_eq(c.jump_height, 2.0, 0.0001)
	assert_almost_eq(c.friction, 6.0, 0.0001)
	assert_almost_eq(c.gravity, 20.32, 0.0001)
	assert_almost_eq(c.acceleration, 7.5, 0.0001)
	assert_almost_eq(c.stop_speed, 4.0, 0.0001)
	assert_almost_eq(c.air_acceleration, 100.0, 0.0001)
	assert_almost_eq(c.max_air_speed, 0.762, 0.0001)
	assert_almost_eq(c.crouch_speed_modifier, 1.0 / 3.0, 0.0001)
	assert_almost_eq(c.sprint_speed_modifier, 1.0, 0.0001)


func test_settle_rests_on_floor() -> void:
	var player: SUCC = _rig.spawn(MovementRig.test_config())
	assert_true(await _rig.settle())
	assert_eq(player.floor_type, SUCC.FloorType.FLOOR)
	assert_lt(MovementRig.horizontal_speed(player.velocity), 0.001)


func test_trace_indexing() -> void:
	_rig.spawn(MovementRig.test_config())
	assert_true(await _rig.settle())
	var steps: Array[MovementRig.Step] = [
		MovementRig.Step.new(_forward(), 10),
		MovementRig.Step.new(SUCCInput.new(), 5),
	]
	await _rig.play(steps)
	assert_eq(_rig.trace.size(), 16)
	for i: int in _rig.trace.size():
		assert_eq(_rig.trace[i].tick, i)
	for i: int in range(1, 11):
		assert_eq(_rig.trace[i].input.move, Vector2(0.0, -1.0), "tick %d forward" % i)
	for i: int in range(11, 16):
		assert_eq(_rig.trace[i].input.move, Vector2.ZERO, "tick %d idle" % i)


func test_first_sample_used_first_step() -> void:
	_rig.spawn(MovementRig.test_config())
	assert_true(await _rig.settle())
	var steps: Array[MovementRig.Step] = [MovementRig.Step.new(_forward(), 1)]
	await _rig.play(steps)
	var speed: float = MovementRig.horizontal_speed(_rig.trace[1].velocity)
	assert_almost_eq(MovementRig.ups(speed), 23.4, MovementRig.SPEED_TOL_UPS)
