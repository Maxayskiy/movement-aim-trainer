class_name PlayerRespawn
extends Node
## Puts the parent SUCC back at its level start on the respawn action or a fall.

## Falling below this height (m) respawns the player.
@export var kill_height: float = -30.0

var _start: Transform3D
var _player: SUCC


func _ready() -> void:
	_player = get_parent() as SUCC
	if _player == null:
		push_error("PlayerRespawn: parent must be a SUCC.")
		set_process_unhandled_input(false)
		set_physics_process(false)
		return
	_start = _player.global_transform


func respawn() -> void:
	_player.velocity = Vector3.ZERO
	_player.teleport(_start)
	if _player.camera_rig:
		_player.camera_rig.pitch = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("respawn"):
		respawn()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if _player.global_position.y < kill_height:
		respawn()
