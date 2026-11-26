extends GutTest
## The player scene carries Rifle1 and hit markers; the fire action is set up.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const RIFLE1_PATH: String = "res://src/weapons/rifle1_config.tres"


func test_player_has_rifle1() -> void:
	var player: Node = PLAYER_SCENE.instantiate()
	var rifle: Rifle = player.get_node_or_null("Rifle") as Rifle
	assert_not_null(rifle, "Rifle child")
	if rifle != null:
		assert_not_null(rifle.config)
		if rifle.config != null:
			assert_eq(rifle.config.resource_path, RIFLE1_PATH)
			assert_almost_eq(rifle.config.shots_per_second, 4.0, 0.001)
			assert_true(rifle.config.full_auto)
			assert_almost_eq(rifle.config.dps, 100.0, 0.001)
	assert_not_null(player.get_node_or_null("HitMarkers") as HitMarkers, "HitMarkers child")
	player.free()


func test_fire_is_left_mouse_button() -> void:
	assert_true(InputMap.has_action("fire"))
	if not InputMap.has_action("fire"):
		return
	var events: Array[InputEvent] = InputMap.action_get_events("fire")
	assert_eq(events.size(), 1)
	if events.size() != 1:
		return
	var button: InputEventMouseButton = events[0] as InputEventMouseButton
	assert_not_null(button)
	if button != null:
		assert_eq(button.button_index, MOUSE_BUTTON_LEFT)
