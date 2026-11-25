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


## One input held for a number of ticks.
class Step:
	var input: SUCCInput
	var ticks: int

	func _init(step_input: SUCCInput, step_ticks: int) -> void:
		input = step_input
		ticks = step_ticks


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


func spawn(config: SUCCConfig, at: Vector3 = Vector3(0.0, 0.01, 0.0)) -> SUCC:
	if _floor == null:
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
	player.jumped.connect(_on_jumped)
	player.landed.connect(_on_landed)
	add_child(player)
	return player


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
	player.command = _steps[0].input
	_playing = true
	while _playing:
		await get_tree().physics_frame
	await get_tree().process_frame


func _physics_process(_delta: float) -> void:
	if _playing:
		_tick += 1
		trace.append(_sample(_steps[_step_index].input))
		_ticks_left -= 1
		if _ticks_left <= 0:
			_step_index += 1
			if _step_index >= _steps.size():
				_playing = false
				player.command = _idle
			else:
				_ticks_left = _steps[_step_index].ticks
				player.command = _steps[_step_index].input


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
