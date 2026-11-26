extends GutTest
## Dummy on the real player: behaviour 1, 2, 4-9 of
## workflow/plans/017-static-target-dummy.md.
## Standard setup: the player at the origin facing -Z, a dummy with its feet at
## (0, 0, -10) and a 10 x 10 x 1 m wall with its near face at z = -20.

const DUMMY_SCENE: PackedScene = preload("res://src/targets/dummy.tscn")
const CONFIG_PATH: String = "res://src/targets/dummy_config.tres"
const HEALTH_TOL: float = 0.001
const POS_TOL_M: float = 0.001
const WALL_Z: float = -20.0
const SHOT_GAP_TICKS: int = 32
const TPS: int = 128
## Physics ticks the push-out may take (plan, behaviour 6).
const PUSH_OUT_TICKS: int = 2
const SOLID_TOL_M: float = 0.02
const VELOCITY_TOL: float = 0.001
const HULL_SIZE: Vector3 = Vector3(0.813, 1.829, 0.813)
const HULL_CENTRE_Y: float = 0.9145

var _rig: MovementRig
var _player: SUCC
var _rifle: Rifle
var _wall: HitTarget
var _dummy: Dummy
## Signal log: [name, tick, args...].
var _events: Array[Array] = []


func before_each() -> void:
	_events.clear()
	_rig = MovementRig.new()
	add_child_autofree(_rig)


func after_each() -> void:
	_fire_event(false)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## A copy of the shipped config, so tests can change it.
func _config() -> DummyConfig:
	return (load(CONFIG_PATH) as DummyConfig).duplicate() as DummyConfig


func _spawn_player(at: Vector3 = Vector3(0.0, 0.01, 0.0)) -> void:
	_player = _rig.spawn(MovementRig.test_config(), at)
	_rifle = _player.get_node("Rifle") as Rifle
	_rifle.require_captured_mouse = false
	_rifle.config = _rifle.config.duplicate() as RifleConfig


func _add_dummy(feet: Vector3, config: DummyConfig, parent: Node = null) -> Dummy:
	var dummy: Dummy = DUMMY_SCENE.instantiate() as Dummy
	dummy.config = config
	dummy.position = feet
	dummy.damaged.connect(_on_damaged.bind(dummy))
	dummy.died.connect(_on_event.bind("died", dummy))
	dummy.respawned.connect(_on_event.bind("respawned", dummy))
	(parent if parent != null else _rig).add_child(dummy)
	return dummy


## Player at the origin, dummy at z = -10, wall at z = -20, player settled.
func _standard_setup(config: DummyConfig = null) -> void:
	_spawn_player()
	_dummy = _add_dummy(Vector3(0.0, 0.0, -10.0), config if config != null else _config())
	_wall = HitTarget.make(Vector3(10.0, 10.0, 1.0), Vector3(0.0, 2.0, WALL_Z - 0.5))
	_rig.add_child(_wall)
	assert_true(await _rig.settle(), "player settles")
	# One render frame places the camera: a click aims from it.
	await get_tree().process_frame


func _on_damaged(damage: float, health_left: float, dummy: Dummy) -> void:
	_events.append(["damaged", Engine.get_physics_frames(), dummy, damage, health_left])


func _on_event(event_name: String, dummy: Dummy) -> void:
	_events.append([event_name, Engine.get_physics_frames(), dummy])


func _events_named(event_name: String) -> Array[Array]:
	var found: Array[Array] = []
	for event: Array in _events:
		if event[0] == event_name:
			found.append(event)
	return found


func _fire_event(pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## Waits n physics ticks, then returns outside the physics step.
func _ticks(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame
	await get_tree().process_frame


## Holds fire for the given number of shots, then releases.
func _hold_fire(shots: int) -> void:
	_fire_event(true)
	await _ticks((shots - 1) * SHOT_GAP_TICKS + 2)
	_fire_event(false)


## Waits until the dummy's respawned has fired, at most max_ticks.
func _wait_respawn(max_ticks: int) -> void:
	for i: int in max_ticks:
		if not _events_named("respawned").is_empty():
			break
		await get_tree().physics_frame
	await get_tree().process_frame


func _set_panel(shown: bool) -> void:
	var overlay: DebugOverlay = _player.get_node("DebugOverlay") as DebugOverlay
	(overlay.get_node("Panel") as Control).visible = shown


func _capsule(dummy: Dummy) -> CapsuleShape3D:
	return (dummy.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D


func _mesh(dummy: Dummy) -> CapsuleMesh:
	return (dummy.get_node("Mesh") as MeshInstance3D).mesh as CapsuleMesh


func _label(dummy: Dummy) -> Label3D:
	return dummy.get_node("HealthLabel") as Label3D


func _assert_size(dummy: Dummy, radius: float, height: float, text: String) -> void:
	assert_almost_eq(_capsule(dummy).radius, radius, POS_TOL_M, text + " shape radius")
	assert_almost_eq(_capsule(dummy).height, height, POS_TOL_M, text + " shape height")
	assert_almost_eq(_mesh(dummy).radius, radius, POS_TOL_M, text + " mesh radius")
	assert_almost_eq(_mesh(dummy).height, height, POS_TOL_M, text + " mesh height")
	var centre: float = height / 2.0
	var shape_y: float = (dummy.get_node("Collision") as Node3D).position.y
	var mesh_y: float = (dummy.get_node("Mesh") as Node3D).position.y
	assert_almost_eq(shape_y, centre, POS_TOL_M, text + " shape centre")
	assert_almost_eq(mesh_y, centre, POS_TOL_M, text + " mesh centre")


## True if a box the size of the player's hull overlaps the dummy.
func _hull_overlaps(dummy: Dummy) -> bool:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = HULL_SIZE
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(
		Basis.IDENTITY, _player.global_position + Vector3.UP * HULL_CENTRE_Y
	)
	query.exclude = [_player.get_rid()]
	var hits: Array[Dictionary] = _player.get_world_3d().direct_space_state.intersect_shape(query)
	for hit: Dictionary in hits:
		if hit["collider"] == dummy:
			return true
	return false


func test_scene_defaults() -> void:
	var config: DummyConfig = load(CONFIG_PATH) as DummyConfig
	assert_almost_eq(config.width, 0.813, POS_TOL_M)
	assert_almost_eq(config.height, 1.829, POS_TOL_M)
	assert_almost_eq(config.max_health, 100.0, HEALTH_TOL)
	assert_almost_eq(config.respawn_delay, 1.0, HEALTH_TOL)
	assert_eq(config.color, Color(1.0, 0.45, 0.0))
	var dummy: Dummy = _add_dummy(Vector3(0.0, 0.0, -10.0), config)
	await _ticks(1)
	assert_eq(dummy.config, config, "uses the shipped config")
	_assert_size(dummy, 0.4065, 1.829, "default")
	assert_almost_eq(_label(dummy).position.y, 2.129, POS_TOL_M, "label height")
	assert_eq(_label(dummy).billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_almost_eq(dummy.health.health, 100.0, HEALTH_TOL)


func test_rifle_kills_with_4_shots() -> void:
	await _standard_setup()
	await _hold_fire(5)
	var damaged: Array[Array] = _events_named("damaged")
	assert_eq(damaged.size(), 4, "4 hits count")
	var expected_left: Array[float] = [75.0, 50.0, 25.0, 0.0]
	for i: int in mini(damaged.size(), 4):
		assert_almost_eq(damaged[i][3] as float, 25.0, HEALTH_TOL, "damage %d" % i)
		assert_almost_eq(damaged[i][4] as float, expected_left[i], HEALTH_TOL, "left %d" % i)
	var died: Array[Array] = _events_named("died")
	assert_eq(died.size(), 1, "died once")
	if died.size() == 1 and damaged.size() == 4:
		var died_at: int = _events.find(died[0])
		assert_eq(died_at, _events.find(damaged[3]) + 1, "died right after the last damaged")
		assert_eq(died[0][1], damaged[3][1], "same tick")
	assert_false(_dummy.visible, "hidden")
	assert_true((_dummy.get_node("Collision") as CollisionShape3D).disabled, "no collision")
	assert_eq(_wall.hits.size(), 1, "only the 5th shot reaches the wall")


func test_respawns_128_ticks_after_the_kill() -> void:
	await _standard_setup()
	await _hold_fire(4)
	var died: Array[Array] = _events_named("died")
	assert_eq(died.size(), 1)
	await _wait_respawn(TPS + 10)
	var respawned: Array[Array] = _events_named("respawned")
	assert_eq(respawned.size(), 1)
	if died.size() != 1 or respawned.size() != 1:
		return
	assert_eq((respawned[0][1] as int) - (died[0][1] as int), TPS, "ticks to respawn")
	assert_true(_dummy.visible)
	assert_false((_dummy.get_node("Collision") as CollisionShape3D).disabled)
	assert_almost_eq(_dummy.health.health, 100.0, HEALTH_TOL)
	var wall_hits: int = _wall.hits.size()
	_fire_event(true)
	_fire_event(false)
	await _ticks(2)
	assert_eq(_events_named("damaged").size(), 5, "the new click hits the dummy")
	assert_eq(_wall.hits.size(), wall_hits, "not the wall")


func test_held_shot_on_the_respawn_tick_hits_the_dummy() -> void:
	# Review r1, finding 1: Rifle1's 4 shot intervals equal the 128-tick delay,
	# so a held trigger fires on the respawn tick. The player (and its rifle)
	# sits before the dummy in the tree.
	await _standard_setup()
	await _hold_fire(8)
	var died: Array[Array] = _events_named("died")
	var respawned: Array[Array] = _events_named("respawned")
	assert_eq(died.size(), 1, "died once")
	assert_eq(respawned.size(), 1, "respawned once")
	var damaged: Array[Array] = _events_named("damaged")
	assert_eq(damaged.size(), 5, "4 kill hits + the shot on the respawn tick")
	if damaged.size() == 5 and respawned.size() == 1:
		assert_eq(damaged[4][1], respawned[0][1], "hit on the respawn tick")
		assert_almost_eq(damaged[4][4] as float, 75.0, HEALTH_TOL)
	assert_eq(_wall.hits.size(), 3, "only the 3 shots while dead reach the wall")


func test_player_respawn_leaves_dummies_alone() -> void:
	await _standard_setup()
	_dummy.take_hit(50.0)
	(_player.get_node("Respawn") as PlayerRespawn).respawn()
	await _ticks(2)
	assert_almost_eq(_dummy.health.health, 50.0, HEALTH_TOL)


func test_player_cannot_walk_through() -> void:
	_spawn_player()
	_dummy = _add_dummy(Vector3(0.0, 0.0, -3.0), _config())
	assert_true(await _rig.settle(), "player settles")
	var forward: SUCCInput = SUCCInput.new()
	forward.move = Vector2(0.0, -1.0)
	await _rig.play([MovementRig.Step.new(forward, TPS)] as Array[MovementRig.Step])
	var limit: float = -3.0 + 0.4065 + 0.4065 - SOLID_TOL_M
	var min_z: float = INF
	for sample: MovementRig.Sample in _rig.trace:
		min_z = minf(min_z, sample.position.z)
	assert_gte(min_z, limit, "player centre stays behind the dummy")
	var last: Vector3 = _rig.trace[-1].position
	assert_almost_eq(last.x, 0.0, SOLID_TOL_M, "no slide around it")


func test_respawn_pushes_the_player_out() -> void:
	var config: DummyConfig = _config()
	config.respawn_delay = 2.0
	var feet: Vector3 = Vector3(0.0, 0.0, -5.0)
	var dummy: Dummy = _add_dummy(feet, config)
	await _ticks(1)
	dummy.take_hit(100.0)
	assert_false(dummy.health.alive, "killed")
	_spawn_player(feet + Vector3(0.0, 0.01, 0.0))
	assert_true(await _rig.settle(), "player settles")
	# The controller runs each tick after the dummy and the player have moved.
	var records: Array[Array] = []
	var idle: SUCCInput = SUCCInput.new()
	var record: Callable = func(_rig_node: MovementRig, _step_tick: int) -> SUCCInput:
		(
			records
			. append(
				[
					Engine.get_physics_frames(),
					_hull_overlaps(dummy),
					_player.velocity,
					_player.floor_type,
				]
			)
		)
		return idle
	await _rig.play([MovementRig.Step.controlled(record, 2 * TPS + 10)] as Array[MovementRig.Step])
	var respawned: Array[Array] = _events_named("respawned")
	assert_eq(respawned.size(), 1, "respawned")
	if respawned.size() != 1:
		return
	var respawn_tick: int = respawned[0][1] as int
	var after: Array[String] = []
	var checked: int = 0
	for entry: Array in records:
		var tick: int = entry[0] as int
		if tick < respawn_tick:
			continue
		checked += 1
		var ticks_after: int = tick - respawn_tick
		after.append("+%d overlap=%s" % [ticks_after, entry[1]])
		if ticks_after >= PUSH_OUT_TICKS:
			assert_false(entry[1] as bool, "no overlap %d ticks after the respawn" % ticks_after)
		assert_almost_eq(
			(entry[2] as Vector3).length(), 0.0, VELOCITY_TOL, "velocity at +%d" % ticks_after
		)
		assert_eq(entry[3], SUCC.FloorType.FLOOR, "on the floor at +%d" % ticks_after)
	assert_gt(checked, PUSH_OUT_TICKS, "ticks recorded after the respawn")
	gut.p("after respawn: %s" % ", ".join(after.slice(0, 4)))


func test_live_resize() -> void:
	var config: DummyConfig = _config()
	var dummy: Dummy = _add_dummy(Vector3(0.0, 0.0, -10.0), config)
	await _ticks(1)
	config.width = 2.0
	await _ticks(1)
	_assert_size(dummy, 1.0, 2.0, "width 2")
	assert_almost_eq(_label(dummy).position.y, 2.3, POS_TOL_M, "label")
	config.height = 3.0
	await _ticks(1)
	_assert_size(dummy, 1.0, 3.0, "height 3")
	assert_almost_eq(_label(dummy).position.y, 3.3, POS_TOL_M, "label")


func test_max_health_live() -> void:
	var config: DummyConfig = _config()
	var dummy: Dummy = _add_dummy(Vector3(0.0, 0.0, -10.0), config)
	await _ticks(1)
	dummy.take_hit(20.0)
	config.max_health = 50.0
	await _ticks(1)
	assert_almost_eq(dummy.health.health, 50.0, HEALTH_TOL)


func test_delay_live() -> void:
	var config: DummyConfig = _config()
	var dummy: Dummy = _add_dummy(Vector3(0.0, 0.0, -10.0), config)
	await _ticks(1)
	config.respawn_delay = 0.5
	await _ticks(1)
	var kill_tick: int = Engine.get_physics_frames()
	dummy.take_hit(100.0)
	await _wait_respawn(TPS)
	var respawned: Array[Array] = _events_named("respawned")
	assert_eq(respawned.size(), 1)
	if respawned.size() == 1:
		assert_eq((respawned[0][1] as int) - kill_tick, 64)


func test_unchanged_config_leaves_the_shape_alone() -> void:
	# Review r1, finding 2: idle ticks must not rewrite the capsule.
	var dummy: Dummy = _add_dummy(Vector3(0.0, 0.0, -10.0), _config())
	await _ticks(2)
	var changes: Array[int] = [0]
	var count: Callable = func() -> void: changes[0] += 1
	_capsule(dummy).changed.connect(count)
	_mesh(dummy).changed.connect(count)
	await _ticks(16)
	assert_eq(changes[0], 0, "no shape or mesh changes in 16 idle ticks")


func test_instances_dont_share() -> void:
	var wide: DummyConfig = _config()
	wide.width = 2.0
	var a: Dummy = _add_dummy(Vector3(0.0, 0.0, -10.0), _config())
	var b: Dummy = _add_dummy(Vector3(5.0, 0.0, -10.0), wide)
	await _ticks(1)
	_assert_size(a, 0.4065, 1.829, "default dummy")
	_assert_size(b, 1.0, 2.0, "wide dummy")


func test_label_with_panel_visible() -> void:
	await _standard_setup()
	_set_panel(true)
	await _ticks(1)
	assert_true(_label(_dummy).visible)
	assert_eq(_label(_dummy).text, "100")
	_dummy.take_hit(25.0)
	await _ticks(1)
	assert_eq(_label(_dummy).text, "75")
	_dummy.take_hit(74.6)
	await _ticks(1)
	assert_almost_eq(_dummy.health.health, 0.4, HEALTH_TOL)
	assert_eq(_label(_dummy).text, "1")


func test_label_with_panel_hidden() -> void:
	await _standard_setup()
	_set_panel(false)
	await _ticks(1)
	assert_false(_label(_dummy).visible)


func test_label_without_overlay() -> void:
	var dummy: Dummy = _add_dummy(Vector3(0.0, 0.0, -10.0), _config())
	await _ticks(1)
	assert_null(get_tree().get_first_node_in_group(DebugOverlay.GROUP), "no overlay")
	assert_false(_label(dummy).visible)
