class_name PlayerInputSetup
extends Node
## Applies input settings Godot has no project setting for.

## False: mouse look reads every mouse event instead of one merged event per frame.
@export var use_accumulated_input: bool = false


func _ready() -> void:
	Input.use_accumulated_input = use_accumulated_input
