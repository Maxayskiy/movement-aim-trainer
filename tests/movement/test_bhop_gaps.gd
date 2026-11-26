extends GutTest
## Behaviour 4 of workflow/plans/014-movement-course.md: the physics of the
## course's bhop gaps. An edge takeoff at the label speed v lands on the block;
## one at v - 50 falls short onto the floor.

## [label v in u/s, gap in m] (plan, Behaviour 4).
const GAPS: Array = [[400, 7.73], [450, 8.73], [500, 9.66], [550, 10.60], [600, 11.44]]
const MISS_DELTA_UPS: float = 50.0
const BOX_TOP: float = 0.6
const PLATFORM_SIZE: Vector3 = Vector3(20.0, 0.6, 6.0)
const BLOCK_SIZE: Vector3 = Vector3(6.0, 0.6, 6.0)
## Hull back face this far inside the platform's east edge (x = 0).
const EDGE_INSET: float = 0.05
const SPAWN_GAP: float = 0.01
const FLIGHT_TICKS: int = 150

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Builds one gap, takes off from the edge at speed_ups and returns the trace.
func _takeoff(gap: float, speed_ups: float) -> Array[MovementRig.Sample]:
	_rig.add_box(PLATFORM_SIZE, Vector3(-PLATFORM_SIZE.x / 2.0, PLATFORM_SIZE.y / 2.0, 0.0))
	_rig.add_box(BLOCK_SIZE, Vector3(gap + BLOCK_SIZE.x / 2.0, BLOCK_SIZE.y / 2.0, 0.0))
	var player: SUCC = _rig.spawn(MovementRig.test_config())
	var half_width: float = (player.collision.shape as BoxShape3D).size.x / 2.0
	player.position = Vector3(-EDGE_INSET + half_width, BOX_TOP + SPAWN_GAP, 0.0)
	player.rotation_degrees.y = -90.0  # faces +X
	assert_true(await _rig.settle(), "player settles on the 5 cm edge strip")
	player.velocity = Vector3(speed_ups / SUCCConfig.SOURCE_MULT, 0.0, 0.0)
	var jump: SUCCInput = SUCCInput.new()
	jump.jump = true
	await _rig.play(
		[MovementRig.Step.new(jump, 1), MovementRig.Step.new(SUCCInput.new(), FLIGHT_TICKS)]
	)
	return _rig.trace


func _assert_takeoff_speed(trace: Array[MovementRig.Sample], speed_ups: float) -> void:
	var takeoff: MovementRig.Sample = trace[1]
	assert_true(takeoff.jumped, "jumped on the first tick")
	var measured: float = MovementRig.ups(MovementRig.horizontal_speed(takeoff.velocity))
	assert_almost_eq(measured, speed_ups, MovementRig.SPEED_TOL_UPS, "takeoff speed")


func test_label_speed_lands_on_block(row: Array = use_parameters(GAPS)) -> void:
	var v: float = row[0]
	var gap: float = row[1]
	var trace: Array[MovementRig.Sample] = await _takeoff(gap, v)
	_assert_takeoff_speed(trace, v)
	var last: MovementRig.Sample = trace[-1]
	var what: String = "gap %d at %d u/s" % [v, v]
	assert_eq(last.floor_type, SUCC.FloorType.FLOOR, what + ": on floor")
	assert_almost_eq(last.position.y, BOX_TOP, MovementRig.HEIGHT_TOL_M, what + ": on block")
	assert_gt(last.position.x, gap, what + ": past block face")


func test_fifty_under_falls_short(row: Array = use_parameters(GAPS)) -> void:
	var v: float = row[0]
	var gap: float = row[1]
	var speed: float = v - MISS_DELTA_UPS
	var trace: Array[MovementRig.Sample] = await _takeoff(gap, speed)
	_assert_takeoff_speed(trace, speed)
	var last: MovementRig.Sample = trace[-1]
	var what: String = "gap %d at %d u/s" % [v, speed]
	assert_almost_eq(last.position.y, 0.0, MovementRig.HEIGHT_TOL_M, what + ": on the floor")
	assert_lt(last.position.x, gap, what + ": before block face")
