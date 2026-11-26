extends GutTest
## Target range station: behaviour 10 of workflow/plans/017-static-target-dummy.md.

const COURSE_PATH: String = "res://levels/movement_course/movement_course.tscn"
const DUMMY_SCENE_PATH: String = "res://src/targets/dummy.tscn"
const CONFIG_PATH: String = "res://src/targets/dummy_config.tres"
const POS_TOL: float = 0.001
const EYE: Vector3 = Vector3(50.0, 1.711, -30.0)
const DUMMY_CENTRE_Y: float = 0.9145

## Dummy node name -> feet position (plan, behaviour 10 table).
const DUMMIES: Dictionary[String, Vector3] = {
	"Dummy05": Vector3(48.0, 0.0, -35.0),
	"Dummy10": Vector3(52.0, 0.0, -40.0),
	"Dummy20": Vector3(46.0, 0.0, -50.0),
	"Dummy40": Vector3(54.0, 0.0, -70.0),
	"Dummy60": Vector3(50.0, 0.0, -90.0),
}

var _course: Node3D


func before_each() -> void:
	var scene: PackedScene = load(COURSE_PATH) as PackedScene
	_course = scene.instantiate() as Node3D
	add_child_autofree(_course)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_five_dummies_at_their_spots() -> void:
	var targets: Node = _course.get_node_or_null("Targets")
	assert_not_null(targets, "Targets exists")
	if targets == null:
		return
	assert_eq(targets.get_child_count(), DUMMIES.size(), "five children")
	var config: DummyConfig = load(CONFIG_PATH) as DummyConfig
	for dummy_name: String in DUMMIES:
		var dummy: Dummy = targets.get_node_or_null(dummy_name) as Dummy
		assert_not_null(dummy, "%s is a Dummy" % dummy_name)
		if dummy == null:
			continue
		assert_eq(dummy.scene_file_path, DUMMY_SCENE_PATH, "%s scene" % dummy_name)
		assert_almost_eq(
			dummy.global_position, DUMMIES[dummy_name], Vector3.ONE * POS_TOL, dummy_name
		)
		assert_eq(dummy.config, config, "%s uses the shared config" % dummy_name)


func test_sign() -> void:
	var sign_label: Label3D = _course.get_node_or_null("Stations/TargetRange/Sign") as Label3D
	assert_not_null(sign_label)
	if sign_label == null:
		return
	assert_eq(sign_label.billboard, BaseMaterial3D.BILLBOARD_DISABLED)
	assert_eq(sign_label.text, "TARGET RANGE\n5–60 m")
	assert_almost_eq(sign_label.global_position, Vector3(50.0, 3.0, -26.0), Vector3.ONE * POS_TOL)


func test_firing_line() -> void:
	var line: MeshInstance3D = (
		_course.get_node_or_null("Stations/TargetRange/FiringLine") as MeshInstance3D
	)
	assert_not_null(line)
	if line == null:
		return
	assert_almost_eq(line.global_position, Vector3(50.0, 0.005, -30.0), Vector3.ONE * POS_TOL)
	assert_eq(line.find_children("*", "CollisionObject3D", true, false).size(), 0, "no body")
	assert_false(line.get_parent() is CollisionObject3D, "not part of a body")


func test_each_dummy_is_in_sight_from_the_line() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = _course.get_world_3d().direct_space_state
	var player: SUCC = _course.get_node("Player") as SUCC
	for dummy_name: String in DUMMIES:
		var dummy: Dummy = _course.get_node("Targets/%s" % dummy_name) as Dummy
		var centre: Vector3 = DUMMIES[dummy_name] + Vector3.UP * DUMMY_CENTRE_Y
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			EYE, centre, 0xFFFFFFFF, [player.get_rid()]
		)
		var hit: Dictionary = space.intersect_ray(query)
		assert_false(hit.is_empty(), "%s: ray hits something" % dummy_name)
		if not hit.is_empty():
			assert_eq(hit["collider"], dummy, "%s is hit first" % dummy_name)
