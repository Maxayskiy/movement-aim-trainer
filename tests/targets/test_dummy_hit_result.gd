extends GutTest
## Dummy.take_hit results: behaviour 1 and 11 of workflow/plans/018-hit-feedback.md.

const DUMMY_SCENE: PackedScene = preload("res://src/targets/dummy.tscn")
const CONFIG_PATH: String = "res://src/targets/dummy_config.tres"

var _dummy: Dummy


func before_each() -> void:
	var config: DummyConfig = (load(CONFIG_PATH) as DummyConfig).duplicate() as DummyConfig
	config.max_health = 100.0
	_dummy = DUMMY_SCENE.instantiate() as Dummy
	_dummy.config = config
	add_child_autofree(_dummy)


func test_damaged_then_killed_then_ignored() -> void:
	for i: int in 3:
		assert_eq(_dummy.take_hit(25.0), TargetHealth.Result.DAMAGED, "hit %d" % (i + 1))
	assert_eq(_dummy.take_hit(25.0), TargetHealth.Result.KILLED, "hit 4")
	assert_eq(_dummy.take_hit(25.0), TargetHealth.Result.IGNORED, "hit 5 (dead)")


func test_zero_damage_is_ignored() -> void:
	assert_eq(_dummy.take_hit(0.0), TargetHealth.Result.IGNORED)
