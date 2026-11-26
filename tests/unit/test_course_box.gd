extends GutTest
## Behaviour 12 of workflow/plans/014-movement-course.md: CourseBox itself.

const SIZE: Vector3 = Vector3(2.0, 3.0, 4.0)


func _make_box(size: Vector3 = SIZE, material: Material = null) -> CourseBox:
	var box: CourseBox = CourseBox.new()
	box.size = size
	box.material = material
	add_child_autofree(box)
	return box


func _shape_of(box: CourseBox) -> BoxShape3D:
	for child: Node in box.get_children(true):
		if child is CollisionShape3D:
			return (child as CollisionShape3D).shape as BoxShape3D
	return null


func _mesh_node_of(box: CourseBox) -> MeshInstance3D:
	for child: Node in box.get_children(true):
		if child is MeshInstance3D:
			return child as MeshInstance3D
	return null


func _count_internal(box: CourseBox) -> Dictionary:
	var counts: Dictionary = {"shape": 0, "mesh": 0}
	for child: Node in box.get_children(true):
		if child is CollisionShape3D:
			counts["shape"] += 1
		elif child is MeshInstance3D:
			counts["mesh"] += 1
	return counts


func test_builds_shape_and_mesh_of_size() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	var box: CourseBox = _make_box(SIZE, material)
	var counts: Dictionary = _count_internal(box)
	assert_eq(counts["shape"], 1, "one CollisionShape3D")
	assert_eq(counts["mesh"], 1, "one MeshInstance3D")
	var shape: BoxShape3D = _shape_of(box)
	assert_not_null(shape, "shape is a BoxShape3D")
	if shape:
		assert_eq(shape.size, SIZE)
	var mesh_node: MeshInstance3D = _mesh_node_of(box)
	assert_not_null(mesh_node)
	if mesh_node:
		var mesh: BoxMesh = mesh_node.mesh as BoxMesh
		assert_not_null(mesh, "mesh is a BoxMesh")
		if mesh:
			assert_eq(mesh.size, SIZE)
		assert_eq(mesh_node.material_override, material)


func test_size_change_after_ready_updates_both() -> void:
	var box: CourseBox = _make_box()
	var new_size: Vector3 = Vector3(5.0, 0.5, 7.0)
	box.size = new_size
	assert_eq(_shape_of(box).size, new_size)
	assert_eq((_mesh_node_of(box).mesh as BoxMesh).size, new_size)


func test_material_change_after_ready_updates_mesh() -> void:
	var box: CourseBox = _make_box()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	box.material = material
	assert_eq(_mesh_node_of(box).material_override, material)


func test_instances_share_nothing() -> void:
	var a: CourseBox = _make_box()
	var b: CourseBox = _make_box()
	assert_ne(_shape_of(a), _shape_of(b), "own shapes")
	assert_ne(_mesh_node_of(a).mesh, _mesh_node_of(b).mesh, "own meshes")


func test_children_are_internal_and_not_saved() -> void:
	var box: CourseBox = _make_box()
	assert_eq(box.get_child_count(), 0, "no public children")
	assert_eq(box.get_child_count(true), 2, "two internal children")
	var packed: PackedScene = PackedScene.new()
	assert_eq(packed.pack(box), OK)
	var copy: CourseBox = packed.instantiate() as CourseBox
	assert_not_null(copy, "copy is a CourseBox")
	if copy == null:
		return
	add_child_autofree(copy)
	assert_eq(copy.get_child_count(), 0, "copy has no public children")
	assert_eq(copy.get_child_count(true), 2, "copy has exactly two internal children")
	assert_eq(copy.size, SIZE, "size is saved")
	assert_eq(_shape_of(copy).size, SIZE)
