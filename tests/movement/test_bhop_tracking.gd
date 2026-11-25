extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")

var _overlay: DebugOverlay


func before_each() -> void:
	var floor_body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(20.0, 1.0, 20.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_child_autofree(floor_body)

	var player: SUCC = PLAYER_SCENE.instantiate() as SUCC
	player.position = Vector3(0.0, 1.0, 0.0)
	add_child_autofree(player)
	_overlay = player.get_node("DebugOverlay") as DebugOverlay


func after_each() -> void:
	Input.action_release("jump")


func after_all() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_held_jump_chains_perfect_hops() -> void:
	Input.action_press("jump")
	await wait_seconds(2.0)
	assert_gte(_overlay.tracker.hops, 2)
	assert_eq(_overlay.tracker.last_ground_ticks, 0)
	assert_true(_overlay.tracker.has_takeoff)
