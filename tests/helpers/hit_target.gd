class_name HitTarget
extends StaticBody3D
## Test target: a static box that records every take_hit call.

var hits: Array[float] = []


## A box of the given size centred at position.
static func make(size: Vector3, position: Vector3) -> HitTarget:
	var target: HitTarget = HitTarget.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	target.add_child(shape)
	target.position = position
	return target


func take_hit(damage: float) -> void:
	hits.append(damage)
