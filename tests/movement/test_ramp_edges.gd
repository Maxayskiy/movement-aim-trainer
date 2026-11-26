extends GutTest
## Behaviour 4 of workflow/plans/012-hull-terrain-tests.md.

const TOP_UPS: float = 400.0
const RAMP_LENGTH: float = 6.0
const RAMP_WIDTH: float = 10.0
## Low edge z: top speed (1.138 m) plus 5 m before it.
const LOW_EDGE_Z: float = -6.2
const PLATFORM_DEPTH: float = 20.0
const PAST_PLATFORM_EDGE: float = 3.0
const PAST_LOW_EDGE: float = 5.0
const EDGE_ZONE: float = 1.0
## Run-up on the platform before the 3 m start mark.
const PLATFORM_RUN_UP: float = 2.0

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _new_rig() -> void:
	_rig.queue_free()
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func _forward(ticks: int, yaw: float = 0.0) -> MovementRig.Step:
	var input: SUCCInput = SUCCInput.new()
	input.move = Vector2(0.0, -1.0)
	input.yaw = yaw
	return MovementRig.Step.new(input, ticks)


func _speed_ups(i: int) -> float:
	return MovementRig.ups(MovementRig.horizontal_speed(_rig.trace[i].velocity))


## Ramp rising toward -Z from LOW_EDGE_Z and a platform flush with its top.
## Returns the z of the top edge.
func _build(angle_deg: float) -> float:
	var angle: float = deg_to_rad(angle_deg)
	var height: float = RAMP_LENGTH * sin(angle)
	var top_z: float = LOW_EDGE_Z - RAMP_LENGTH * cos(angle)
	_rig.add_ramp(angle_deg, Vector3(0.0, 0.0, LOW_EDGE_Z), RAMP_LENGTH, RAMP_WIDTH)
	_rig.add_box(
		Vector3(RAMP_WIDTH, height + 1.0, PLATFORM_DEPTH),
		Vector3(0.0, (height - 1.0) / 2.0, top_z - PLATFORM_DEPTH / 2.0)
	)
	return top_z


func _first_index(from: int, test: Callable) -> int:
	for i: int in range(from, _rig.trace.size()):
		if test.call(_rig.trace[i]):
			return i
	return -1


func _assert_no_speed_drop(from: int, to: int, label: String) -> void:
	for i: int in range(from + 1, to + 1):
		var drop: float = _speed_ups(i - 1) - _speed_ups(i)
		assert_lte(drop, MovementRig.SPEED_TOL_UPS, "%s: tick %d drop %.2f u/s" % [label, i, drop])


# Behaviour 4a.
func _up_run(angle_deg: float) -> void:
	var label: String = "%d deg up" % int(angle_deg)
	_new_rig()
	var top_z: float = _build(angle_deg)
	_rig.spawn(MovementRig.test_config())
	assert_true(await _rig.settle(), "%s: player settles" % label)
	await _rig.play([_forward(320)])
	var top: int = _first_index(
		0,
		func(s: MovementRig.Sample) -> bool:
			return (
				absf(MovementRig.ups(MovementRig.horizontal_speed(s.velocity)) - TOP_UPS)
				<= MovementRig.SPEED_TOL_UPS
			)
	)
	var end: int = _first_index(
		0, func(s: MovementRig.Sample) -> bool: return s.position.z <= top_z - PAST_PLATFORM_EDGE
	)
	assert_gt(top, 0, "%s: reaches top speed" % label)
	assert_gt(end, top, "%s: reaches 3 m onto the platform" % label)
	if top <= 0 or end <= top:
		return
	assert_gt(_rig.trace[top].position.z, LOW_EDGE_Z, "%s: top speed before the ramp" % label)
	_assert_no_speed_drop(top, end, label)


# Behaviour 4b.
func _down_run(angle_deg: float) -> void:
	var label: String = "%d deg down" % int(angle_deg)
	_new_rig()
	var top_z: float = _build(angle_deg)
	var height: float = RAMP_LENGTH * sin(deg_to_rad(angle_deg))
	var start_z: float = top_z - PAST_PLATFORM_EDGE - PLATFORM_RUN_UP
	var player: SUCC = _rig.spawn(MovementRig.test_config(), Vector3(0.0, height + 0.01, start_z))
	player.rotation.y = PI
	assert_true(await _rig.settle(), "%s: player settles" % label)
	await _rig.play([_forward(320, PI)])
	var top: int = _first_index(
		0,
		func(s: MovementRig.Sample) -> bool:
			return (
				absf(MovementRig.ups(MovementRig.horizontal_speed(s.velocity)) - TOP_UPS)
				<= MovementRig.SPEED_TOL_UPS
			)
	)
	var end: int = _first_index(
		0, func(s: MovementRig.Sample) -> bool: return s.position.z >= LOW_EDGE_Z + PAST_LOW_EDGE
	)
	assert_gt(top, 0, "%s: reaches top speed" % label)
	assert_gt(end, top, "%s: reaches 5 m past the low edge" % label)
	if top <= 0 or end <= top:
		return
	assert_lt(
		_rig.trace[top].position.z,
		top_z - PAST_PLATFORM_EDGE,
		"%s: top speed 3 m before the edge" % label
	)
	_assert_no_speed_drop(top, end, label)
	for i: int in range(top, end + 1):
		var s: MovementRig.Sample = _rig.trace[i]
		if absf(s.position.z - LOW_EDGE_Z) <= EDGE_ZONE:
			assert_ne(
				s.floor_type, SUCC.FloorType.NONE, "%s: tick %d on ground at the edge" % [label, i]
			)


func test_ramp_15_up() -> void:
	await _up_run(15.0)


func test_ramp_30_up() -> void:
	await _up_run(30.0)


func test_ramp_15_down() -> void:
	await _down_run(15.0)


func test_ramp_30_down() -> void:
	await _down_run(30.0)
