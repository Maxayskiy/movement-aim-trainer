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


func _ray_down(from: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = _rig.get_viewport().get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, from + Vector3.DOWN * 20.0
	)
	return space.intersect_ray(query)


func _static_bodies() -> int:
	var count: int = 0
	for child: Node in _rig.get_children():
		if child is StaticBody3D:
			count += 1
	return count


func test_test_config_step_height() -> void:
	assert_almost_eq(MovementRig.test_config().step_height, 0.45, 0.0001)


func test_spawn_without_floor() -> void:
	_rig.spawn(MovementRig.test_config(), Vector3(0.0, 0.01, 0.0), false)
	assert_eq(_static_bodies(), 0, "no floor added")


func test_spawn_pins_floor_angles() -> void:
	var player: SUCC = _rig.spawn(MovementRig.test_config())
	assert_almost_eq(rad_to_deg(player.ramp_angle_threshold), 45.0, 0.0001)
	assert_almost_eq(rad_to_deg(player.max_floor_angle), 45.0, 0.0001)
	assert_eq(_static_bodies(), 1, "default floor added")


func test_add_box() -> void:
	var size: Vector3 = Vector3(2.0, 0.6, 3.0)
	var at: Vector3 = Vector3(5.0, 0.3, -4.0)
	var body: StaticBody3D = _rig.add_box(size, at)
	assert_eq(body.get_parent(), _rig)
	var shape: CollisionShape3D = body.get_child(0) as CollisionShape3D
	assert_not_null(shape)
	if shape == null:
		return
	assert_eq((shape.shape as BoxShape3D).size, size)
	assert_almost_eq(shape.global_position.distance_to(at), 0.0, 0.0001)
	await get_tree().physics_frame
	var hit: Dictionary = _ray_down(Vector3(5.0, 5.0, -4.0))
	assert_false(hit.is_empty(), "ray hits the box")
	if hit.is_empty():
		return
	assert_almost_eq((hit["position"] as Vector3).y, 0.6, 0.001)


func test_add_ramp_30() -> void:
	var low_edge: Vector3 = Vector3(1.0, 0.2, -2.0)
	_rig.add_ramp(30.0, low_edge, 6.0, 4.0)
	await get_tree().physics_frame
	var at_edge: Dictionary = _ray_down(Vector3(1.0, 10.0, -2.0005))
	var one_up: Dictionary = _ray_down(Vector3(1.0, 10.0, -3.0))
	assert_false(at_edge.is_empty(), "ray hits at the low edge")
	assert_false(one_up.is_empty(), "ray hits one metre up")
	if at_edge.is_empty() or one_up.is_empty():
		return
	assert_almost_eq((at_edge["position"] as Vector3).y, 0.2, 0.001, "low edge height")
	var rise: float = (one_up["position"] as Vector3).y - 0.2
	assert_almost_eq(rise, tan(deg_to_rad(30.0)), 0.001, "rise per horizontal metre")
	var normal: Vector3 = one_up["normal"]
	assert_almost_eq(rad_to_deg(normal.angle_to(Vector3.UP)), 30.0, 0.1, "normal angle")
