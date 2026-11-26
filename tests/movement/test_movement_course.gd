extends GutTest

const COURSE_PATH: String = "res://levels/test_course/test_course.tscn"

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


func test_player_is_our_scene() -> void:
	var player: Node = _course.get_node_or_null("Player")
	assert_not_null(player)
	if player:
		assert_eq(player.scene_file_path, "res://src/player/player.tscn")


func test_demo_level_pieces_removed() -> void:
	assert_null(_course.get_script(), "root has no script")
	for node_name: String in ["JumpSound", "Speedo", "PresetPanel", "Hint"]:
		assert_null(_course.find_child(node_name, true, false), "%s removed" % node_name)
	assert_not_null(_course.get_node_or_null("UI/HUD/Crosshair"))
