extends GutTest
## Behaviour 7 of workflow/plans/012-hull-terrain-tests.md.

## Apex 1.143 m + top air lift 0.47 m (appendix of the plan).
const LEDGE_LIMIT: float = 1.613
const LEDGE_MARGIN: float = 0.02
const FACE_Z: float = -2.0
const LEDGE_WIDTH: float = 4.0
## Deep enough that 150 ticks of W after landing stay on top.
const LEDGE_DEPTH: float = 20.0
const FACE_GAP: float = 0.01

var _rig: MovementRig


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _forward(ticks: int, jump: bool = false) -> MovementRig.Step:
	var input: SUCCInput = SUCCInput.new()
	input.move = Vector2(0.0, -1.0)
	input.jump = jump
	return MovementRig.Step.new(input, ticks)


## Returns the floor height after settling.
func _jump_at_ledge(height: float) -> float:
	_rig.add_box(
		Vector3(LEDGE_WIDTH, height, LEDGE_DEPTH),
		Vector3(0.0, height / 2.0, FACE_Z - LEDGE_DEPTH / 2.0)
	)
	var player: SUCC = _rig.spawn(MovementRig.test_config())
	var half_depth: float = (player.collision.shape as BoxShape3D).size.z / 2.0
	player.position.z = FACE_Z + half_depth + FACE_GAP
	assert_true(await _rig.settle(), "player settles")
	var floor_y: float = player.global_position.y
	await _rig.play([_forward(10), _forward(1, true), _forward(150)])
	return floor_y


# Behaviour 7a.
func test_ledge_under_limit_climbs() -> void:
	var height: float = LEDGE_LIMIT - LEDGE_MARGIN
	await _jump_at_ledge(height)
	var last: MovementRig.Sample = _rig.trace[-1]
	assert_almost_eq(last.position.y, height, MovementRig.HEIGHT_TOL_M, "feet on the ledge")
	assert_eq(last.floor_type, SUCC.FloorType.FLOOR)


# Behaviour 7b.
func test_ledge_over_limit_falls_back() -> void:
	var floor_y: float = await _jump_at_ledge(LEDGE_LIMIT + LEDGE_MARGIN)
	var last: MovementRig.Sample = _rig.trace[-1]
	assert_almost_eq(last.position.y, floor_y, MovementRig.HEIGHT_TOL_M, "feet on the floor")
