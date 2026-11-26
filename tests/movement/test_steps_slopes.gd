extends GutTest
## Behaviours 5-6 of workflow/plans/012-hull-terrain-tests.md.

## Step face z: top speed (1.138 m) plus 5 m.
const STEP_FACE_Z: float = -6.2
const STEP_DEPTH: float = 10.0
const STEP_WIDTH: float = 10.0
const SLOPE_LENGTH: float = 10.0
const SLOPE_WIDTH: float = 10.0
const SLOPE_LOW_EDGE_Z: float = -3.0
## Gap between the hull's lowest corner and the slope face at spawn.
const SPAWN_GAP: float = 0.05

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _cmd(move: Vector2) -> SUCCInput:
	var input: SUCCInput = SUCCInput.new()
	input.move = move
	return input


func _half_depth(player: SUCC) -> float:
	return (player.collision.shape as BoxShape3D).size.z / 2.0


func _run_into_step(height: float) -> float:
	_rig.add_box(
		Vector3(STEP_WIDTH, height, STEP_DEPTH),
		Vector3(0.0, height / 2.0, STEP_FACE_Z - STEP_DEPTH / 2.0)
	)
	_rig.spawn(MovementRig.test_config())
	assert_true(await _rig.settle(), "player settles")
	var floor_y: float = _rig.player.global_position.y
	await _rig.play([MovementRig.Step.new(_cmd(Vector2(0.0, -1.0)), 128)])
	return floor_y


# Behaviour 5a.
func test_step_044_climbs() -> void:
	await _run_into_step(0.44)
	var last: MovementRig.Sample = _rig.trace[-1]
	assert_lt(last.position.z, STEP_FACE_Z, "ends past the face")
	assert_almost_eq(last.position.y, 0.44, MovementRig.HEIGHT_TOL_M, "feet on top")
	assert_eq(last.floor_type, SUCC.FloorType.FLOOR)


# Behaviour 5b.
func test_step_046_blocks() -> void:
	var floor_y: float = await _run_into_step(0.46)
	var last: MovementRig.Sample = _rig.trace[-1]
	var speed: float = MovementRig.ups(MovementRig.horizontal_speed(last.velocity))
	assert_almost_eq(speed, 0.0, MovementRig.SPEED_TOL_UPS, "stopped")
	var front: float = last.position.z - _half_depth(_rig.player)
	assert_almost_eq(front, STEP_FACE_Z, MovementRig.DISTANCE_TOL_M, "stops at the face")
	assert_almost_eq(last.position.y, floor_y, MovementRig.HEIGHT_TOL_M, "feet on the floor")


## Builds a slope rising toward -Z and spawns the player over its middle with
## SPAWN_GAP under the hull's lowest (uphill) corner.
func _spawn_on_slope(angle_deg: float) -> SUCC:
	var angle: float = deg_to_rad(angle_deg)
	var low_edge: Vector3 = Vector3(0.0, 0.0, SLOPE_LOW_EDGE_Z)
	_rig.add_ramp(angle_deg, low_edge, SLOPE_LENGTH, SLOPE_WIDTH)
	var middle: Vector3 = low_edge + Vector3(0.0, sin(angle), -cos(angle)) * (SLOPE_LENGTH / 2.0)
	var player: SUCC = _rig.spawn(MovementRig.test_config(), middle)
	player.position.y += _half_depth(player) * tan(angle) + SPAWN_GAP
	return player


# Behaviour 6a.
func test_slope_44_holds_and_climbs() -> void:
	_spawn_on_slope(44.0)
	assert_true(await _rig.settle(), "settles on FLOOR")
	await _rig.play([MovementRig.Step.new(SUCCInput.new(), 128)])
	var start: Vector3 = _rig.trace[0].position
	for i: int in _rig.trace.size():
		var s: MovementRig.Sample = _rig.trace[i]
		assert_eq(s.floor_type, SUCC.FloorType.FLOOR, "tick %d floor" % i)
	var moved: float = start.distance_to(_rig.trace[-1].position)
	assert_lt(moved, 0.01, "rests: moved %.4f m" % moved)
	await _rig.play([MovementRig.Step.new(_cmd(Vector2(0.0, -1.0)), 128)])
	var rest_y: float = _rig.trace[0].position.y
	var top_y: float = rest_y
	for s: MovementRig.Sample in _rig.trace:
		top_y = maxf(top_y, s.position.y)
	assert_gt(top_y - rest_y, 1.0, "W uphill rises %.3f m" % (top_y - rest_y))


# Behaviour 6b.
func test_slope_46_slides() -> void:
	_spawn_on_slope(46.0)
	await _rig.play([MovementRig.Step.new(SUCCInput.new(), 128)])
	var landed: int = -1
	for i: int in _rig.trace.size():
		if _rig.trace[i].floor_type != SUCC.FloorType.NONE:
			landed = i
			break
	assert_gte(landed, 0, "lands on the face")
	if landed < 0:
		return
	assert_eq(_rig.trace[landed].floor_type, SUCC.FloorType.RAMP, "lands on RAMP")
	var angle: float = deg_to_rad(46.0)
	var downhill: Vector3 = Vector3(0.0, -sin(angle), cos(angle))
	var slid: float = (_rig.trace[-1].position - _rig.trace[landed].position).dot(downhill)
	assert_gt(slid, 1.0, "slides downhill %.3f m" % slid)
