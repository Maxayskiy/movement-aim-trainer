extends GutTest

const KEYED_ACTIONS: Dictionary[String, Key] = {
	"forward": KEY_W,
	"back": KEY_S,
	"left": KEY_A,
	"right": KEY_D,
	"jump": KEY_SPACE,
	"crouch": KEY_CTRL,
	"respawn": KEY_R,
}


func test_physics_runs_at_128_ticks() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 128)


func test_each_action_has_one_physical_key() -> void:
	for action: String in KEYED_ACTIONS:
		assert_true(InputMap.has_action(action), "%s exists" % action)
		if not InputMap.has_action(action):
			continue
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		assert_eq(events.size(), 1, "%s has exactly one event" % action)
		if events.size() != 1:
			continue
		var key: InputEventKey = events[0] as InputEventKey
		assert_not_null(key, "%s event is a key" % action)
		if key == null:
			continue
		assert_eq(key.physical_keycode, KEYED_ACTIONS[action], "%s physical key" % action)
		assert_eq(key.keycode, KEY_NONE, "%s uses physical keycode only" % action)


func test_crouch_is_left_ctrl() -> void:
	var events: Array[InputEvent] = InputMap.action_get_events("crouch")
	assert_eq(events.size(), 1)
	if events.size() == 1:
		assert_eq((events[0] as InputEventKey).location, KEY_LOCATION_LEFT)


func test_jump_has_no_mouse_button() -> void:
	for event: InputEvent in InputMap.action_get_events("jump"):
		assert_false(event is InputEventMouseButton, "jump has no mouse button")


func test_sprint_exists_with_no_events() -> void:
	assert_true(InputMap.has_action("sprint"))
	assert_eq(InputMap.action_get_events("sprint").size(), 0)
