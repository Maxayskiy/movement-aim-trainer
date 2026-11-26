class_name MovementRig
extends Node
## Test rig: spawns the player on a flat floor, drives it through SUCC.command
## and records one Sample per physics tick.
## settle() and play() wait on SceneTree.physics_frame, not on signals of this
## node: GUT can't free a node that is emitting, so a test resumed by one of its
## signals would leave the rig (and its player) in the tree. Both then return on
## SceneTree.process_frame, so the test (and GUT's later tests) carry on outside
## the physics step, as after GUT's own waits.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const FLOOR_SIZE: Vector3 = Vector3(200.0, 1.0, 200.0)
const SETTLE_MAX_TICKS: int = 64

const SPEED_TOL_UPS: float = 1.0
const HEIGHT_TOL_M: float = 0.01
const DISTANCE_TOL_M: float = 0.02
const TICK_TOL: int = 1

## Pinned on the player root so terrain tests don't depend on its defaults.
## Same as player.tscn: Source's walkable limit, acos(0.7) = 45.573 deg.
## Godot counts floor up to max_floor_angle + 0.573 deg, so 45 deg meets it
## exactly; otherwise a resting body sticks on a RAMP band
## (see workflow/plans/013-slope-stick.md and #13).
const RAMP_ANGLE_THRESHOLD_DEG: float = rad_to_deg(acos(0.7))
const MAX_FLOOR_ANGLE_DEG: float = 45.0


## One input held for a number of ticks, or (controlled) an input chosen per
## tick by controller.call(rig, step_tick) -> SUCCInput.
class Step:
	var input: SUCCInput
	var ticks: int
	var controller: Callable

	func _init(step_input: SUCCInput, step_ticks: int) -> void:
		input = step_input
		ticks = step_ticks

	## Before each of its ticks the rig calls step_controller.call(rig, step_tick)
	## (step_tick 0 = the step's first tick) and uses the returned SUCCInput.
	static func controlled(step_controller: Callable, step_ticks: int) -> Step:
		var step: Step = Step.new(null, step_ticks)
		step.controller = step_controller
		return step


## The player's state after one tick, with the input that tick used.
class Sample:
	var tick: int
	var position: Vector3
	var velocity: Vector3
	var floor_type: SUCC.FloorType
	var jumped: bool
	var landed: bool
	var input: SUCCInput


var player: SUCC
var trace: Array[Sample] = []

var _floor: StaticBody3D
var _idle: SUCCInput = SUCCInput.new()
var _steps: Array[Step] = []
var _step_index: int = 0
var _ticks_left: int = 0
var _current_input: SUCCInput
var _tick: int = 0
var _playing: bool = false
var _jumped_flag: bool = false
var _landed_flag: bool = false


func _init() -> void:
	# Runs after SUCC (priority 0) in the same physics frame.
	process_physics_priority = 1


## Frozen test config T: today's defaults, set explicitly.
static func test_config() -> SUCCConfig:
	var config: SUCCConfig = SUCCConfig.new()
	config.gravity = 20.32
	config.jump_height = 1.143
	config.bhop_buffered_jump = true
	config.acceleration = 7.5
	config.friction = 4.0
	config.stop_speed = 4.0
	config.max_speed = 10.16
	config.air_acceleration = 100.0
	config.max_air_speed = 0.762
	config.enforce_max_velocity = false
	config.crouch_speed_modifier = 1.0 / 3.0
	config.sprint_speed_modifier = 1.0
	config.step_height = 0.45
	return config


## Air config A: T with air_acceleration 5.0.
static func air_config() -> SUCCConfig:
	var config: SUCCConfig = test_config()
	config.air_acceleration = 5.0
	return config


## Second config S: T with other max speed, jump height and friction.
static func second_config() -> SUCCConfig:
	var config: SUCCConfig = test_config()
	config.max_speed = 8.0
	config.jump_height = 2.0
	config.friction = 6.0
	return config


static func ups(mps: float) -> float:
	return mps * SUCCConfig.SOURCE_MULT


static func horizontal_speed(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


static func horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(b.x - a.x, b.z - a.z).length()


## pin_angles false keeps the floor angles from player.tscn.
func spawn(
	config: SUCCConfig,
	at: Vector3 = Vector3(0.0, 0.01, 0.0),
	with_floor: bool = true,
	pin_angles: bool = true
) -> SUCC:
	if with_floor and _floor == null:
		_floor = StaticBody3D.new()
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = FLOOR_SIZE
		shape.shape = box
		_floor.add_child(shape)
		_floor.position = Vector3(0.0, -FLOOR_SIZE.y / 2.0, 0.0)
		add_child(_floor)
	player = PLAYER_SCENE.instantiate() as SUCC
	player.config = config
	player.command = _idle
	player.position = at
	if pin_angles:
		player.ramp_angle_threshold = deg_to_rad(RAMP_ANGLE_THRESHOLD_DEG)
		player.max_floor_angle = deg_to_rad(MAX_FLOOR_ANGLE_DEG)
	player.jumped.connect(_on_jumped)
	player.landed.connect(_on_landed)
	add_child(player)
	return player


## A static box of the given size, centred at position, rotated in degrees.
func add_box(
	size: Vector3, position: Vector3, rotation_deg: Vector3 = Vector3.ZERO
) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = position
	body.rotation_degrees = rotation_deg
	add_child(body)
	return body


## A box whose top face rises toward -Z at angle_deg, with the top face's low
## edge centred on low_edge. length is measured along the slope.
func add_ramp(
	angle_deg: float, low_edge: Vector3, length: float, width: float, thickness: float = 0.5
) -> StaticBody3D:
	var angle: float = deg_to_rad(angle_deg)
	# Unit vectors of the rotated box: along the slope (uphill) and the top normal.
	var along: Vector3 = Vector3(0.0, sin(angle), -cos(angle))
	var normal: Vector3 = Vector3(0.0, cos(angle), sin(angle))
	var centre: Vector3 = low_edge + along * (length / 2.0) - normal * (thickness / 2.0)
	return add_box(Vector3(width, thickness, length), centre, Vector3(angle_deg, 0.0, 0.0))


## Waits until the player is on FLOOR after 2 ticks in a row. False if it
## doesn't within SETTLE_MAX_TICKS.
func settle() -> bool:
	var in_a_row: int = 0
	for i: int in SETTLE_MAX_TICKS:
		await get_tree().physics_frame
		in_a_row = in_a_row + 1 if player.floor_type == SUCC.FloorType.FLOOR else 0
		if in_a_row >= 2:
			break
	await get_tree().process_frame
	return in_a_row >= 2


## Runs the steps in order and fills trace (trace[0] = state at the start).
func play(steps: Array[Step]) -> void:
	trace.clear()
	_jumped_flag = false
	_landed_flag = false
	_tick = 0
	trace.append(_sample(player.command))
	_steps.clear()
	for step: Step in steps:
		if step.ticks > 0:
			_steps.append(step)
	if _steps.is_empty():
		return
	_step_index = 0
	_ticks_left = _steps[0].ticks
	_use_input(_input_for(_steps[0], 0))
	_playing = true
	while _playing:
		await get_tree().physics_frame
	await get_tree().process_frame


func _physics_process(_delta: float) -> void:
	if _playing:
		_tick += 1
		trace.append(_sample(_current_input))
		_ticks_left -= 1
		if _ticks_left <= 0:
			_step_index += 1
			if _step_index >= _steps.size():
				_playing = false
				player.command = _idle
				return
			_ticks_left = _steps[_step_index].ticks
		var step: Step = _steps[_step_index]
		_use_input(_input_for(step, step.ticks - _ticks_left))


## The input for one tick of a step: its fixed input, or its controller's.
func _input_for(step: Step, step_tick: int) -> SUCCInput:
	if step.controller.is_valid():
		return step.controller.call(self, step_tick) as SUCCInput
	return step.input


func _use_input(input: SUCCInput) -> void:
	_current_input = input
	player.command = input


func _sample(input: SUCCInput) -> Sample:
	var s: Sample = Sample.new()
	s.tick = _tick
	s.position = player.global_position
	s.velocity = player.velocity
	s.floor_type = player.floor_type
	s.jumped = _jumped_flag
	s.landed = _landed_flag
	s.input = input
	_jumped_flag = false
	_landed_flag = false
	return s


func _on_jumped() -> void:
	_jumped_flag = true


func _on_landed(_fall_velocity: float) -> void:
	_landed_flag = true
