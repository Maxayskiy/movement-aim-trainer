extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const START_POS: Vector3 = Vector3(8.0, 1.0, 24.0)
const START_YAW: float = 0.7

var _player: SUCC
var _respawn: PlayerRespawn


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as SUCC
	_player.transform = Transform3D(Basis(Vector3.UP, START_YAW), START_POS)
	add_child_autofree(_player)
	_respawn = _player.get_node("Respawn") as PlayerRespawn


func after_each() -> void:
	Input.action_release("respawn")


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _displace() -> void:
	_player.global_position = Vector3(50.0, 5.0, -10.0)
	_player.rotation.y = -1.2
	_player.velocity = Vector3(3.0, -4.0, 5.0)
	_player.camera_rig.pitch = 0.5


func _assert_at_start() -> void:
	assert_almost_eq(_player.global_position, START_POS, Vector3.ONE * 0.001)
	assert_almost_eq(_player.rotation.y, START_YAW, 0.001)
	assert_eq(_player.velocity, Vector3.ZERO)
	assert_eq(_player.camera_rig.pitch, 0.0)


func test_respawn_resets_position_yaw_velocity_pitch() -> void:
	_displace()
	_respawn.respawn()
	_assert_at_start()


func test_respawn_action_respawns() -> void:
	_displace()
	var event: InputEventAction = InputEventAction.new()
	event.action = "respawn"
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	_assert_at_start()


func test_falling_below_kill_height_respawns() -> void:
	_player.global_position = Vector3(0.0, -31.0, 0.0)
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(1)
	assert_almost_eq(_player.global_position, START_POS, Vector3.ONE * 0.001)


func test_above_kill_height_does_not_respawn() -> void:
	var pos: Vector3 = Vector3(0.0, -29.0, 0.0)
	_player.global_position = pos
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(1)
	assert_almost_eq(_player.global_position.x, pos.x, 0.001)
	assert_almost_eq(_player.global_position.z, pos.z, 0.001)
	assert_lt(_player.global_position.y, -28.0)
