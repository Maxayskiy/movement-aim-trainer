extends GutTest
## Behaviours 1-2 of workflow/plans/013-slope-stick.md. Uses the angles from
## player.tscn (pin_angles false), not the rig's pins.

const SLOPE_LENGTH: float = 10.0
const SLOPE_WIDTH: float = 10.0
const SLOPE_LOW_EDGE_Z: float = -3.0
## Gap between the hull's lowest (uphill) bottom edge and the slope face at spawn.
const SPAWN_GAP: float = 0.05
const PLAY_TICKS: int = 160
## Ticks measured from landing.
const MEASURE_TICKS: int = 128
const SLIDE_MIN_M: float = 1.0
const HOLD_MAX_M: float = 0.01

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Builds a slope rising toward -Z, spawns the player over its middle with
## SPAWN_GAP under the hull's uphill bottom edge, and plays PLAY_TICKS with no
## input. Returns the index of the first sample that isn't NONE, or -1.
func _rest_on_slope(angle_deg: float) -> int:
	var angle: float = deg_to_rad(angle_deg)
	var low_edge: Vector3 = Vector3(0.0, 0.0, SLOPE_LOW_EDGE_Z)
	_rig.add_ramp(angle_deg, low_edge, SLOPE_LENGTH, SLOPE_WIDTH)
	var middle: Vector3 = low_edge + Vector3(0.0, sin(angle), -cos(angle)) * (SLOPE_LENGTH / 2.0)
	var player: SUCC = _rig.spawn(MovementRig.test_config(), middle, false, false)
	var half_depth: float = (player.collision.shape as BoxShape3D).size.z / 2.0
	player.position.y += half_depth * tan(angle) + SPAWN_GAP
	await _rig.play([MovementRig.Step.new(SUCCInput.new(), PLAY_TICKS)])
	for i: int in _rig.trace.size():
		if _rig.trace[i].floor_type != SUCC.FloorType.NONE:
			return i
	return -1


func _end_index(landed: int) -> int:
	return mini(landed + MEASURE_TICKS, _rig.trace.size() - 1)


func _assert_holds(angle_deg: float) -> void:
	var landed: int = await _rest_on_slope(angle_deg)
	assert_gte(landed, 0, "lands on the face")
	if landed < 0:
		return
	var end: int = _end_index(landed)
	var floor_ticks: int = 0
	for i: int in range(landed, end + 1):
		if _rig.trace[i].floor_type == SUCC.FloorType.FLOOR:
			floor_ticks += 1
	assert_eq(floor_ticks, end - landed + 1, "FLOOR on every tick after landing")
	var moved: float = _rig.trace[landed].position.distance_to(_rig.trace[end].position)
	assert_lt(moved, HOLD_MAX_M, "holds: moved %.4f m" % moved)


# Behaviour 1.
func test_slope_46_slides() -> void:
	var landed: int = await _rest_on_slope(46.0)
	assert_gte(landed, 0, "lands on the face")
	if landed < 0:
		return
	var end: int = _end_index(landed)
	assert_eq(_rig.trace[landed].floor_type, SUCC.FloorType.RAMP, "lands on RAMP")
	var angle: float = deg_to_rad(46.0)
	var downhill: Vector3 = Vector3(0.0, -sin(angle), cos(angle))
	var slid: float = (_rig.trace[end].position - _rig.trace[landed].position).dot(downhill)
	assert_gt(slid, SLIDE_MIN_M, "slides downhill %.3f m" % slid)


# Behaviour 2.
func test_slope_44_holds() -> void:
	await _assert_holds(44.0)


# Behaviour 2.
func test_slope_45_3_holds() -> void:
	await _assert_holds(45.3)
