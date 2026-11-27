extends GutTest
## Rifle.target_hit: behaviour 1 and 11 of workflow/plans/018-hit-feedback.md.
## The player stands at the origin facing -Z.

const DUMMY_SCENE: PackedScene = preload("res://src/targets/dummy.tscn")
const DUMMY_CONFIG_PATH: String = "res://src/targets/dummy_config.tres"
const SHOT_GAP_TICKS: int = 32
const BOX_SIZE: Vector3 = Vector3(10.0, 10.0, 1.0)
const WALL_Z: float = -20.0


## A box whose take_hit returns nothing.
class VoidTarget:
	extends StaticBody3D

	var calls: int = 0

	func take_hit(_damage: float) -> void:
		calls += 1


var _rig: MovementRig
var _player: SUCC
var _rifle: Rifle
## Signal log: [name, tick, collider, killed (target_hit only)].
var _events: Array[Array] = []


func before_each() -> void:
	_events.clear()
	_rig = MovementRig.new()
	add_child_autofree(_rig)
	_player = _rig.spawn(MovementRig.test_config())
	_rifle = _player.get_node("Rifle") as Rifle
	_rifle.require_captured_mouse = false
	_rifle.config = _rifle.config.duplicate() as RifleConfig
	_rifle.shot_fired.connect(_on_shot_fired)
	_rifle.target_hit.connect(_on_target_hit)


func after_each() -> void:
	_fire_event(false)


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_shot_fired(_o: Vector3, _d: Vector3, _h: Vector3, collider: Object) -> void:
	_events.append(["shot_fired", Engine.get_physics_frames(), collider])


func _on_target_hit(collider: Object, killed: bool) -> void:
	_events.append(["target_hit", Engine.get_physics_frames(), collider, killed])


func _named(event_name: String) -> Array[Array]:
	var found: Array[Array] = []
	for event: Array in _events:
		if event[0] == event_name:
			found.append(event)
	return found


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


func _click() -> void:
	_fire_event(true)
	_fire_event(false)
	await _ticks(2)


func _hold_fire(shots: int) -> void:
	_fire_event(true)
	await _ticks((shots - 1) * SHOT_GAP_TICKS + 2)
	_fire_event(false)


## Adds target as a BOX_SIZE box with its near face at near_face_z.
func _box_at(target: StaticBody3D, near_face_z: float) -> StaticBody3D:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = BOX_SIZE
	shape.shape = box
	target.add_child(shape)
	target.position = Vector3(0.0, 2.0, near_face_z - BOX_SIZE.z / 2.0)
	_rig.add_child(target)
	return target


func _hit_target(result: TargetHealth.Result) -> HitTarget:
	var target: HitTarget = HitTarget.make(BOX_SIZE, Vector3(0.0, 2.0, WALL_Z - BOX_SIZE.z / 2.0))
	target.result = result
	_rig.add_child(target)
	return target


func test_dummy_kill_reports_3_hits_then_a_kill() -> void:
	var dummy: Dummy = DUMMY_SCENE.instantiate() as Dummy
	dummy.config = (load(DUMMY_CONFIG_PATH) as DummyConfig).duplicate() as DummyConfig
	dummy.config.max_health = 100.0
	dummy.position = Vector3(0.0, 0.0, -10.0)
	_rig.add_child(dummy)
	await _settle()
	await _hold_fire(4)
	var hits: Array[Array] = _named("target_hit")
	assert_eq(hits.size(), 4, "4 target_hit")
	if hits.size() != 4:
		return
	var expected_killed: Array[bool] = [false, false, false, true]
	for i: int in 4:
		assert_eq(hits[i][2], dummy, "collider %d" % i)
		assert_eq(hits[i][3], expected_killed[i], "killed %d" % i)
	# Every target_hit comes right after its shot's shot_fired, on the same tick.
	assert_eq(_events.size(), 8, "4 shot_fired + 4 target_hit")
	if _events.size() != 8:
		return
	for i: int in range(0, _events.size(), 2):
		assert_eq(_events[i][0], "shot_fired", "event %d" % i)
		assert_eq(_events[i + 1][0], "target_hit", "event %d" % (i + 1))
		assert_eq(_events[i + 1][1], _events[i][1], "same tick %d" % i)


func test_plain_wall_gives_no_target_hit() -> void:
	var wall: StaticBody3D = _box_at(StaticBody3D.new(), WALL_Z)
	await _settle()
	await _click()
	var shots: Array[Array] = _named("shot_fired")
	assert_eq(shots.size(), 1)
	if shots.size() == 1:
		assert_eq(shots[0][2], wall)
	assert_eq(_named("target_hit").size(), 0)


func test_miss_gives_no_target_hit() -> void:
	await _settle()
	await _click()
	assert_eq(_named("shot_fired").size(), 1)
	assert_eq(_named("target_hit").size(), 0)


func test_ignored_gives_no_target_hit() -> void:
	var target: HitTarget = _hit_target(TargetHealth.Result.IGNORED)
	await _settle()
	await _click()
	assert_eq(target.hits.size(), 1, "damage recorded")
	assert_eq(_named("target_hit").size(), 0)


func test_default_hit_target_reports_a_hit() -> void:
	var target: HitTarget = HitTarget.make(BOX_SIZE, Vector3(0.0, 2.0, WALL_Z - BOX_SIZE.z / 2.0))
	_rig.add_child(target)
	await _settle()
	await _click()
	var hits: Array[Array] = _named("target_hit")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq(hits[0][2], target)
		assert_false(hits[0][3] as bool)


func test_killed_hit_target_reports_a_kill() -> void:
	var target: HitTarget = _hit_target(TargetHealth.Result.KILLED)
	await _settle()
	await _click()
	var hits: Array[Array] = _named("target_hit")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq(hits[0][2], target)
		assert_true(hits[0][3] as bool)


func test_non_int_return_gives_no_target_hit() -> void:
	var target: VoidTarget = _box_at(VoidTarget.new(), WALL_Z) as VoidTarget
	await _settle()
	await _click()
	assert_eq(target.calls, 1, "take_hit called")
	assert_eq(_named("shot_fired").size(), 1)
	assert_eq(_named("target_hit").size(), 0)
