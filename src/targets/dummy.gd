class_name Dummy
extends StaticBody3D
## A static capsule target. Rifle shots call take_hit. At 0 health it hides,
## stops colliding and comes back after the config's respawn delay.
## Its origin is at its feet. Health logic is in TargetHealth.

## Every hit that counts. damage has overkill removed.
signal damaged(damage: float, health_left: float)
## Right after the damaged of the killing hit.
signal died
signal respawned

@export var config: DummyConfig
## Debug label: metres above the head.
@export var label_offset: float = 0.3
@export var label_font_size: int = 64
@export var label_pixel_size: float = 0.004
@export var label_outline_size: int = 12

var health: TargetHealth = TargetHealth.new()

var _overlay: DebugOverlay
var _shape: CapsuleShape3D
var _mesh: CapsuleMesh
var _material: StandardMaterial3D
var _last_max_health: float = NAN
## Last applied config sizes: the shape stores 32-bit floats, so comparing
## against it would never match and would rewrite it every tick.
var _last_width: float = NAN
var _last_height: float = NAN

@onready var _collision: CollisionShape3D = $Collision
@onready var _mesh_instance: MeshInstance3D = $Mesh
@onready var _label: Label3D = $HealthLabel


func _init() -> void:
	# Before the rifle (priority 0): a shot on the respawn tick must see the
	# dummy back.
	process_physics_priority = -1


func _ready() -> void:
	if config == null:
		config = DummyConfig.new()
	# Own copies: instances never share a shape, mesh or material.
	_shape = _collision.shape.duplicate() as CapsuleShape3D
	_collision.shape = _shape
	_mesh = _mesh_instance.mesh.duplicate() as CapsuleMesh
	_material = _mesh.material.duplicate() as StandardMaterial3D
	_mesh.material = _material
	_mesh_instance.mesh = _mesh
	_label.font_size = label_font_size
	_label.pixel_size = label_pixel_size
	_label.outline_size = label_outline_size
	health.ticks_per_second = Engine.physics_ticks_per_second
	_sync_config()
	health.reset()
	_update_label()


## A rifle hit. Returns what it did: IGNORED (dead, or damage <= 0), DAMAGED or KILLED.
func take_hit(damage: float) -> TargetHealth.Result:
	var result: TargetHealth.Result = health.take(damage, Engine.get_physics_frames())
	if result == TargetHealth.Result.IGNORED:
		return result
	damaged.emit(health.last_damage, health.health)
	if result == TargetHealth.Result.KILLED:
		visible = false
		_collision.disabled = true
		died.emit()
	return result


func _physics_process(_delta: float) -> void:
	_sync_config()
	if health.tick(Engine.get_physics_frames()):
		visible = true
		_collision.disabled = false
		respawned.emit()


func _process(_delta: float) -> void:
	_update_label()


func _sync_config() -> void:
	var radius: float = config.width / 2.0
	var height: float = maxf(config.height, config.width)
	var centre: Vector3 = Vector3(0.0, height / 2.0, 0.0)
	if config.width != _last_width or config.height != _last_height:
		_last_width = config.width
		_last_height = config.height
		# Set height first when growing so height never drops under 2 x radius.
		_shape.height = maxf(height, _shape.height)
		_shape.radius = radius
		_shape.height = height
		_mesh.height = maxf(height, _mesh.height)
		_mesh.radius = radius
		_mesh.height = height
	_collision.position = centre
	_mesh_instance.position = centre
	_label.position = Vector3(0.0, height + label_offset, 0.0)
	_material.albedo_color = config.color
	# Only on change: a clamped value would otherwise warn every tick.
	if config.max_health != _last_max_health:
		_last_max_health = config.max_health
		health.max_health = config.max_health
	health.respawn_delay = config.respawn_delay


func _update_label() -> void:
	if not is_instance_valid(_overlay):
		_overlay = get_tree().get_first_node_in_group(DebugOverlay.GROUP) as DebugOverlay
	_label.visible = _overlay != null and _overlay.panel_visible
	_label.text = str(ceili(health.health))
