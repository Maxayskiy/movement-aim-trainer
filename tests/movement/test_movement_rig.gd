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


func test_air_config_values() -> void:
	var a: SUCCConfig = MovementRig.air_config()
	var t: SUCCConfig = MovementRig.test_config()
	assert_almost_eq(a.air_acceleration, 5.0, 0.0001)
	assert_almost_eq(a.gravity, t.gravity, 0.0001)
	assert_almost_eq(a.jump_height, t.jump_height, 0.0001)
	assert_eq(a.bhop_buffered_jump, t.bhop_buffered_jump)
	assert_almost_eq(a.acceleration, t.acceleration, 0.0001)
	assert_almost_eq(a.friction, t.friction, 0.0001)
	assert_almost_eq(a.stop_speed, t.stop_speed, 0.0001)
	assert_almost_eq(a.max_speed, t.max_speed, 0.0001)
	assert_almost_eq(a.max_air_speed, t.max_air_speed, 0.0001)
	assert_eq(a.enforce_max_velocity, t.enforce_max_velocity)
	assert_almost_eq(a.crouch_speed_modifier, t.crouch_speed_modifier, 0.0001)
	assert_almost_eq(a.sprint_speed_modifier, t.sprint_speed_modifier, 0.0001)


func test_controlled_step_calls_and_trace() -> void:
	_rig.spawn(MovementRig.test_config())
	assert_true(await _rig.settle())
	var calls: Array[int] = []
	var returned: Array[SUCCInput] = []
	var controller: Callable = func(_r: MovementRig, step_tick: int) -> SUCCInput:
		calls.append(step_tick)
		var input: SUCCInput = _forward()
		returned.append(input)
		return input
	var steps: Array[MovementRig.Step] = [MovementRig.Step.controlled(controller, 5)]
	await _rig.play(steps)
	assert_eq(calls, [0, 1, 2, 3, 4] as Array[int])
	assert_eq(_rig.trace.size(), 6)
	if returned.size() != 5 or _rig.trace.size() != 6:
		return
	for i: int in range(1, 6):
		assert_same(_rig.trace[i].input, returned[i - 1], "trace[%d] input" % i)


func test_controlled_step_sees_previous_tick() -> void:
	_rig.spawn(MovementRig.test_config())
	assert_true(await _rig.settle())
	var seen_sizes: Array[int] = []
	var controller: Callable = func(r: MovementRig, _step_tick: int) -> SUCCInput:
		seen_sizes.append(r.trace.size())
		return _forward()
	var steps: Array[MovementRig.Step] = [
		MovementRig.Step.new(_forward(), 3),
		MovementRig.Step.controlled(controller, 2),
	]
	await _rig.play(steps)
	assert_eq(seen_sizes, [4, 5] as Array[int])
