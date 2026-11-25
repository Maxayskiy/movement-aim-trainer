extends GutTest

const FRAMES_PER_WINDOW: int = 25
const TICKS_PER_WINDOW: int = 32

var _sampler: PerfSampler


func before_each() -> void:
	_sampler = PerfSampler.new()
	_sampler.interval = 0.25


## Feeds one window of 25 frames after `start_usec`, with 32 ticks spread between them.
## Returns the result of every add_frame call.
func _feed_window(start_usec: int, step_usec: int, delta: float) -> Array[bool]:
	var results: Array[bool] = []
	var ticks_added: int = 0
	for i: int in range(1, FRAMES_PER_WINDOW + 1):
		var ticks_due: int = TICKS_PER_WINDOW * i / FRAMES_PER_WINDOW
		while ticks_added < ticks_due:
			_sampler.add_tick()
			ticks_added += 1
		results.append(_sampler.add_frame(delta, start_usec + step_usec * i))
	return results


func test_first_frame_only_starts_window() -> void:
	assert_false(_sampler.add_frame(0.01, 0))
	assert_false(_sampler.has_sample)


func test_window_gives_fps_frame_time_and_ticks() -> void:
	_sampler.add_frame(0.01, 0)
	var results: Array[bool] = _feed_window(0, 10_000, 0.01)
	for i: int in range(FRAMES_PER_WINDOW - 1):
		assert_false(results[i], "frame %d does not close the window" % i)
	assert_true(results[FRAMES_PER_WINDOW - 1], "frame at 250 000 us closes the window")
	assert_true(_sampler.has_sample)
	assert_almost_eq(_sampler.fps, 100.0, 0.01)
	assert_almost_eq(_sampler.frame_ms, 10.0, 0.01)
	assert_almost_eq(_sampler.ticks_per_second, 128.0, 0.01)


func test_next_window_starts_from_zero() -> void:
	_sampler.add_frame(0.01, 0)
	_feed_window(0, 10_000, 0.01)
	# 25 frames at 20 000 us span 0.5 s, so this window needs a 0.5 s interval.
	_sampler.interval = 0.5
	var results: Array[bool] = _feed_window(250_000, 20_000, 0.02)
	assert_true(results[FRAMES_PER_WINDOW - 1])
	assert_almost_eq(_sampler.fps, 50.0, 0.01)
	assert_almost_eq(_sampler.frame_ms, 20.0, 0.01)
	assert_almost_eq(_sampler.ticks_per_second, 64.0, 0.01)
