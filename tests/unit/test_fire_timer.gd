extends GutTest
## FireTimer cadence, ticks counted by hand at 128 ticks per second.

const TPS: int = 128

var _results: Dictionary[int, FireTimer.Result] = {}


func _timer(sps: float, full_auto: bool = true) -> FireTimer:
	var timer: FireTimer = FireTimer.new()
	timer.ticks_per_second = TPS
	timer.shots_per_second = sps
	timer.full_auto = full_auto
	return timer


## Runs ticks from..to-1. pressed_at: ticks with a latched click.
## held(t) tells whether the trigger is down on tick t. Returns shot ticks.
func _run(
	timer: FireTimer, from: int, to: int, pressed_at: Array[int], held: Callable
) -> Array[int]:
	var shots: Array[int] = []
	for t: int in range(from, to):
		var result: FireTimer.Result = timer.tick(t, pressed_at.has(t), held.call(t) as bool)
		_results[t] = result
		if result == FireTimer.Result.CLICK_SHOT or result == FireTimer.Result.HELD_SHOT:
			shots.append(t)
	return shots


func before_each() -> void:
	_results.clear()


func test_4_sps_held_fires_every_32_ticks() -> void:
	var timer: FireTimer = _timer(4.0)
	var shots: Array[int] = _run(timer, 0, 128, [0], func(_t: int) -> bool: return true)
	assert_eq(shots, [0, 32, 64, 96] as Array[int])
	assert_eq(_results[0], FireTimer.Result.CLICK_SHOT)
	for t: int in [32, 64, 96]:
		assert_eq(_results[t], FireTimer.Result.HELD_SHOT, "tick %d" % t)


func test_10_sps_carries_the_fraction() -> void:
	var timer: FireTimer = _timer(10.0)
	var shots: Array[int] = _run(timer, 0, 128, [0], func(_t: int) -> bool: return true)
	assert_eq(shots, [0, 13, 26, 39, 52, 64, 77, 90, 103, 116] as Array[int])


func test_10_sps_cadence_from_a_nonzero_start() -> void:
	# Due ticks 100 + 12.8 n: 112.8, 125.6, 138.4, 151.2, 164.0, 176.8.
	var timer: FireTimer = _timer(10.0)
	var shots: Array[int] = _run(timer, 100, 180, [100], func(_t: int) -> bool: return true)
	assert_eq(shots, [100, 113, 126, 139, 152, 164, 177] as Array[int])


func test_10_sps_fires_100_shots_in_1280_ticks() -> void:
	var timer: FireTimer = _timer(10.0)
	var shots: Array[int] = _run(timer, 0, 1280, [0], func(_t: int) -> bool: return true)
	assert_eq(shots.size(), 100)


func test_idle_restart_starts_a_new_schedule() -> void:
	var timer: FireTimer = _timer(4.0)
	var shots: Array[int] = _run(
		timer, 0, 114, [0, 50], func(t: int) -> bool: return t == 0 or t >= 50
	)
	assert_eq(shots, [0, 50, 82] as Array[int])


func test_long_idle_has_no_catch_up_burst() -> void:
	var timer: FireTimer = _timer(10.0)
	var shots: Array[int] = _run(
		timer, 0, 1030, [0, 1000], func(t: int) -> bool: return t == 0 or t >= 1000
	)
	assert_eq(shots, [0, 1000, 1013, 1026] as Array[int])


func test_tap_only_click_in_cooldown_is_dropped() -> void:
	var timer: FireTimer = _timer(10.0, false)
	assert_eq(timer.tick(0, true, true), FireTimer.Result.CLICK_SHOT)
	assert_eq(timer.tick(5, true, true), FireTimer.Result.CLICK_DROPPED)
	assert_eq(timer.tick(13, true, true), FireTimer.Result.CLICK_SHOT)


func test_tap_only_held_fires_once() -> void:
	var timer: FireTimer = _timer(4.0, false)
	var shots: Array[int] = _run(timer, 0, 128, [0], func(_t: int) -> bool: return true)
	assert_eq(shots, [0] as Array[int])


func test_dropped_click_then_held_shots_follow_the_schedule() -> void:
	var timer: FireTimer = _timer(4.0)
	var shots: Array[int] = _run(
		timer, 0, 96, [0, 10], func(t: int) -> bool: return t == 0 or t >= 10
	)
	assert_eq(_results[10], FireTimer.Result.CLICK_DROPPED)
	assert_eq(shots, [0, 32, 64] as Array[int])
	assert_eq(_results[32], FireTimer.Result.HELD_SHOT)
	assert_eq(_results[64], FireTimer.Result.HELD_SHOT)


func test_rate_above_tick_rate_is_clamped_with_warning() -> void:
	var timer: FireTimer = _timer(200.0)
	assert_push_warning_count(1)
	assert_almost_eq(timer.shots_per_second, 128.0, 0.001)
	var shots: Array[int] = _run(timer, 0, 10, [0], func(_t: int) -> bool: return true)
	assert_eq(shots.size(), 10)


func test_rate_at_tick_rate_fires_every_tick() -> void:
	var timer: FireTimer = _timer(128.0)
	assert_push_warning_count(0)
	var shots: Array[int] = _run(timer, 0, 10, [0], func(_t: int) -> bool: return true)
	assert_eq(shots, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as Array[int])


func test_rate_below_one_is_clamped_with_warning() -> void:
	var timer: FireTimer = _timer(0.0)
	assert_push_warning_count(1)
	assert_almost_eq(timer.shots_per_second, 1.0, 0.001)
