extends GutTest
## Behaviours 1-5 of workflow/plans/008-ground-jump-tests.md.

const STOPPED_MPS: float = 0.001
const TOP_SPEED_MARGIN_MPS: float = 0.01

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _cmd(move: Vector2, crouch: bool = false, sprint: bool = false) -> SUCCInput:
	var input: SUCCInput = SUCCInput.new()
	input.move = move
	input.crouch = crouch
	input.sprint = sprint
	return input


func _forward() -> SUCCInput:
	return _cmd(Vector2(0.0, -1.0))


func _start(config: SUCCConfig) -> void:
	_rig.spawn(config)
	assert_true(await _rig.settle(), "player settles on the floor")


func _play(steps: Array[MovementRig.Step]) -> void:
	await _rig.play(steps)


func _speed_ups(i: int) -> float:
	return MovementRig.ups(MovementRig.horizontal_speed(_rig.trace[i].velocity))


func _max_speed_ups() -> float:
	var top: float = 0.0
	for i: int in _rig.trace.size():
		top = maxf(top, _speed_ups(i))
	return top


func _assert_top_speed(expected_ups: float, at: int) -> void:
	assert_lte(_max_speed_ups(), expected_ups + MovementRig.SPEED_TOL_UPS, "never above top")
	assert_almost_eq(_speed_ups(at), expected_ups, MovementRig.SPEED_TOL_UPS, "ends at top")


# Index of the first sample in [from, trace.size()) below STOPPED_MPS, or -1.
func _first_stopped(from: int) -> int:
	for i: int in range(from, _rig.trace.size()):
		if MovementRig.horizontal_speed(_rig.trace[i].velocity) < STOPPED_MPS:
			return i
	return -1


func test_top_speed_forward() -> void:
	await _start(MovementRig.test_config())
	await _play([MovementRig.Step.new(_forward(), 128)])
	_assert_top_speed(400.0, 128)


func test_top_speed_diagonal() -> void:
	await _start(MovementRig.test_config())
	await _play([MovementRig.Step.new(_cmd(Vector2(1.0, -1.0).normalized()), 128)])
	_assert_top_speed(400.0, 128)


func test_top_speed_second_config() -> void:
	await _start(MovementRig.second_config())
	await _play([MovementRig.Step.new(_forward(), 128)])
	_assert_top_speed(315.0, 128)


func test_time_to_top_speed() -> void:
	var config: SUCCConfig = MovementRig.test_config()
	await _start(config)
	await _play([MovementRig.Step.new(_forward(), 64)])
	var reached: int = -1
	for i: int in _rig.trace.size():
		var speed: float = MovementRig.horizontal_speed(_rig.trace[i].velocity)
		if speed >= config.max_speed - TOP_SPEED_MARGIN_MPS:
			reached = i
			break
	assert_almost_eq(reached, 25, MovementRig.TICK_TOL, "tick top speed is reached")
	if reached < 0:
		return
	var distance: float = MovementRig.horizontal_distance(
		_rig.trace[0].position, _rig.trace[reached].position
	)
	assert_almost_eq(distance, 1.138, MovementRig.DISTANCE_TOL_M, "distance to top speed")


func test_stopping() -> void:
	await _start(MovementRig.test_config())
	await _play([MovementRig.Step.new(_forward(), 64), MovementRig.Step.new(SUCCInput.new(), 80)])
	var stopped: int = _first_stopped(65)
	assert_almost_eq(stopped - 64, 62, MovementRig.TICK_TOL, "idle tick speed reaches 0")
	if stopped < 0:
		return
	var distance: float = MovementRig.horizontal_distance(
		_rig.trace[64].position, _rig.trace[stopped].position
	)
	assert_almost_eq(distance, 1.976, MovementRig.DISTANCE_TOL_M, "stopping distance")


func test_stopping_second_config() -> void:
	await _start(MovementRig.second_config())
	await _play([MovementRig.Step.new(_forward(), 64), MovementRig.Step.new(SUCCInput.new(), 80)])
	var stopped: int = _first_stopped(65)
	assert_almost_eq(stopped - 64, 36, MovementRig.TICK_TOL, "idle tick speed reaches 0")


func test_crouch_walk() -> void:
	await _start(MovementRig.test_config())
	await _play([MovementRig.Step.new(_cmd(Vector2(0.0, -1.0), true), 256)])
	_assert_top_speed(133.3, 256)


func test_no_sprint() -> void:
	await _start(MovementRig.test_config())
	await _play([MovementRig.Step.new(_cmd(Vector2(0.0, -1.0), false, true), 128)])
	_assert_top_speed(400.0, 128)
