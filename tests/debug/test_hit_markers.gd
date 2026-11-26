extends GutTest
## Debug hit markers: one red sphere per hit while the F3 panel is visible.

const POS_TOL_M: float = 0.001
const WALL_Z: float = -20.0
const SHORT_LIFETIME_S: float = 0.1

var _rig: MovementRig
var _player: SUCC
var _rifle: Rifle
var _markers: HitMarkers
var _overlay: DebugOverlay
var _wall: HitTarget
var _last_hit: Vector3


func before_each() -> void:
	_rig = MovementRig.new()
	add_child_autofree(_rig)
	_player = _rig.spawn(MovementRig.test_config())
	_rifle = _player.get_node("Rifle") as Rifle
	_rifle.require_captured_mouse = false
	_rifle.shot_fired.connect(_on_shot_fired)
	_markers = _player.get_node("HitMarkers") as HitMarkers
	_overlay = _player.get_node("DebugOverlay") as DebugOverlay
	_wall = HitTarget.make(Vector3(10.0, 10.0, 1.0), Vector3(0.0, 2.0, WALL_Z - 0.5))
	_rig.add_child(_wall)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_shot_fired(
	_origin: Vector3, _direction: Vector3, hit_position: Vector3, _collider: Object
) -> void:
	_last_hit = hit_position


func _set_panel(shown: bool) -> void:
	(_overlay.get_node("Panel") as Control).visible = shown


## Settles at the given pitch, then clicks once and waits for the shot.
func _shoot(pitch_deg: float = 0.0) -> void:
	var input: SUCCInput = SUCCInput.new()
	input.pitch = deg_to_rad(pitch_deg)
	_player.command = input
	assert_true(await _rig.settle(), "player settles")
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame


func _emit_hit(at: Vector3) -> void:
	_rifle.shot_fired.emit(Vector3.ZERO, Vector3.FORWARD, at, _wall)


func test_hit_with_panel_visible_leaves_a_marker() -> void:
	_set_panel(true)
	await _shoot()
	assert_eq(_markers.marker_count(), 1)
	if _markers.marker_count() != 1:
		return
	var at: Vector3 = _markers.marker_positions()[0]
	assert_almost_eq(at.distance_to(_last_hit), 0.0, POS_TOL_M, "at the hit point")
	assert_almost_eq(at.z, WALL_Z, POS_TOL_M)
	assert_true(_markers.visible, "shown with the panel")


func test_hit_with_panel_hidden_leaves_none() -> void:
	_set_panel(false)
	await _shoot()
	assert_eq(_markers.marker_count(), 0)


func test_miss_leaves_none() -> void:
	_set_panel(true)
	await _shoot(45.0)
	assert_eq(_markers.marker_count(), 0)


func test_hiding_the_panel_hides_markers() -> void:
	_set_panel(true)
	_emit_hit(Vector3(0.0, 1.0, WALL_Z))
	_set_panel(false)
	await get_tree().process_frame
	assert_false(_markers.visible)


func test_65th_marker_removes_the_oldest() -> void:
	_set_panel(true)
	for i: int in 65:
		_emit_hit(Vector3(float(i) * 0.1, 1.0, WALL_Z))
	assert_eq(_markers.marker_count(), _markers.max_markers)
	var positions: Array[Vector3] = _markers.marker_positions()
	assert_almost_eq(positions[0].x, 0.1, POS_TOL_M, "oldest left is the 2nd")
	assert_almost_eq(positions[-1].x, 6.4, POS_TOL_M, "newest is the 65th")


func test_marker_is_gone_after_its_lifetime() -> void:
	_set_panel(true)
	_markers.marker_lifetime = SHORT_LIFETIME_S
	_emit_hit(Vector3(0.0, 1.0, WALL_Z))
	assert_eq(_markers.marker_count(), 1)
	await wait_seconds(SHORT_LIFETIME_S * 3.0)
	assert_eq(_markers.marker_count(), 0)


func test_respawn_clears_markers() -> void:
	_set_panel(true)
	for i: int in 3:
		_emit_hit(Vector3(float(i), 1.0, WALL_Z))
	assert_eq(_markers.marker_count(), 3)
	(_player.get_node("Respawn") as PlayerRespawn).respawn()
	assert_eq(_markers.marker_count(), 0)
