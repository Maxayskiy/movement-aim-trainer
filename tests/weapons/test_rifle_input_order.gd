extends GutTest
## A click saves the aim after the motion before it, not after motion that
## follows it in the same frame. Real events, no SUCC.command: MotionTurner turns the view.

const DIR_TOL: float = 0.0001
const MOTION_A_PX: float = 100.0
const MOTION_B_PX: float = 200.0
const MOTION_C_PX: float = 300.0

var _rig: MovementRig
var _player: SUCC
var _rifle: Rifle
var _turner: MotionTurner
var _directions: Array[Vector3] = []
var _accumulated_before: bool


func before_all() -> void:
	_accumulated_before = Input.use_accumulated_input


func before_each() -> void:
	_directions.clear()
	_rig = MovementRig.new()
	add_child_autofree(_rig)
	_player = _rig.spawn(MovementRig.test_config())
	_rifle = _player.get_node("Rifle") as Rifle
	_rifle.require_captured_mouse = false
	_rifle.shot_fired.connect(_on_shot_fired)
	_turner = MotionTurner.new()
	_turner.player = _player
	add_child_autofree(_turner)


func after_all() -> void:
	Input.use_accumulated_input = _accumulated_before
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_shot_fired(
	_origin: Vector3, direction: Vector3, _hit_position: Vector3, _collider: Object
) -> void:
	_directions.append(direction)


func _motion(px: float) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.relative = Vector2(px, 0.0)
	event.screen_relative = Vector2(px, 0.0)
	return event


func _button(pressed: bool) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	return event


func _run(accumulated: bool) -> void:
	assert_true(await _rig.settle(), "player settles")
	# After spawn: PlayerInputSetup sets it in _ready.
	Input.use_accumulated_input = accumulated
	_player.command = null
	await get_tree().process_frame
	var yaw_before: float = _player.global_rotation.y
	var events: Array[InputEvent] = [
		_motion(MOTION_A_PX),
		_button(true),
		_motion(MOTION_B_PX),
		_button(false),
		_motion(MOTION_C_PX),
	]
	for event: InputEvent in events:
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	await get_tree().physics_frame
	await get_tree().process_frame
	assert_eq(_directions.size(), 1, "one shot")
	if _directions.size() != 1:
		return
	# turn(x) yaws the body by -x (rotate_object_local around DOWN).
	var yaw_after_a: float = yaw_before - MOTION_A_PX * _turner.radians_per_pixel
	var expected: Vector3 = Basis(Vector3.UP, yaw_after_a) * Vector3.FORWARD
	assert_almost_eq(_directions[0].x, expected.x, DIR_TOL, "direction x")
	assert_almost_eq(_directions[0].z, expected.z, DIR_TOL, "direction z")
	var total_px: float = MOTION_A_PX + MOTION_B_PX + MOTION_C_PX
	var yaw_all: float = yaw_before - total_px * _turner.radians_per_pixel
	assert_almost_eq(_player.global_rotation.y, yaw_all, DIR_TOL, "all motion was applied")


func test_order_kept_without_accumulated_input() -> void:
	await _run(false)


func test_order_kept_with_accumulated_input() -> void:
	await _run(true)
