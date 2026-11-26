@tool
class_name CourseBox
extends StaticBody3D
## A solid grey-box piece: one BoxShape3D and one BoxMesh, both of size.
## They are internal, unowned children, so a scene saves only the transform,
## size and material of each piece.

## Box size in m (x, y, z).
@export var size: Vector3 = Vector3.ONE:
	set(value):
		size = value
		_apply()

## Material drawn on the box.
@export var material: Material:
	set(value):
		material = value
		_apply()

var _shape: CollisionShape3D
var _mesh: MeshInstance3D


func _ready() -> void:
	_shape = CollisionShape3D.new()
	_shape.shape = BoxShape3D.new()
	add_child(_shape, false, Node.INTERNAL_MODE_FRONT)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = BoxMesh.new()
	add_child(_mesh, false, Node.INTERNAL_MODE_FRONT)
	_apply()


func _apply() -> void:
	if _shape == null or _mesh == null:
		return
	(_shape.shape as BoxShape3D).size = size
	(_mesh.mesh as BoxMesh).size = size
	_mesh.material_override = material
