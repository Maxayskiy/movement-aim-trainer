extends GutTest
## HitFeedback on the real player: workflow/plans/018-hit-feedback.md.
## The player stands at the origin facing -Z, a dummy with its feet at (0, 0, -10).

const DUMMY_SCENE: PackedScene = preload("res://src/targets/dummy.tscn")
const FEEDBACK_SCENE: PackedScene = preload("res://src/ui/hit_feedback.tscn")
const DUMMY_CONFIG_PATH: String = "res://src/targets/dummy_config.tres"
const FEEDBACK_CONFIG_PATH: String = "res://src/ui/hit_feedback_config.tres"
const HITSOUND_PATH: String = "res://assets/audio/hitsound.wav"
const KILLSOUND_PATH: String = "res://assets/audio/killsound.wav"
const SHOT_GAP_TICKS: int = 32
const ALPHA_TOL: float = 0.001
const DB_TOL: float = 0.01
const FLOAT_TOL: float = 0.0001
const WALL_Z: float = -20.0

var _rig: MovementRig
var _player: SUCC
var _rifle: Rifle
var _feedback: HitFeedback
var _view: HitMarkerView
var _config: HitFeedbackConfig
var _dummy: Dummy
## Signal log: [name, tick].
var _events: Array[Array] = []
## fade.alpha at the moment of the last sound signal (the hit).
var _alpha_at_hit: float = -1.0


func before_each() -> void:
	_events.clear()
	_rig = MovementRig.new()
	add_child_autofree(_rig)
	_player = _rig.spawn(MovementRig.test_config())
	_rifle = _player.get_node("Rifle") as Rifle
	_rifle.require_captured_mouse = false
	_rifle.config = _rifle.config.duplicate() as RifleConfig
	_feedback = _player.get_node("HitFeedback") as HitFeedback
	_view = _feedback.get_node("Marker") as HitMarkerView
	# A copy: tests change it, and the .tres is shared.
	_config = (load(FEEDBACK_CONFIG_PATH) as HitFeedbackConfig).duplicate() as HitFeedbackConfig
	_feedback.config = _config
	_feedback.hitsound_played.connect(_on_sound.bind("hit"))
	_feedback.killsound_played.connect(_on_sound.bind("kill"))
	watch_signals(_feedback)


func after_each() -> void:
	_fire_event(false)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_sound(sound: String) -> void:
	_events.append([sound, Engine.get_physics_frames()])
	_alpha_at_hit = _feedback.fade.alpha(_now())


func _add_dummy() -> void:
	_dummy = DUMMY_SCENE.instantiate() as Dummy
	_dummy.config = (load(DUMMY_CONFIG_PATH) as DummyConfig).duplicate() as DummyConfig
	_dummy.config.max_health = 100.0
	_dummy.position = Vector3(0.0, 0.0, -10.0)
	_rig.add_child(_dummy)


func _add_wall() -> StaticBody3D:
	var wall: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(10.0, 10.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0.0, 2.0, WALL_Z - 0.5)
	_rig.add_child(wall)
	return wall


func _settle() -> void:
	assert_true(await _rig.settle(), "player settles")
	await get_tree().process_frame


func _fire_event(pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _ticks(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame
	await get_tree().process_frame


## One shot, then one more render frame so HitFeedback._process has run.
func _click() -> void:
	_fire_event(true)
	_fire_event(false)
	await _ticks(2)
	await get_tree().process_frame


func _hold_fire(shots: int) -> void:
	_fire_event(true)
	await _ticks((shots - 1) * SHOT_GAP_TICKS + 2)
	_fire_event(false)
	await get_tree().process_frame


func _now() -> float:
	return Time.get_ticks_usec() / 1e6


func _named(sound: String) -> Array[Array]:
	var found: Array[Array] = []
	for event: Array in _events:
		if event[0] == sound:
			found.append(event)
	return found


func _assert_color(got: Color, expected: Color, text: String) -> void:
	assert_almost_eq(got.r, expected.r, FLOAT_TOL, text + " r")
	assert_almost_eq(got.g, expected.g, FLOAT_TOL, text + " g")
	assert_almost_eq(got.b, expected.b, FLOAT_TOL, text + " b")
	assert_almost_eq(got.a, expected.a, FLOAT_TOL, text + " a")


## Hit dummy, ready to shoot.
func _dummy_setup() -> void:
	_add_dummy()
	await _settle()


func test_scene_defaults() -> void:
	assert_eq(_feedback.layer, 2)
	assert_not_null(_feedback.get_node_or_null("Marker") as HitMarkerView, "Marker")
	assert_not_null(_feedback.get_node_or_null("HitSound") as AudioStreamPlayer, "HitSound")
	assert_not_null(_feedback.get_node_or_null("KillSound") as AudioStreamPlayer, "KillSound")
	var shipped: HitFeedbackConfig = load(FEEDBACK_CONFIG_PATH) as HitFeedbackConfig
	var scene: HitFeedback = FEEDBACK_SCENE.instantiate() as HitFeedback
	assert_eq(scene.config, shipped, "scene uses the shipped config")
	scene.free()
	assert_true(shipped.marker_enabled)
	assert_almost_eq(shipped.marker_gap, 8.0, FLOAT_TOL)
	assert_almost_eq(shipped.marker_length, 8.0, FLOAT_TOL)
	assert_almost_eq(shipped.marker_thickness, 2.0, FLOAT_TOL)
	assert_almost_eq(shipped.marker_outline, 1.0, FLOAT_TOL)
	_assert_color(shipped.marker_outline_color, Color(0.16, 0.16, 0.18, 1.0), "outline")
	assert_almost_eq(shipped.marker_duration, 0.25, FLOAT_TOL)
	_assert_color(shipped.hit_color, Color(1.0, 1.0, 1.0, 1.0), "hit")
	_assert_color(shipped.kill_color, Color(1.0, 0.15, 0.15, 1.0), "kill")
	assert_true(shipped.hitsound_enabled)
	assert_true(shipped.killsound_enabled)
	assert_eq(shipped.hitsound_volume, 100)
	assert_eq(shipped.killsound_volume, 100)
	assert_eq(shipped.max_voices, 8)
	assert_true(shipped.hitsound is AudioStream, "hitsound loads")
	assert_true(shipped.killsound is AudioStream, "killsound loads")
	if shipped.hitsound != null:
		assert_eq(shipped.hitsound.resource_path, HITSOUND_PATH)
	if shipped.killsound != null:
		assert_eq(shipped.killsound.resource_path, KILLSOUND_PATH)


func test_hit() -> void:
	await _dummy_setup()
	await _click()
	assert_signal_emit_count(_feedback, "hitsound_played", 1)
	assert_signal_emit_count(_feedback, "killsound_played", 0)
	assert_false(_feedback.fade.killed)
	assert_gt(_alpha_at_hit, 0.9, "alpha at the hit")
	_assert_color(_view.color, _config.hit_color, "view colour")


func test_kill() -> void:
	await _dummy_setup()
	await _hold_fire(4)
	assert_signal_emit_count(_feedback, "hitsound_played", 3)
	assert_signal_emit_count(_feedback, "killsound_played", 1)
	assert_eq(_events.size(), 4)
	if _events.size() == 4:
		for i: int in 3:
			assert_eq(_events[i][0], "hit", "shot %d" % (i + 1))
		assert_eq(_events[3][0], "kill", "shot 4")
	assert_true(_feedback.fade.killed)
	_assert_color(_view.color, _config.kill_color, "view colour")


func test_wall_gives_nothing() -> void:
	_add_wall()
	await _settle()
	await _click()
	assert_signal_emit_count(_feedback, "hitsound_played", 0)
	assert_signal_emit_count(_feedback, "killsound_played", 0)
	assert_almost_eq(_feedback.fade.alpha(_now()), 0.0, ALPHA_TOL)
	assert_almost_eq(_view.alpha, 0.0, ALPHA_TOL)


func test_fade_in_game() -> void:
	await _dummy_setup()
	await _click()
	assert_gt(_view.alpha, 0.0, "showing after the hit")
	await wait_seconds(0.3)
	await get_tree().process_frame
	assert_almost_eq(_view.alpha, 0.0, ALPHA_TOL)


func test_marker_off() -> void:
	await _dummy_setup()
	_config.marker_enabled = false
	await _click()
	assert_signal_emit_count(_feedback, "hitsound_played", 1)
	assert_almost_eq(_view.alpha, 0.0, ALPHA_TOL)
	# Switched off while an X shows.
	_config.marker_enabled = true
	_config.marker_duration = 1.0
	await _ticks(SHOT_GAP_TICKS)
	await _click()
	assert_gt(_view.alpha, 0.0, "showing")
	_config.marker_enabled = false
	await get_tree().process_frame
	assert_almost_eq(_view.alpha, 0.0, ALPHA_TOL)


func test_hitsound_off() -> void:
	await _dummy_setup()
	_config.hitsound_enabled = false
	await _click()
	assert_signal_emit_count(_feedback, "hitsound_played", 0)


func test_killsound_off_plays_hitsound_on_kill() -> void:
	await _dummy_setup()
	_config.killsound_enabled = false
	await _hold_fire(4)
	assert_signal_emit_count(_feedback, "hitsound_played", 4)
	assert_signal_emit_count(_feedback, "killsound_played", 0)


func test_both_off_kill_is_silent() -> void:
	await _dummy_setup()
	_dummy.config.max_health = 25.0
	_config.hitsound_enabled = false
	_config.killsound_enabled = false
	await _click()
	assert_true(_feedback.fade.killed, "the shot killed")
	assert_signal_emit_count(_feedback, "hitsound_played", 0)
	assert_signal_emit_count(_feedback, "killsound_played", 0)


func test_hitsound_volume() -> void:
	await _dummy_setup()
	var player: AudioStreamPlayer = _feedback.get_node("HitSound") as AudioStreamPlayer
	_config.hitsound_volume = 50
	await _click()
	assert_almost_eq(player.volume_db, linear_to_db(0.5), DB_TOL)
	assert_almost_eq(player.volume_db, -6.02, DB_TOL)
	_config.hitsound_volume = 100
	await _ticks(SHOT_GAP_TICKS)
	await _click()
	assert_almost_eq(player.volume_db, 0.0, DB_TOL)
	assert_signal_emit_count(_feedback, "hitsound_played", 2)
	_config.hitsound_volume = 0
	await _ticks(SHOT_GAP_TICKS)
	await _click()
	assert_signal_emit_count(_feedback, "hitsound_played", 2, "0 % is silent")


func test_killsound_volume() -> void:
	await _dummy_setup()
	_config.killsound_volume = 25
	await _hold_fire(4)
	assert_signal_emit_count(_feedback, "killsound_played", 1)
	var player: AudioStreamPlayer = _feedback.get_node("KillSound") as AudioStreamPlayer
	assert_almost_eq(player.volume_db, -12.04, DB_TOL)


func test_voices() -> void:
	await _dummy_setup()
	var player: AudioStreamPlayer = _feedback.get_node("HitSound") as AudioStreamPlayer
	await _click()
	assert_eq(player.max_polyphony, 8, "default")
	_config.max_voices = 3
	await _ticks(SHOT_GAP_TICKS)
	await _click()
	assert_eq(player.max_polyphony, 3)


func test_second_hit_keeps_the_first_voice() -> void:
	# A 1 s sound and 64 shots/s: the first voice still plays at the second hit.
	var long_sound: AudioStreamWAV = AudioStreamWAV.new()
	long_sound.mix_rate = 44100
	var data: PackedByteArray = PackedByteArray()
	data.resize(44100)
	long_sound.data = data
	_config.hitsound = long_sound
	_rifle.config.shots_per_second = 64.0
	await _dummy_setup()
	var player: AudioStreamPlayer = _feedback.get_node("HitSound") as AudioStreamPlayer
	_fire_event(true)
	for i: int in 64:
		await get_tree().physics_frame
		if not _named("hit").is_empty():
			break
	var first: AudioStreamPlayback = player.get_stream_playback()
	assert_not_null(first, "first voice")
	for i: int in 64:
		await get_tree().physics_frame
		if _named("hit").size() >= 2:
			break
	_fire_event(false)
	assert_eq(_named("hit").size(), 2, "two hits")
	if first != null:
		# A cut-off voice stops mixing, so its position stops moving.
		var start: float = first.get_playback_position()
		await wait_seconds(0.2)
		var moved: float = first.get_playback_position() - start
		assert_gt(moved, 0.1, "first voice still plays (moved %.3f s in 0.2 s)" % moved)


func test_null_stream_is_silent_but_marker_shows() -> void:
	await _dummy_setup()
	_config.hitsound = null
	await _click()
	assert_signal_emit_count(_feedback, "hitsound_played", 0)
	assert_gt(_view.alpha, 0.0, "X still shows")


func test_live_kill_colour() -> void:
	await _dummy_setup()
	_dummy.config.max_health = 25.0
	_config.marker_duration = 1.0
	await _click()
	assert_true(_feedback.fade.killed)
	_config.kill_color = Color(0.0, 0.0, 1.0, 1.0)
	await get_tree().process_frame
	_assert_color(_view.color, Color(0.0, 0.0, 1.0, 1.0), "view colour")


func test_no_rifle_no_error() -> void:
	var alone: HitFeedback = FEEDBACK_SCENE.instantiate() as HitFeedback
	add_child_autofree(alone)
	await get_tree().process_frame
	assert_almost_eq(alone.fade.alpha(_now()), 0.0, ALPHA_TOL)


func test_debug_spheres_unchanged() -> void:
	var overlay: DebugOverlay = _player.get_node("DebugOverlay") as DebugOverlay
	(overlay.get_node("Panel") as Control).visible = true
	var markers: HitMarkers = _player.get_node("HitMarkers") as HitMarkers
	await _dummy_setup()
	await _click()
	assert_eq(markers.marker_count(), 1)
	assert_signal_emit_count(_feedback, "hitsound_played", 1)
