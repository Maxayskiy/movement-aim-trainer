extends GutTest
## Behaviours 1-5 of workflow/plans/010-bhop-strafe-tests.md.

const RUN_UP: int = 64
const TOP_UPS: float = 400.0
const HOP_PERIOD: int = 86
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


func _new_rig() -> void:
	_rig.queue_free()
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func _speed_ups(i: int) -> float:
	return MovementRig.ups(MovementRig.horizontal_speed(_rig.trace[i].velocity))


func _jumped_indices(from: int, to: int) -> Array[int]:
	var out: Array[int] = []
	for i: int in range(from, mini(to + 1, _rig.trace.size())):
		if _rig.trace[i].jumped:
			out.append(i)
	return out


func _landed_indices(from: int, to: int) -> Array[int]:
	var out: Array[int] = []
	for i: int in range(from, mini(to + 1, _rig.trace.size())):
		if _rig.trace[i].landed:
			out.append(i)
	return out


func _assert_speed_from(from: int, to: int, expected: float) -> void:
	for i: int in range(from, to + 1):
		assert_almost_eq(_speed_ups(i), expected, MovementRig.SPEED_TOL_UPS, "tick %d speed" % i)


func _assert_floor_after(index: int, label: String) -> void:
	for i: int in range(index + 1, _rig.trace.size()):
		assert_eq(
			_rig.trace[i].floor_type, SUCC.FloorType.FLOOR, "%s: tick %d on floor" % [label, i]
		)


# Behaviours 1 and 2.
func test_bhop_chain_keeps_speed() -> void:
	await _start(MovementRig.test_config())
	var held_ticks: int = 430
	await _rig.play([_forward(RUN_UP), _forward(held_ticks, true), _forward(20)])
	var held_end: int = RUN_UP + held_ticks
	var jumps: Array[int] = _jumped_indices(RUN_UP + 1, held_end)
	assert_gte(jumps.size(), 5, "at least 5 jumps: %s" % [jumps])
	if jumps.is_empty():
		return
	assert_eq(jumps[0], RUN_UP + 1, "first jump")
	for k: int in range(1, jumps.size()):
		assert_almost_eq(jumps[k] - jumps[k - 1], HOP_PERIOD, MovementRig.TICK_TOL, "hop %d" % k)
	# A landing on the held step's last tick has no held tick after it.
	for l: int in _landed_indices(RUN_UP + 1, held_end - 1):
		assert_true(_rig.trace[l + 1].jumped, "landed %d then jumped" % l)
	_assert_speed_from(RUN_UP, held_end, TOP_UPS)


func _no_buffer_variants() -> Array[Dictionary]:
	var off_config: SUCCConfig = MovementRig.test_config()
	off_config.bhop_buffered_jump = false
	return [
		{"name": "bhop_buffered_jump off", "config": off_config, "enable_bhop": true},
		{"name": "enable_bhop off", "config": MovementRig.test_config(), "enable_bhop": false},
	]


func _start_no_buffer(variant: Dictionary) -> void:
	var player: SUCC = await _start(variant["config"] as SUCCConfig)
	player.enable_bhop = variant["enable_bhop"] as bool


## Play 1 of 3b/3c. It runs twice and L comes from the second run: the player
## rests about 1 mm higher after a landing than after settle(), which lands
## 1 tick later, and play 2 starts after a landing.
func _landed_index_of_one_jump() -> int:
	for _run: int in 2:
		await _rig.play([_forward(RUN_UP), _forward(1, true), _forward(120)])
	return _first_landed_after_jump()


func _first_landed_after_jump() -> int:
	var landed: Array[int] = _landed_indices(RUN_UP + 2, _rig.trace.size() - 1)
	return landed[0] if not landed.is_empty() else -1


# Behaviour 3a.
func test_no_buffer_holding_jump_jumps_once() -> void:
	for variant: Dictionary in _no_buffer_variants():
		var label: String = variant["name"]
		_new_rig()
		await _start_no_buffer(variant)
		await _rig.play([_forward(RUN_UP), _forward(200, true)])
		var jumps: Array[int] = _jumped_indices(0, _rig.trace.size() - 1)
		assert_eq(jumps, [RUN_UP + 1] as Array[int], "%s: one jump" % label)
		var landed: Array[int] = _landed_indices(0, _rig.trace.size() - 1)
		assert_eq(landed.size(), 1, "%s: one landing" % label)
		if landed.size() != 1:
			continue
		assert_almost_eq(landed[0], FIRST_LANDED, MovementRig.TICK_TOL, "%s: landed" % label)
		_assert_floor_after(landed[0], label)


# Behaviour 3b.
func test_no_buffer_press_on_landed_tick_is_lost() -> void:
	for variant: Dictionary in _no_buffer_variants():
		var label: String = variant["name"]
		_new_rig()
		await _start_no_buffer(variant)
		var l: int = await _landed_index_of_one_jump()
		assert_gt(l, 0, "%s: play 1 landed" % label)
		if l <= 0:
			continue
		await _rig.play([_forward(RUN_UP), _forward(1, true), _forward(l - 66), _forward(60, true)])
		assert_true(_rig.trace[l].landed, "%s: trace[L] landed" % label)
		assert_true(_rig.trace[l].input.jump, "%s: jump held on trace[L]" % label)
		assert_false(_rig.trace[l - 1].input.jump, "%s: press starts on trace[L]" % label)
		var jumps: Array[int] = _jumped_indices(0, _rig.trace.size() - 1)
		assert_eq(jumps.size(), 1, "%s: one jump %s" % [label, jumps])
		_assert_floor_after(l, label)


# Behaviour 3c.
func test_no_buffer_press_on_first_floor_tick_jumps() -> void:
	for variant: Dictionary in _no_buffer_variants():
		var label: String = variant["name"]
		_new_rig()
		await _start_no_buffer(variant)
		var l: int = await _landed_index_of_one_jump()
		assert_gt(l, 0, "%s: play 1 landed" % label)
		if l <= 0:
			continue
		await (
			_rig
			. play(
				[
					_forward(RUN_UP),
					_forward(1, true),
					_forward(l - 65),
					_forward(1, true),
					_forward(40),
				]
			)
		)
		assert_true(_rig.trace[l].landed, "%s: trace[L] landed" % label)
		assert_true(_rig.trace[l + 1].jumped, "%s: jumped on L + 1" % label)
		assert_almost_eq(
			_speed_ups(l + 1), TOP_UPS, MovementRig.SPEED_TOL_UPS, "%s: speed L + 1" % label
		)


# Behaviour 4.
func test_late_jump_above_top_speed_costs_speed() -> void:
	var player: SUCC = await _start(MovementRig.test_config())
	var controller: Callable = func(r: MovementRig, step_tick: int) -> SUCCInput:
		var l: int = -1
		for i: int in range(RUN_UP + 1, r.trace.size()):
			if r.trace[i].landed:
				l = i
				break
		if l < 0:
			return PerfectStrafer.input(player, 1, step_tick == 0)
		return _cmd(Vector2.ZERO, r.trace.size() == l + 5)
	await _rig.play([_forward(RUN_UP), MovementRig.Step.controlled(controller, 120)])
	var landed: Array[int] = _landed_indices(RUN_UP + 1, _rig.trace.size() - 1)
	assert_false(landed.is_empty(), "landed")
	if landed.is_empty():
		return
	var l: int = landed[0]
	var expected: Array[float] = [487.2, 472.0, 457.3, 443.0, 429.1]
	for k: int in expected.size():
		assert_almost_eq(
			_speed_ups(l + k), expected[k], MovementRig.SPEED_TOL_UPS, "trace[L + %d]" % k
		)
	assert_true(_rig.trace[l + 5].jumped, "jumped on L + 5")
	assert_almost_eq(_speed_ups(l + 5), 429.1, MovementRig.SPEED_TOL_UPS, "trace[L + 5]")


# Behaviour 5.
func test_late_jump_at_top_speed_costs_nothing() -> void:
	await _start(MovementRig.test_config())
	await _rig.play(
		[_forward(RUN_UP), _forward(1, true), _forward(89), _forward(1, true), _forward(20)]
	)
	var jumps: Array[int] = _jumped_indices(0, _rig.trace.size() - 1)
	assert_eq(jumps.size(), 2, "two jumps %s" % [jumps])
	var landed: Array[int] = _landed_indices(0, _rig.trace.size() - 1)
	assert_false(landed.is_empty(), "landed")
	if jumps.size() == 2 and not landed.is_empty():
		assert_almost_eq(jumps[1] - landed[0] - 1, 4, MovementRig.TICK_TOL, "ground ticks")
	_assert_speed_from(RUN_UP, _rig.trace.size() - 1, TOP_UPS)
