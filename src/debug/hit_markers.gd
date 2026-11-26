class_name HitMarkers
extends Node3D
## Debug: a small red sphere at each rifle hit while the F3 panel is visible.
## A child of the Player root; listens to the sibling Rifle, Respawn and DebugOverlay.

@export var marker_diameter: float = 0.08
## Seconds a marker stays.
@export var marker_lifetime: float = 2.0
## The oldest marker goes first when a new one would pass this.
@export var max_markers: int = 64
@export var marker_color: Color = Color(1.0, 0.0, 0.0)

var _overlay: DebugOverlay
var _mesh: SphereMesh
## Each entry: [MeshInstance3D, spawn time in usec].
var _markers: Array[Array] = []


func _ready() -> void:
	# Markers stay at world hit points while the player moves.
	top_level = true
	global_transform = Transform3D.IDENTITY
	_build_mesh()
	var parent: Node = get_parent()
	if parent == null:
		return
	_overlay = parent.get_node_or_null("DebugOverlay") as DebugOverlay
	var rifle: Rifle = parent.get_node_or_null("Rifle") as Rifle
	if rifle != null:
		rifle.shot_fired.connect(_on_shot_fired)
	var respawn: PlayerRespawn = parent.get_node_or_null("Respawn") as PlayerRespawn
	if respawn != null:
		respawn.respawned.connect(clear)


func marker_count() -> int:
	return _markers.size()


## Marker world positions, oldest first.
func marker_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for entry: Array in _markers:
		positions.append((entry[0] as MeshInstance3D).global_position)
	return positions


func clear() -> void:
	for entry: Array in _markers:
		(entry[0] as Node).queue_free()
	_markers.clear()


func _process(_delta: float) -> void:
	visible = _panel_visible()
	var now: int = Time.get_ticks_usec()
	var lifetime_usec: int = int(marker_lifetime * 1_000_000.0)
	while not _markers.is_empty() and now - (_markers[0][1] as int) >= lifetime_usec:
		(_markers[0][0] as Node).queue_free()
		_markers.remove_at(0)


func _panel_visible() -> bool:
	return _overlay != null and _overlay.panel_visible


func _on_shot_fired(
	_origin: Vector3, _direction: Vector3, hit_position: Vector3, collider: Object
) -> void:
	if collider == null or not _panel_visible():
		return
	while _markers.size() >= max_markers and not _markers.is_empty():
		(_markers[0][0] as Node).queue_free()
		_markers.remove_at(0)
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.mesh = _mesh
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)
	marker.global_position = hit_position
	_markers.append([marker, Time.get_ticks_usec()])


func _build_mesh() -> void:
	_mesh = SphereMesh.new()
	_mesh.radius = marker_diameter / 2.0
	_mesh.height = marker_diameter
	_mesh.radial_segments = 12
	_mesh.rings = 6
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = marker_color
	_mesh.material = material
