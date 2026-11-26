extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const CONFIG_PATH: String = "res://src/player/player_config.tres"

var _player: SUCC


func before_each() -> void:
	Input.use_accumulated_input = true
	_player = PLAYER_SCENE.instantiate() as SUCC
	add_child_autofree(_player)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_root_is_succ_with_our_config() -> void:
	assert_not_null(_player)
	assert_eq(_player.config.resource_path, CONFIG_PATH)


func test_config_values() -> void:
	var config: SUCCConfig = _player.config
	assert_almost_eq(config.max_speed, 10.16, 0.0001)
	assert_almost_eq(config.gravity, 20.32, 0.0001)
	assert_almost_eq(config.jump_height, 1.143, 0.0001)
	assert_almost_eq(config.air_acceleration, 100.0, 0.0001)
	assert_almost_eq(config.sprint_speed_modifier, 1.0, 0.0001)


func test_bhop_and_surf_on() -> void:
	assert_true(_player.enable_bhop)
	assert_true(_player.enable_surf)
	assert_true(_player.config.bhop_buffered_jump)


func test_has_respawn_and_input_setup_children() -> void:
	var has_respawn: bool = false
	var has_input_setup: bool = false
	for child: Node in _player.get_children():
		has_respawn = has_respawn or child is PlayerRespawn
		has_input_setup = has_input_setup or child is PlayerInputSetup
	assert_true(has_respawn, "has PlayerRespawn child")
	assert_true(has_input_setup, "has PlayerInputSetup child")


func test_input_is_not_accumulated_after_ready() -> void:
	assert_false(Input.use_accumulated_input)


# Behaviour 3 of workflow/plans/013-slope-stick.md.
func test_floor_angles_meet_at_source_limit() -> void:
	assert_almost_eq(_player.ramp_angle_threshold, acos(0.7), 0.0001)
	assert_almost_eq(_player.max_floor_angle, deg_to_rad(45.0), 0.0001)
