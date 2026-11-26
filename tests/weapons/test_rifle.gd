extends GutTest
## Rifle on the real player: real fire events, MovementRig for the body.
## The player stands at the origin facing -Z. A 10 x 10 x 1 m wall's near face is at z = -20.

const POS_TOL_M: float = 0.001
const DAMAGE_TOL: float = 0.001
const DIR_TOL: float = 0.0001
const WALL_SIZE: Vector3 = Vector3(10.0, 10.0, 1.0)
const WALL_Z: float = -20.0


## One shot_fired emission, with the tick and the body's position at that tick.
class Shot:
	var tick: int
	var origin: Vector3
	var direction: Vector3
	var hit_position: Vector3
	var collider: Object
	var player_position: Vector3


var _rig: MovementRig
var _player: SUCC
var _rifle: Rifle
var _wall: HitTarget
var _shots: Array[Shot] = []


func before_each() -> void:
	_shots.clear()
	_rig = MovementRig.new()
	add_child_autofree(_rig)
	_player = _rig.spawn(MovementRig.test_config())
	_rifle = _player.get_node("Rifle") as Rifle
	_rifle.require_captured_mouse = false
	# A copy: tests change it, and the .tres is shared.
	_rifle.config = _rifle.config.duplicate() as RifleConfig
	_rifle.shot_fired.connect(_on_shot_fired)
	_wall = _add_wall(WALL_Z)


func after_each() -> void:
	_release_fire()


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _add_wall(near_face_z: float) -> HitTarget:
	var wall: HitTarget = HitTarget.make(
		WALL_SIZE, Vector3(0.0, 2.0, near_face_z - WALL_SIZE.z / 2.0)
	)
	_rig.add_child(wall)
	return wall


func _on_shot_fired(
	origin: Vector3, direction: Vector3, hit_position: Vector3, collider: Object
) -> void:
	var shot: Shot = Shot.new()
	shot.tick = Engine.get_physics_frames()
	shot.origin = origin
	shot.direction = direction
	shot.hit_position = hit_position
	shot.collider = collider
	shot.player_position = _player.global_position
	_shots.append(shot)


## Settles, then lets one render frame place the camera at the rest position:
## a click aims from where the camera was last placed.
func _settle() -> void:
	assert_true(await _rig.settle(), "player settles")
	await get_tree().process_frame


func _fire_event(pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _press_fire() -> void:
	_fire_event(true)


func _release_fire() -> void:
	_fire_event(false)


func _click() -> void:
	_fire_event(true)
	_fire_event(false)


## Waits n physics ticks, then returns outside the physics step.
func _ticks(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame
	await get_tree().process_frame


## Sets the view through the rig command; SUCC applies it on the next tick.
func _look(yaw_deg: float, pitch_deg: float = 0.0) -> void:
	var input: SUCCInput = SUCCInput.new()
	input.yaw = deg_to_rad(yaw_deg)
	input.pitch = deg_to_rad(pitch_deg)
	_player.command = input


func _dir(yaw_deg: float) -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(yaw_deg)) * Vector3.FORWARD


func _eye_y() -> float:
	return _player.global_position.y + _player.camera_rig.view_height


func _assert_vec(got: Vector3, expected: Vector3, tol: float, text: String) -> void:
	assert_almost_eq(got.x, expected.x, tol, text + " x")
	assert_almost_eq(got.y, expected.y, tol, text + " y")
	assert_almost_eq(got.z, expected.z, tol, text + " z")


func test_hold_fires_4_shots_32_ticks_apart() -> void:
	await _settle()
	_press_fire()
	await _ticks(128)
	assert_eq(_shots.size(), 4, "4 shots in 128 ticks")
	if _shots.size() != 4:
		return
	for i: int in range(1, 4):
		assert_eq(_shots[i].tick - _shots[i - 1].tick, 32, "gap before shot %d" % i)
	for shot: Shot in _shots:
		assert_eq(shot.collider, _wall)
		_assert_vec(shot.hit_position, Vector3(0.0, _eye_y(), WALL_Z), POS_TOL_M, "hit")
	assert_eq(_wall.hits.size(), 4)
	for damage: float in _wall.hits:
		assert_almost_eq(damage, 25.0, DAMAGE_TOL)


func test_click_uses_the_aim_saved_at_the_click() -> void:
	await _settle()
	_click()
	_look(30.0)
	await _ticks(2)
	assert_eq(_shots.size(), 1)
	if _shots.size() != 1:
		return
	assert_almost_eq(_player.global_rotation.y, deg_to_rad(30.0), DIR_TOL, "view turned")
	assert_almost_eq(_shots[0].hit_position.x, 0.0, POS_TOL_M, "hit at x = 0")
	assert_almost_eq(_shots[0].hit_position.z, WALL_Z, POS_TOL_M)


func test_click_uses_the_on_screen_camera_position() -> void:
	await _settle()
	var eye: Vector3 = _player.global_position + Vector3.UP * _player.camera_rig.view_height
	var shifted: Vector3 = eye + Vector3(0.5, 0.0, 0.0)
	_player.camera_rig.global_position = shifted
	_press_fire()
	_release_fire()
	await _ticks(2)
	assert_eq(_shots.size(), 1)
	if _shots.size() != 1:
		return
	_assert_vec(_shots[0].origin, shifted, POS_TOL_M, "origin")
	assert_almost_eq(_shots[0].hit_position.x, 0.5, POS_TOL_M, "hit at x = 0.5")


func test_held_shots_aim_from_the_physics_eye_on_the_tick() -> void:
	await _settle()
	_press_fire()
	await _ticks(2)
	assert_eq(_shots.size(), 1, "first shot")
	_look(10.0)
	await _ticks(40)
	assert_eq(_shots.size(), 2, "second shot")
	if _shots.size() != 2:
		return
	var shot: Shot = _shots[1]
	var eye: Vector3 = shot.player_position + Vector3.UP * _player.camera_rig.view_height
	_assert_vec(shot.origin, eye, POS_TOL_M, "origin")
	_assert_vec(shot.direction, _dir(10.0), DIR_TOL, "direction")
	var distance: float = (WALL_Z - eye.z) / shot.direction.z
	_assert_vec(shot.hit_position, eye + shot.direction * distance, POS_TOL_M, "hit")


func test_press_and_release_between_ticks_fires_once() -> void:
	await _settle()
	_click()
	await _ticks(101)
	assert_eq(_shots.size(), 1)


func test_dropped_tap_leaves_nothing_behind() -> void:
	await _settle()
	# Inputs are scheduled by physics tick through the rig's controller, which
	# runs after the rifle on each tick: a click on step tick k fires on k + 1,
	# and a yaw returned on step tick k is applied on k + 1.
	var controller: Callable = func(_rig_node: MovementRig, k: int) -> SUCCInput:
		if k == 0 or k == 10 or k == 40:
			_click()
		var input: SUCCInput = SUCCInput.new()
		if k >= 39:
			input.yaw = deg_to_rad(-20.0)
		elif k >= 9:
			input.yaw = deg_to_rad(20.0)
		return input
	await _rig.play([MovementRig.Step.controlled(controller, 45)] as Array[MovementRig.Step])
	assert_eq(_shots.size(), 2, "click in cooldown doesn't fire")
	if _shots.size() != 2:
		return
	assert_eq(_shots[1].tick - _shots[0].tick, 40, "fires 40 ticks after the first")
	_assert_vec(_shots[1].direction, _dir(-20.0), DIR_TOL, "direction -20 deg")


func test_tap_only_held_fires_once() -> void:
	_rifle.config.full_auto = false
	await _settle()
	_press_fire()
	await _ticks(128)
	assert_eq(_shots.size(), 1)


func test_straight_down_hits_the_floor_not_the_player() -> void:
	_look(0.0, -89.0)
	await _settle()
	_click()
	await _ticks(2)
	assert_eq(_shots.size(), 1)
	if _shots.size() != 1:
		return
	var shot: Shot = _shots[0]
	assert_not_null(shot.collider)
	assert_ne(shot.collider, _player, "not the player")
	assert_ne(shot.collider, _wall)
	assert_almost_eq(shot.hit_position.y, 0.0, POS_TOL_M, "floor top")
	assert_lt(Vector2(shot.hit_position.x, shot.hit_position.z).length(), 0.1, "below the feet")


func test_areas_are_ignored() -> void:
	var area: Area3D = Area3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(10.0, 10.0, 1.0)
	shape.shape = box
	area.add_child(shape)
	area.position = Vector3(0.0, 2.0, -10.0)
	_rig.add_child(area)
	await _settle()
	_click()
	await _ticks(2)
	assert_eq(_shots.size(), 1)
	if _shots.size() != 1:
		return
	assert_eq(_shots[0].collider, _wall)


func test_far_wall_is_hit() -> void:
	_wall.free()
	_wall = _add_wall(-5000.0)
	await _settle()
	_click()
	await _ticks(2)
	assert_eq(_shots.size(), 1)
	if _shots.size() != 1:
		return
	assert_eq(_shots[0].collider, _wall)
	assert_almost_eq(_shots[0].hit_position.z, -5000.0, POS_TOL_M)


func test_sky_shot_misses_at_ray_length() -> void:
	_look(0.0, 45.0)
	await _settle()
	_click()
	await _ticks(2)
	assert_eq(_shots.size(), 1)
	if _shots.size() != 1:
		return
	var shot: Shot = _shots[0]
	assert_null(shot.collider)
	_assert_vec(
		shot.hit_position, shot.origin + shot.direction * Rifle.RAY_LENGTH_M, POS_TOL_M, "far end"
	)
	assert_eq(_wall.hits.size(), 0)


func test_no_shot_without_captured_mouse() -> void:
	_rifle.require_captured_mouse = true
	await _settle()
	_click()
	_press_fire()
	await _ticks(40)
	assert_eq(_shots.size(), 0)
