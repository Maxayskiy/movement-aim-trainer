extends GutTest
## Behaviour 10 of workflow/plans/008-ground-jump-tests.md and of
## workflow/plans/010-bhop-strafe-tests.md: prints the shipped config's movement
## numbers. No asserts on them.

const CONFIG_PATH: String = "res://src/player/player_config.tres"
const TICK_RATE: float = 128.0
const STOPPED_MPS: float = 0.001
const TOP_SPEED_MARGIN_MPS: float = 0.01
## Run-up for the bhop and strafe lines: long enough for a retuned config.
const RUN_UP: int = 128

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

	# Behaviour 10 of workflow/plans/010-bhop-strafe-tests.md.
	var hop_period: int = await _hop_period(forward)
	var strafe: Dictionary = await _strafe_chain(forward)
	var brake_ticks: int = await _air_brake_ticks(forward)

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
		"hop period       %d ticks" % hop_period,
		"strafe 1 hop     %d u/s" % roundi(strafe["one"]),
		"strafe 5 hops    %d u/s" % roundi(strafe["five"]),
		"strafe turn      %d deg/s at top speed" % roundi(strafe["turn"]),
		"air brake        %d ticks" % brake_ticks,
	]
	gut.p("\n".join(lines))
	pass_test("report printed")


## Back to the spawn point, stopped, yaw 0, resting on the floor.
func _reset() -> void:
	_rig.player.teleport(Transform3D(Basis.IDENTITY, Vector3(0.0, 0.01, 0.0)))
	_rig.player.velocity = Vector3.ZERO
	assert_true(await _rig.settle(), "player settles on the floor")


func _jump_cmd(input: SUCCInput) -> SUCCInput:
	var out: SUCCInput = SUCCInput.new()
	out.move = input.move
	out.jump = true
	return out


## Ticks between the first two jumps of a held forward+jump chain.
func _hop_period(forward: SUCCInput) -> int:
	await _reset()
	await _rig.play(
		[MovementRig.Step.new(forward, RUN_UP), MovementRig.Step.new(_jump_cmd(forward), 256)]
	)
	var jumps: Array[int] = []
	for i: int in _rig.trace.size():
		if _rig.trace[i].jumped:
			jumps.append(i)
	return jumps[1] - jumps[0] if jumps.size() >= 2 else -1


## Perfect strafe chain (as in behaviour 7): speeds at the 1st and 5th landing
## (u/s) and the first tick's turn rate (deg/s).
func _strafe_chain(forward: SUCCInput) -> Dictionary:
	await _reset()
	var player: SUCC = _rig.player
	var controller: Callable = func(r: MovementRig, _step_tick: int) -> SUCCInput:
		var landings: int = 0
		for i: int in range(RUN_UP + 1, r.trace.size()):
			if r.trace[i].landed:
				landings += 1
		if landings >= 5:
			return SUCCInput.new()
		return PerfectStrafer.input(player, 1 if landings % 2 == 0 else -1, true)
	await _rig.play(
		[MovementRig.Step.new(forward, RUN_UP), MovementRig.Step.controlled(controller, 640)]
	)
	var landed: Array[int] = []
	for i: int in range(RUN_UP + 1, _rig.trace.size()):
		if _rig.trace[i].landed:
			landed.append(i)
	var before: Vector3 = _rig.trace[RUN_UP].velocity
	var after: Vector3 = _rig.trace[RUN_UP + 1].velocity
	var turn: float = Vector2(before.x, before.z).angle_to(Vector2(after.x, after.z))
	return {
		"one": MovementRig.ups(_speed(landed[0])) if landed.size() >= 1 else -1.0,
		"five": MovementRig.ups(_speed(landed[4])) if landed.size() >= 5 else -1.0,
		"turn": absf(rad_to_deg(turn)) * TICK_RATE,
	}


## Ticks of S after a W jump from top speed until the velocity along the run
## direction is <= 0.
func _air_brake_ticks(forward: SUCCInput) -> int:
	await _reset()
	var back: SUCCInput = SUCCInput.new()
	back.move = Vector2(0.0, 1.0)
	await (
		_rig
		. play(
			[
				MovementRig.Step.new(forward, RUN_UP),
				MovementRig.Step.new(_jump_cmd(forward), 1),
				MovementRig.Step.new(back, 32),
			]
		)
	)
	var run: Vector3 = _rig.trace[RUN_UP].velocity
	run = Vector3(run.x, 0.0, run.z).normalized()
	for k: int in range(1, 33):
		if _rig.trace[RUN_UP + 1 + k].velocity.dot(run) <= 0.0:
			return k
	return -1
