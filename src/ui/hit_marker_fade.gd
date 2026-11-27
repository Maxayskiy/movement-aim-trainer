class_name HitMarkerFade
extends RefCounted
## Fade state of the hit marker. Pure logic: the caller passes times in seconds.
## alpha = 1 - elapsed / duration, 0 once elapsed >= duration.

const MIN_DURATION: float = 0.01

## Seconds of the full fade. Clamped to at least MIN_DURATION.
var duration: float = 0.25:
	set(value):
		duration = maxf(value, MIN_DURATION)
## Whether the X shows the kill colour.
var killed: bool:
	get:
		return _killed

var _killed: bool = false
var _showing: bool = false
var _shown_at: float = 0.0


## Restarts at full strength.
func show(was_kill: bool, now: float) -> void:
	_killed = was_kill
	_shown_at = now
	_showing = true


func alpha(now: float) -> float:
	if not _showing:
		return 0.0
	return clampf(1.0 - (now - _shown_at) / duration, 0.0, 1.0)


func clear() -> void:
	_showing = false
