class_name MotionTurner
extends Node
## Turns player.camera_rig by each mouse-motion event, through CameraRig.turn().
## Stands in for SUCC's own handler, which ignores motion in headless runs
## (headless Godot can't capture the mouse).

var player: SUCC
var radians_per_pixel: float = 0.001


func _input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null or player == null:
		return
	player.camera_rig.turn(motion.screen_relative * radians_per_pixel)
