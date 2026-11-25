extends GutTest
## Behaviour 10 of workflow/plans/008-ground-jump-tests.md: prints the shipped
## config's movement numbers. No asserts on them.

const CONFIG_PATH: String = "res://src/player/player_config.tres"
const TICK_RATE: float = 128.0
const STOPPED_MPS: float = 0.001
const TOP_SPEED_MARGIN_MPS: float = 0.01

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _speed(i: int) -> float:
	return MovementRig.horizontal_speed(_rig.trace[i].velocity)


func test_print_shipped_config_numbers() -> void:
	var config: SUCCConfig = load(CONFIG_PATH) as SUCCConfig
	_rig.spawn(config)
	if not await _rig.settle():
		fail_test("player did not settle")
		return

	var forward: SUCCInput = SUCCInput.new()
	forward.move = Vector2(0.0, -1.0)
	var jump: SUCCInput = SUCCInput.new()
	jump.jump = true

	# Top speed and time to it: forward 128 ticks, then idle 256 to stop.
	await _rig.play(
		[MovementRig.Step.new(forward, 128), MovementRig.Step.new(SUCCInput.new(), 256)]
	)
	var top: float = _speed(128)
	var top_tick: int = -1
	for i: int in range(0, 129):
		if _speed(i) >= config.max_speed - TOP_SPEED_MARGIN_MPS:
			top_tick = i
			break
	var top_dist: float = (
		MovementRig.horizontal_distance(_rig.trace[0].position, _rig.trace[top_tick].position)
		if top_tick >= 0
		else 0.0
	)
	var stop_tick: int = -1
	for i: int in range(129, _rig.trace.size()):
		if _speed(i) < STOPPED_MPS:
			stop_tick = i
			break
	var stop_dist: float = (
		MovementRig.horizontal_distance(_rig.trace[128].position, _rig.trace[stop_tick].position)
		if stop_tick >= 0
		else 0.0
	)
	var stop_ticks: int = stop_tick - 128 if stop_tick >= 0 else -1

	# Standing jump: settle again, jump 1 tick, idle until well after landing.
	assert_true(await _rig.settle())
	await _rig.play([MovementRig.Step.new(jump, 1), MovementRig.Step.new(SUCCInput.new(), 256)])
	var apex: float = 0.0
	var jumped: int = -1
	var landed: int = -1
	for i: int in _rig.trace.size():
		var s: MovementRig.Sample = _rig.trace[i]
		apex = maxf(apex, s.position.y - _rig.trace[0].position.y)
		if s.jumped and jumped < 0:
			jumped = i
		elif s.landed and jumped >= 0 and landed < 0:
			landed = i
	var airtime: int = landed - jumped if landed >= 0 else -1

	var lines: PackedStringArray = [
		"Movement numbers: %s @ %d Hz" % [CONFIG_PATH, int(TICK_RATE)],
		"top speed        %d u/s" % roundi(MovementRig.ups(top)),
		"0 -> top speed   %d ticks   %.3f s   %.3f m" % [top_tick, top_tick / TICK_RATE, top_dist],
		(
			"stop from top    %d ticks   %.3f s   %.3f m"
			% [stop_ticks, stop_ticks / TICK_RATE, stop_dist]
		),
		"jump apex        %.3f m" % apex,
		"airtime          %d ticks   %.3f s" % [airtime, airtime / TICK_RATE],
	]
	gut.p("\n".join(lines))
	pass_test("report printed")
