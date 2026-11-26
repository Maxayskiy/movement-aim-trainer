extends GutTest
## Behaviours 1-3 of workflow/plans/012-hull-terrain-tests.md.

const TOP_UPS: float = 400.0
const RUN_UP: int = 64
const HOP_PERIOD: int = 86
## Metres from spawn to where top speed is reached (#8: 1.138 m).
const TOP_SPEED_DISTANCE: float = 1.138
const SEAM_PAST_TOP_SPEED: float = 5.0
## One hop at 400 u/s: 86 ticks x 10.16 m/s / 128.
const HOP_LENGTH: float = 6.826
const BOX_SIZE: float = 40.0

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


func _forward(ticks: int, jump: bool = false) -> MovementRig.Step:
	var input: SUCCInput = SUCCInput.new()
	input.move = Vector2(0.0, -1.0)
	input.jump = jump
	return MovementRig.Step.new(input, ticks)


func _speed_ups(i: int) -> float:
	return MovementRig.ups(MovementRig.horizontal_speed(_rig.trace[i].velocity))


## Two floor boxes, tops at y = 0, meeting along a line through seam_point.
## Their Z faces meet there, turned yaw_deg about Y.
func _two_boxes(seam_point: Vector3, yaw_deg: float) -> void:
	var yaw: float = deg_to_rad(yaw_deg)
	var normal: Vector3 = Vector3(sin(yaw), 0.0, cos(yaw))
	var size: Vector3 = Vector3(BOX_SIZE, 1.0, BOX_SIZE)
	var rot: Vector3 = Vector3(0.0, yaw_deg, 0.0)
	var down: Vector3 = Vector3(0.0, -0.5, 0.0)
	_rig.add_box(size, seam_point + normal * (BOX_SIZE / 2.0) + down, rot)
	_rig.add_box(size, seam_point - normal * (BOX_SIZE / 2.0) + down, rot)


func _first_top_speed_index() -> int:
	for i: int in _rig.trace.size():
		if absf(_speed_ups(i) - TOP_UPS) <= MovementRig.SPEED_TOL_UPS:
			return i
	return -1


func _run_across_seam(yaw_deg: float, label: String) -> void:
	_two_boxes(Vector3(0.0, 0.0, -(TOP_SPEED_DISTANCE + SEAM_PAST_TOP_SPEED)), yaw_deg)
	_rig.spawn(MovementRig.test_config(), Vector3(0.0, 0.01, 0.0), false)
	assert_true(await _rig.settle(), "%s: player settles" % label)
	await _rig.play([_forward(256)])
	var top: int = _first_top_speed_index()
	assert_gt(top, 0, "%s: reaches top speed" % label)
	if top <= 0:
		return
	var seam_z: float = -(TOP_SPEED_DISTANCE + SEAM_PAST_TOP_SPEED)
	assert_lt(_rig.trace[-1].position.z, seam_z - 2.0, "%s: crossed the seam" % label)
	var feet: float = _rig.trace[top].position.y
	for i: int in range(top, _rig.trace.size()):
		var s: MovementRig.Sample = _rig.trace[i]
		assert_almost_eq(
			_speed_ups(i), TOP_UPS, MovementRig.SPEED_TOL_UPS, "%s: tick %d speed" % [label, i]
		)
		assert_almost_eq(
			s.position.y, feet, MovementRig.HEIGHT_TOL_M, "%s: tick %d feet" % [label, i]
		)
		assert_eq(s.floor_type, SUCC.FloorType.FLOOR, "%s: tick %d floor" % [label, i])


# Behaviour 1.
func test_straight_seam() -> void:
	await _run_across_seam(0.0, "straight")


# Behaviour 2.
func test_diagonal_seam() -> void:
	await _run_across_seam(45.0, "diagonal")


func _takeoff_z() -> float:
	_rig.spawn(MovementRig.test_config())
	assert_true(await _rig.settle(), "measure run: player settles")
	await _rig.play([_forward(RUN_UP), _forward(1, true)])
	assert_true(_rig.trace[RUN_UP + 1].jumped, "measure run: jumped")
	return _rig.trace[RUN_UP + 1].position.z


# Behaviour 3.
func test_bhop_landing_on_seam() -> void:
	var takeoff_z: float = await _takeoff_z()
	_new_rig()
	_two_boxes(Vector3(0.0, 0.0, takeoff_z - HOP_LENGTH), 0.0)
	_rig.spawn(MovementRig.test_config(), Vector3(0.0, 0.01, 0.0), false)
	assert_true(await _rig.settle(), "player settles")
	var floor_y: float = _rig.player.global_position.y
	var held: int = 3 * HOP_PERIOD + 2
	await _rig.play([_forward(RUN_UP), _forward(held, true), _forward(10)])
	var held_end: int = RUN_UP + held
	var landed: Array[int] = []
	for i: int in range(RUN_UP + 1, held_end + 1):
		if _rig.trace[i].landed:
			landed.append(i)
	assert_gte(landed.size(), 3, "3 landings: %s" % [landed])
	if landed.is_empty():
		return
	var seam_z: float = takeoff_z - HOP_LENGTH
	var first_z: float = _rig.trace[landed[0]].position.z
	assert_almost_eq(first_z, seam_z, 0.4, "first landing has the seam under the hull")
	for l: int in landed:
		assert_almost_eq(
			_rig.trace[l].position.y, floor_y, MovementRig.HEIGHT_TOL_M, "landing %d height" % l
		)
		if l < held_end:
			assert_true(_rig.trace[l + 1].jumped, "landed %d then jumped" % l)
	for i: int in range(RUN_UP, held_end + 1):
		assert_almost_eq(_speed_ups(i), TOP_UPS, MovementRig.SPEED_TOL_UPS, "tick %d speed" % i)
