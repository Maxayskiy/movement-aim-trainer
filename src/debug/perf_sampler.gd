class_name PerfSampler
extends RefCounted
## Averages frame and physics tick rates over fixed windows. The caller passes times in.

## Window length in seconds.
var interval: float = 0.25

var has_sample: bool = false
var fps: float = 0.0
var frame_ms: float = 0.0
var ticks_per_second: float = 0.0

var _started: bool = false
var _window_start_usec: int = 0
var _frames: int = 0
var _delta_sum: float = 0.0
var _ticks: int = 0


## Counts a rendered frame. Returns true when a window closed and the results changed.
func add_frame(delta: float, now_usec: int) -> bool:
	if not _started:
		_started = true
		_window_start_usec = now_usec
		return false
	_frames += 1
	_delta_sum += delta
	var elapsed_usec: int = now_usec - _window_start_usec
	if elapsed_usec < roundi(interval * 1_000_000.0):
		return false
	var elapsed: float = elapsed_usec / 1_000_000.0
	fps = _frames / elapsed
	frame_ms = _delta_sum / _frames * 1000.0
	ticks_per_second = _ticks / elapsed
	has_sample = true
	_window_start_usec = now_usec
	_frames = 0
	_delta_sum = 0.0
	_ticks = 0
	return true


func add_tick() -> void:
	_ticks += 1
