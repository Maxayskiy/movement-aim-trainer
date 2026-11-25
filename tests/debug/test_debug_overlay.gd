extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const NO_VALUE: String = "—"

var _player: SUCC
var _overlay: DebugOverlay


func before_each() -> void:
	_player = _spawn_player()


func after_each() -> void:
	Input.action_release("forward")


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _spawn_player(start_visible: bool = true, show_speedometer: bool = true) -> SUCC:
	var player: SUCC = PLAYER_SCENE.instantiate() as SUCC
	_overlay = player.get_node("DebugOverlay") as DebugOverlay
	_overlay.start_visible = start_visible
	_overlay.show_speedometer = show_speedometer
	add_child_autofree(player)
	player.set_physics_process(false)
	return player


func _speedometer() -> Label:
	return _overlay.get_node("Speedometer") as Label


func _panel() -> Control:
	return _overlay.get_node("Panel") as Control


func _stats() -> Label:
	return _overlay.get_node("Panel/VBox/Stats") as Label


func _key(key_name: String) -> Label:
	return _overlay.get_node("Panel/VBox/Keys/" + key_name) as Label


func _press_toggle() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = "toggle_debug"
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _all_controls(node: Node) -> Array[Control]:
	var found: Array[Control] = []
	for child: Node in node.get_children():
		if child is Control:
			found.append(child as Control)
		found.append_array(_all_controls(child))
	return found


func test_player_has_overlay() -> void:
	assert_not_null(_overlay)
	assert_true(_player.get_node("DebugOverlay") is DebugOverlay)


func test_shows_speed_and_stats() -> void:
	_player.velocity = Vector3(10.16, -5.0, 0.0)
	await wait_process_frames(1)
	assert_eq(_speedometer().text, "400")
	var stats: String = _stats().text
	assert_string_contains(stats, "-197")
	assert_string_contains(stats, str(SUCC.MovementState.keys()[_player.movement_state]))
	assert_string_contains(stats, str(SUCC.FloorType.keys()[_player.floor_type]))


func test_no_control_catches_the_mouse() -> void:
	var controls: Array[Control] = _all_controls(_overlay)
	assert_gt(controls.size(), 0)
	for control: Control in controls:
		assert_eq(
			control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s ignores mouse" % control.name
		)


func test_speedometer_and_panel_visible_at_start() -> void:
	assert_true(_speedometer().visible)
	assert_true(_panel().visible)
	assert_true(_overlay.panel_visible)


func test_toggle_hides_and_shows_panel() -> void:
	_press_toggle()
	assert_false(_panel().visible)
	assert_true(_speedometer().visible)
	_press_toggle()
	assert_true(_panel().visible)


func test_start_hidden() -> void:
	_player = _spawn_player(false)
	assert_false(_panel().visible)
	assert_true(_speedometer().visible)


func test_speedometer_can_be_off() -> void:
	_player = _spawn_player(true, false)
	assert_false(_speedometer().visible)


func test_key_boxes_light_while_held() -> void:
	Input.action_press("forward")
	await wait_process_frames(1)
	assert_almost_eq(_key("KeyW").modulate.a, 1.0, 0.001)
	assert_almost_eq(_key("KeyS").modulate.a, 0.3, 0.001)


func test_respawn_clears_bhop_stats() -> void:
	_player.velocity = Vector3(8.0, 0.0, 0.0)
	_player.jumped.emit()
	assert_eq(_overlay.tracker.hops, 1)
	assert_true(_overlay.tracker.has_takeoff)
	(_player.get_node("Respawn") as PlayerRespawn).respawn()
	await wait_process_frames(1)
	assert_eq(_overlay.tracker.hops, 0)
	assert_false(_overlay.tracker.has_takeoff)
	assert_false(_overlay.tracker.has_gain)
	assert_eq(_overlay.tracker.last_ground_ticks, -1)
	assert_string_contains(_stats().text, "takeoff  " + NO_VALUE)


func test_perf_lines_fill_in() -> void:
	await wait_seconds(0.3)
	var stats: String = _stats().text
	for label: String in ["fps", "frame", "process", "physics", "ticks/s"]:
		var line: String = _find_line(stats, label)
		assert_ne(line, "", "%s line exists" % label)
		assert_false(line.contains(NO_VALUE), "%s has a number: %s" % [label, line])


func _find_line(text: String, label: String) -> String:
	for line: String in text.split("\n"):
		if line.begins_with(label + " "):
			return line
	return ""
