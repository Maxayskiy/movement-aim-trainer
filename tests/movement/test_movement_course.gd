extends GutTest
## Behaviour 1, 2, 11 and 12 of workflow/plans/014-movement-course.md.

const COURSE_PATH: String = "res://levels/movement_course/movement_course.tscn"
const OLD_COURSE_PATH: String = "res://levels/test_course/test_course.tscn"
const HUD_THEME_PATH: String = "res://assets/ui/hud_theme.tres"
const POS_TOL: float = 0.001

## Station node name -> sign text (plan, Signs table).
const SIGNS: Dictionary = {
	"StrafeLane": "STRAFE LANE\n107 m",
	"Bhop": "BHOP GAPS\n400–600 u/s",
	"Surf": "SURF\n53°",
	"SeamsEdges": "SEAMS & EDGES\n15° · 30°",
	"Steps": "STEPS\n0.30 · 0.44 · 0.46 · 0.60 m",
	"Ledges": "LEDGES\n1.56 · 1.66 m",
	"Slopes": "SLOPES\n15 · 30 · 44 · 46°",
	"CrouchTunnel": "CROUCH TUNNEL\n1.02 m",
}

var _course: Node


func before_each() -> void:
	var scene: PackedScene = load(COURSE_PATH) as PackedScene
	_course = scene.instantiate()
	add_child_autofree(_course)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_main_scene_is_course() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	if main.begins_with("uid://"):
		main = ResourceUID.uid_to_path(main)
	assert_eq(main, COURSE_PATH)
	assert_false(ResourceLoader.exists(OLD_COURSE_PATH), "demo course deleted")


func test_player_is_our_scene() -> void:
	var player: Node = _course.get_node_or_null("Player")
	assert_not_null(player)
	if player:
		assert_eq(player.scene_file_path, "res://src/player/player.tscn")


func test_player_spawns_on_hub_facing_west() -> void:
	var player: Node3D = _course.get_node("Player") as Node3D
	assert_almost_eq(player.position, Vector3(0.0, 0.11, 0.0), Vector3.ONE * POS_TOL)
	var facing: Vector3 = -player.global_transform.basis.z
	assert_almost_eq(facing, Vector3(-1.0, 0.0, 0.0), Vector3.ONE * 0.01, "faces -X")


func test_crosshair_uses_hud_theme() -> void:
	assert_not_null(_course.get_node_or_null("UI/HUD/Crosshair"))
	var hud: Control = _course.get_node_or_null("UI/HUD") as Control
	assert_not_null(hud)
	if hud and hud.theme:
		assert_eq(hud.theme.resource_path, HUD_THEME_PATH)
	else:
		fail_test("HUD has no theme")


func test_no_csg_and_every_body_is_a_course_box() -> void:
	# The player's own CSGMesh3D visuals (src/player, not touched) don't count.
	for child: Node in _course.get_children():
		if child.name == "Player":
			continue
		var csg: Array[Node] = child.find_children("*", "CSGShape3D", true, false)
		assert_eq(csg.size(), 0, "no CSG under %s" % child.name)
		assert_false(child is CSGShape3D, "%s is not CSG" % child.name)
	var bodies: Array[Node] = []
	for root_name: String in ["Floor", "Stations"]:
		var root: Node = _course.get_node(root_name)
		if root is StaticBody3D:
			bodies.append(root)
		bodies.append_array(root.find_children("*", "StaticBody3D", true, false))
	assert_gt(bodies.size(), 50, "course has its pieces")
	for body: Node in bodies:
		assert_true(body is CourseBox, "%s is a CourseBox" % body.name)
		if body is CourseBox:
			assert_not_null((body as CourseBox).material, "%s has a material" % body.name)


func test_floor_size_and_top() -> void:
	var floor_box: CourseBox = _course.get_node("Floor") as CourseBox
	assert_not_null(floor_box)
	if floor_box == null:
		return
	assert_eq(floor_box.size, Vector3(200.0, 1.0, 200.0))
	var top: float = floor_box.global_position.y + floor_box.size.y / 2.0
	assert_almost_eq(top, 0.0, POS_TOL, "floor top at y = 0")


func test_station_signs() -> void:
	for station: String in SIGNS:
		var sign_label: Label3D = _course.get_node_or_null("Stations/%s/Sign" % station) as Label3D
		assert_not_null(sign_label, "%s has a Sign" % station)
		if sign_label == null:
			continue
		assert_eq(
			sign_label.billboard, BaseMaterial3D.BILLBOARD_DISABLED, "%s not billboard" % station
		)
		assert_eq(sign_label.text, SIGNS[station])


func test_bhop_block_labels() -> void:
	for v: int in [400, 450, 500, 550, 600]:
		var block_label: Label3D = _course.get_node_or_null("Stations/Bhop/Label%d" % v) as Label3D
		assert_not_null(block_label, "Label%d exists" % v)
		if block_label:
			assert_eq(block_label.text, str(v))
