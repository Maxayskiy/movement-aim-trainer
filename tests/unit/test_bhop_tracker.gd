extends GutTest

var _tracker: BhopTracker


func before_each() -> void:
	_tracker = BhopTracker.new()


func _assert_start_state() -> void:
	assert_eq(_tracker.hops, 0)
	assert_false(_tracker.has_takeoff)
	assert_false(_tracker.has_gain)
	assert_eq(_tracker.last_ground_ticks, -1)


func test_new_tracker_is_empty() -> void:
	_assert_start_state()


func test_first_jump_without_landing() -> void:
	_tracker.on_jumped(50, 8.0)
	assert_eq(_tracker.hops, 1)
	assert_true(_tracker.has_takeoff)
	assert_almost_eq(_tracker.last_takeoff_speed, 8.0, 0.0001)
	assert_false(_tracker.has_gain)
	assert_eq(_tracker.last_ground_ticks, -1)


func test_perfect_hop_extends_chain() -> void:
	_tracker.on_jumped(50, 8.0)
	_tracker.on_landed(100)
	_tracker.on_jumped(101, 9.0)
	assert_eq(_tracker.hops, 2)
	assert_eq(_tracker.last_ground_ticks, 0)
	assert_true(_tracker.has_gain)
	assert_almost_eq(_tracker.last_gain, 1.0, 0.0001)
	assert_almost_eq(_tracker.last_takeoff_speed, 9.0, 0.0001)


func test_three_perfect_hops() -> void:
	_tracker.on_jumped(50, 8.0)
	_tracker.on_landed(100)
	_tracker.on_jumped(101, 9.0)
	_tracker.on_landed(150)
	_tracker.on_jumped(151, 9.5)
	assert_eq(_tracker.hops, 3)


func test_late_hop_breaks_chain_with_default_limit() -> void:
	_tracker.on_jumped(50, 8.0)
	_tracker.on_landed(100)
	_tracker.on_jumped(102, 9.0)
	assert_eq(_tracker.hops, 1)
	assert_eq(_tracker.last_ground_ticks, 1)
	assert_false(_tracker.has_gain)


func test_late_hop_counts_with_higher_limit() -> void:
	_tracker.max_chain_ground_ticks = 1
	_tracker.on_jumped(50, 8.0)
	_tracker.on_landed(100)
	_tracker.on_jumped(102, 9.0)
	assert_eq(_tracker.hops, 2)


func test_two_landings_break_chain() -> void:
	_tracker.on_jumped(50, 8.0)
	_tracker.on_landed(100)
	_tracker.on_landed(140)
	_tracker.on_jumped(141, 9.0)
	assert_eq(_tracker.hops, 1)
	assert_false(_tracker.has_gain)


func test_reset_returns_to_start_state() -> void:
	_tracker.on_jumped(50, 8.0)
	_tracker.on_landed(100)
	_tracker.on_jumped(101, 9.0)
	_tracker.reset()
	_assert_start_state()
