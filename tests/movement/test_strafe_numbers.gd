extends GutTest
## Behaviours 6-9 of workflow/plans/010-bhop-strafe-tests.md.

const RUN_UP: int = 64
const FIRST_LANDED: int = 150

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


func _forward(ticks: int, jump: bool = false) -> MovementRig.Step:
	return MovementRig.Step.new(_cmd(Vector2(0.0, -1.0), jump), ticks)


func _start(config: SUCCConfig) -> SUCC:
	var player: SUCC = _rig.spawn(config)
	assert_true(await _rig.settle(), "player settles on the floor")
	return player


func _speed_ups(i: int) -> float:
	return MovementRig.ups(MovementRig.horizontal_speed(_rig.trace[i].velocity))


static func _landed_indices(trace: Array[MovementRig.Sample], from: int) -> Array[int]:
	var out: Array[int] = []
	for i: int in range(from, trace.size()):
		if trace[i].landed:
			out.append(i)
	return out


## Strafes right with a jump on the first tick until the first landing, then idle.
func _one_hop(config: SUCCConfig) -> int:
	var player: SUCC = await _start(config)
	var controller: Callable = func(r: MovementRig, step_tick: int) -> SUCCInput:
		if not _landed_indices(r.trace, RUN_UP + 1).is_empty():
			return SUCCInput.new()
		return PerfectStrafer.input(player, 1, step_tick == 0)
	await _rig.play([_forward(RUN_UP), MovementRig.Step.controlled(controller, 100)])
	var landed: Array[int] = _landed_indices(_rig.trace, RUN_UP + 1)
	assert_false(landed.is_empty(), "landed")
	return landed[0] if not landed.is_empty() else -1


# Behaviour 6, config T.
func test_one_perfect_strafe_hop() -> void:
	var l: int = await _one_hop(MovementRig.test_config())
	assert_true(_rig.trace[RUN_UP + 1].jumped, "jumped on tick 65")
	assert_almost_eq(l, FIRST_LANDED, MovementRig.TICK_TOL, "L")
	if l < 0:
		return
	assert_almost_eq(_speed_ups(l), 487.2, MovementRig.SPEED_TOL_UPS, "landing speed")
	for i: int in range(RUN_UP + 1, l + 1):
		assert_gt(_speed_ups(i), _speed_ups(i - 1), "tick %d faster" % i)


# Behaviour 6, config A.
func test_one_perfect_strafe_hop_air_config() -> void:
	var l: int = await _one_hop(MovementRig.air_config())
	if l < 0:
		return
	assert_almost_eq(_speed_ups(l), 468.6, MovementRig.SPEED_TOL_UPS, "landing speed")


# Behaviour 7.
func test_five_perfect_strafe_hops() -> void:
	var player: SUCC = await _start(MovementRig.test_config())
	var controller: Callable = func(r: MovementRig, _step_tick: int) -> SUCCInput:
		var landings: int = _landed_indices(r.trace, RUN_UP + 1).size()
		if landings >= 5:
			return SUCCInput.new()
		return PerfectStrafer.input(player, 1 if landings % 2 == 0 else -1, true)
	await _rig.play([_forward(RUN_UP), MovementRig.Step.controlled(controller, 440)])
	var landed: Array[int] = _landed_indices(_rig.trace, RUN_UP + 1)
	assert_eq(landed.size(), 5, "5 landings %s" % [landed])
	var expected: Array[float] = [487.2, 561.1, 626.3, 685.3, 739.6]
	for k: int in mini(landed.size(), expected.size()):
		assert_almost_eq(
			_speed_ups(landed[k]), expected[k], MovementRig.SPEED_TOL_UPS, "landing %d" % (k + 1)
		)
	for k: int in mini(landed.size(), 4):
		assert_true(_rig.trace[landed[k] + 1].jumped, "landing %d then jumped" % (k + 1))


# Behaviour 8.
func test_strafe_without_turning_gains_almost_nothing() -> void:
	await _start(MovementRig.test_config())
	await _rig.play(
		[_forward(RUN_UP), _forward(1, true), MovementRig.Step.new(_cmd(Vector2(1.0, 0.0)), 90)]
	)
	var landed: Array[int] = _landed_indices(_rig.trace, RUN_UP + 2)
	assert_false(landed.is_empty(), "landed")
	var l: int = landed[0] if not landed.is_empty() else _rig.trace.size() - 1
	assert_almost_eq(_speed_ups(66), 401.1, MovementRig.SPEED_TOL_UPS, "after first D tick")
	var top: float = 0.0
	for i: int in range(66, l + 1):
		top = maxf(top, _speed_ups(i))
	assert_lte(top, 402.1, "max speed before landing")


# Behaviour 9.
func test_air_brake() -> void:
	await _start(MovementRig.test_config())
	await (
		_rig
		. play(
			[
				_forward(RUN_UP),
				_forward(1, true),
				MovementRig.Step.new(_cmd(Vector2(0.0, 1.0)), 3),
				MovementRig.Step.new(SUCCInput.new(), 10),
			]
		)
	)
	assert_almost_eq(_speed_ups(66), 87.5, MovementRig.SPEED_TOL_UPS, "after 1 S tick")
	assert_lt(_rig.trace[66].velocity.z, 0.0, "still moving forward")
	assert_almost_eq(_speed_ups(67), 30.0, MovementRig.SPEED_TOL_UPS, "after 2 S ticks")
	assert_gt(_rig.trace[67].velocity.z, 0.0, "moving backward")
	assert_almost_eq(_speed_ups(68), 30.0, MovementRig.SPEED_TOL_UPS, "after 3 S ticks")
