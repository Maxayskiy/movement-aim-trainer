class_name FireTimer
extends RefCounted
## Fire cadence on physics ticks. Pure logic: the caller passes the tick number
## and the trigger state, and gets back what happens on that tick.

enum Result { NONE, CLICK_SHOT, HELD_SHOT, CLICK_DROPPED }

const MIN_SHOTS_PER_SECOND: float = 1.0
## Float rounding slack when comparing a tick with a due time.
const DUE_EPSILON: float = 1e-6

var ticks_per_second: int = 128
## Clamped to 1..ticks_per_second with a warning: at most one shot per tick.
var shots_per_second: float = 4.0:
	set(value):
		var clamped: float = clampf(value, MIN_SHOTS_PER_SECOND, float(ticks_per_second))
		if clamped != value:
			push_warning("FireTimer: shots_per_second %s clamped to %s." % [value, clamped])
		shots_per_second = clamped
var full_auto: bool = true

## Tick the current schedule started on, and shots since then. Due times are
## start + shots x interval, so rounding doesn't build up over a long hold.
var _schedule_start: float = 0.0
var _schedule_shots: int = 0
var _next_due: float = -INF


## Interval between shots in ticks (a float: the fraction carries over).
func interval() -> float:
	return float(ticks_per_second) / shots_per_second


## pressed: a click was latched since the last tick. held: the trigger is down.
func tick(t: int, pressed: bool, held: bool) -> Result:
	var now: float = float(t)
	var ready: bool = now >= _next_due - DUE_EPSILON
	if pressed:
		if not ready:
			return Result.CLICK_DROPPED
		_start_schedule(now)
		return Result.CLICK_SHOT
	if held and full_auto and ready:
		_schedule_shots += 1
		_next_due = _schedule_start + float(_schedule_shots) * interval()
		# After a long idle the schedule would lie in the past: no catch-up burst.
		if _next_due <= now + DUE_EPSILON:
			_start_schedule(now)
		return Result.HELD_SHOT
	return Result.NONE


## Forgets the schedule: the next shot may fire at once.
func reset() -> void:
	_next_due = -INF


## A shot on tick now starts a new schedule: next due = now + interval.
func _start_schedule(now: float) -> void:
	_schedule_start = now
	_schedule_shots = 1
	_next_due = now + interval()
