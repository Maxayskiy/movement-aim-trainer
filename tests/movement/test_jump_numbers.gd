extends GutTest
## Behaviours 6-9 of workflow/plans/008-ground-jump-tests.md.

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _cmd(move: Vector2, jump: bool = false) -> SUCCInput:
	var input: SUCCInput = SUCCInput.new()
	input.move = move
	input.jump = jump
	return input


func _start(config: SUCCConfig) -> void:
	_rig.spawn(config)
	assert_true(await _rig.settle(), "player settles on the floor")


func _play(steps: Array[MovementRig.Step]) -> void:
	await _rig.play(steps)


func _speed_ups(i: int) -> float:
	return MovementRig.ups(MovementRig.horizontal_speed(_rig.trace[i].velocity))


func _index_of_jumped() -> int:
	for i: int in _rig.trace.size():
		if _rig.trace[i].jumped:
			return i
	return -1


func _index_of_landed(after: int) -> int:
	for i: int in range(after + 1, _rig.trace.size()):
		if _rig.trace[i].landed:
			return i
	return -1


func _apex() -> float:
	var apex: float = 0.0
	for s: MovementRig.Sample in _rig.trace:
		apex = maxf(apex, s.position.y - _rig.trace[0].position.y)
	return apex


func _standing_jump() -> void:
	await _play(
		[
			MovementRig.Step.new(_cmd(Vector2.ZERO, true), 1),
			MovementRig.Step.new(SUCCInput.new(), 128),
		]
	)


func _running_jump() -> void:
	await _play(
		[
			MovementRig.Step.new(_cmd(Vector2(0.0, -1.0)), 64),
			MovementRig.Step.new(_cmd(Vector2(0.0, -1.0), true), 1),
			MovementRig.Step.new(SUCCInput.new(), 128),
		]
	)


func test_standing_jump_apex_and_airtime() -> void:
	await _start(MovementRig.test_config())
	await _standing_jump()
	assert_true(_rig.trace[1].jumped, "jumped on tick 1")
	assert_almost_eq(_apex(), 1.143, MovementRig.HEIGHT_TOL_M, "apex")
	var jumped: int = _index_of_jumped()
	var landed: int = _index_of_landed(jumped)
	assert_gt(landed, 0, "landed")
	assert_almost_eq(landed - jumped, 85, MovementRig.TICK_TOL, "airtime ticks")


func test_standing_jump_apex_second_config() -> void:
	await _start(MovementRig.second_config())
	await _standing_jump()
	assert_almost_eq(_apex(), 2.0, MovementRig.HEIGHT_TOL_M, "apex")


func test_takeoff_keeps_speed() -> void:
	await _start(MovementRig.test_config())
	await _running_jump()
	var jumped: int = _index_of_jumped()
	assert_eq(jumped, 65, "jumped on the jump tick")
	if jumped < 1:
		return
	var change: float = _speed_ups(jumped) - _speed_ups(jumped - 1)
	assert_almost_eq(change, 0.0, MovementRig.SPEED_TOL_UPS, "takeoff speed change")


func test_no_air_friction_and_landing_keeps_speed() -> void:
	await _start(MovementRig.test_config())
	await _running_jump()
	var jumped: int = _index_of_jumped()
	var landed: int = _index_of_landed(jumped)
	assert_gt(jumped, 0, "jumped")
	assert_gt(landed, jumped, "landed")
	if jumped < 0 or landed < 0:
		return
	for i: int in range(jumped, landed + 1):
		assert_almost_eq(_speed_ups(i), 400.0, MovementRig.SPEED_TOL_UPS, "tick %d" % i)
	assert_almost_eq(_speed_ups(landed + 1), 387.5, MovementRig.SPEED_TOL_UPS, "one friction tick")


func test_falling() -> void:
	var config: SUCCConfig = MovementRig.test_config()
	_rig.spawn(config, Vector3(0.0, 10.0, 0.0))
	await _play([MovementRig.Step.new(SUCCInput.new(), 64)])
	for k: int in range(1, 65):
		var expected: float = MovementRig.ups(-config.gravity * k / 128.0)
		var actual: float = MovementRig.ups(_rig.trace[k].velocity.y)
		assert_almost_eq(actual, expected, MovementRig.SPEED_TOL_UPS, "tick %d" % k)
	assert_almost_eq(MovementRig.ups(_rig.trace[64].velocity.y), -400.0, MovementRig.SPEED_TOL_UPS)
