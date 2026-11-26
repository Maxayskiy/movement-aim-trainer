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

@onready var _collision: CollisionShape3D = $Collision
@onready var _mesh_instance: MeshInstance3D = $Mesh
@onready var _label: Label3D = $HealthLabel


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


func take_hit(damage: float) -> void:
	var result: TargetHealth.Result = health.take(damage, Engine.get_physics_frames())
	if result == TargetHealth.Result.IGNORED:
		return
	damaged.emit(health.last_damage, health.health)
	if result == TargetHealth.Result.KILLED:
		visible = false
		_collision.disabled = true
		died.emit()


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
	if _shape.radius != radius or _shape.height != height:
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
