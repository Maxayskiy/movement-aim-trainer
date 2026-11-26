class_name Rifle
extends Node
## Hitscan rifle. A child of the Player root (a SUCC).
## Shots fire only on physics ticks. A click is latched as it arrives, with the
## aim at that moment, and the next tick fires from that saved aim. Later shots
## of a held trigger aim from the physics eye on the tick schedule.

## Every shot. On a miss collider is null and hit_position is the far end of the ray.
signal shot_fired(origin: Vector3, direction: Vector3, hit_position: Vector3, collider: Object)

## VIEW: the on-screen camera position. PHYSICS_EYE: the eye at the body's physics position.
enum OriginSource { VIEW, PHYSICS_EYE }

## Stands in for infinite range: longer than any map.
const RAY_LENGTH_M: float = 10000.0
const ALL_LAYERS: int = 0xFFFFFFFF


## A ray origin and its unit direction.
class Aim:
	var origin: Vector3
	var direction: Vector3

	func _init(aim_origin: Vector3, aim_direction: Vector3) -> void:
		origin = aim_origin
		direction = aim_direction


@export var config: RifleConfig
## Fire only while the mouse is captured. Headless tests turn it off: headless
## Godot can't capture the mouse.
@export var require_captured_mouse: bool = true

var timer: FireTimer = FireTimer.new()

var _player: SUCC
var _held: bool = false
var _latched: bool = false
var _saved_aim: Aim
var _last_config_sps: float = NAN


func _ready() -> void:
	_player = get_parent() as SUCC
	if _player == null:
		push_error("Rifle: parent must be a SUCC.")
		set_process_input(false)
		set_physics_process(false)
		return
	if config == null:
		config = RifleConfig.new()
	timer.ticks_per_second = Engine.physics_ticks_per_second
	_sync_config()


func _input(event: InputEvent) -> void:
	if not event.is_action("fire"):
		return
	if event.is_echo():
		return
	if event.is_pressed():
		# Runs before SUCC's _unhandled_input, so the click that recaptures the
		# mouse still sees it free and doesn't fire.
		if not _mouse_ok():
			return
		_held = true
		if not _latched:
			_latched = true
			_saved_aim = aim(OriginSource.VIEW)
	else:
		_held = false


func _physics_process(_delta: float) -> void:
	if not _mouse_ok():
		_held = false
		_latched = false
	_sync_config()
	var result: FireTimer.Result = timer.tick(Engine.get_physics_frames(), _latched, _held)
	match result:
		FireTimer.Result.CLICK_SHOT:
			_fire(_saved_aim)
		FireTimer.Result.HELD_SHOT:
			_fire(aim(OriginSource.PHYSICS_EYE))
	_latched = false
	_saved_aim = null


## Where a shot comes from and where it goes. The only place that decides it.
func aim(origin_source: OriginSource) -> Aim:
	var yaw: float = _player.global_rotation.y
	var pitch: float = _player.camera_rig.pitch
	var direction: Vector3 = Basis.from_euler(Vector3(pitch, yaw, 0.0)) * Vector3.FORWARD
	var origin: Vector3
	if origin_source == OriginSource.VIEW and _player.camera_rig.camera != null:
		origin = _player.camera_rig.camera.global_position
	else:
		origin = _player.global_position + Vector3.UP * _player.camera_rig.view_height
	return Aim.new(origin, direction.normalized())


## Damage per shot, from the clamped fire rate.
func damage() -> float:
	return config.dps / timer.shots_per_second


func _sync_config() -> void:
	# Only on change: a clamped value would otherwise warn every tick.
	if config.shots_per_second != _last_config_sps:
		_last_config_sps = config.shots_per_second
		timer.shots_per_second = config.shots_per_second
	timer.full_auto = config.full_auto


func _mouse_ok() -> bool:
	return not require_captured_mouse or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func _fire(shot: Aim) -> void:
	var far_end: Vector3 = shot.origin + shot.direction * RAY_LENGTH_M
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		shot.origin, far_end, ALL_LAYERS, [_player.get_rid()]
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(query)
	var hit_position: Vector3 = far_end
	var collider: Object = null
	if not hit.is_empty():
		hit_position = hit["position"] as Vector3
		collider = hit["collider"] as Object
		if collider != null and collider.has_method("take_hit"):
			collider.call("take_hit", damage())
	shot_fired.emit(shot.origin, shot.direction, hit_position, collider)
