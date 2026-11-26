class_name TargetHealth
extends RefCounted
## Health, damage, death and respawn of one target. Pure logic: the caller
## passes the physics tick number. Ticks are exact, so tests need no scene.

enum Result { IGNORED, DAMAGED, KILLED }

const MIN_MAX_HEALTH: float = 1.0

var ticks_per_second: int = 128
## Clamped to at least 1 with a warning. While alive, health is capped to it
## at once and never raised.
var max_health: float = 100.0:
	set(value):
		var clamped: float = maxf(value, MIN_MAX_HEALTH)
		if clamped != value:
			push_warning("TargetHealth: max_health %s clamped to %s." % [value, clamped])
		max_health = clamped
		if _alive:
			_health = minf(_health, max_health)
## Seconds from death to respawn. Clamped to at least 0. Fixed at the moment of death.
var respawn_delay: float = 1.0:
	set(value):
		respawn_delay = maxf(value, 0.0)

var health: float:
	get:
		return _health
var alive: bool:
	get:
		return _alive
## The damage that counted in the last take (overkill removed).
var last_damage: float:
	get:
		return _last_damage

var _health: float = 100.0
var _alive: bool = true
var _last_damage: float = 0.0
var _respawn_tick: int = 0


## Alive with full health.
func reset() -> void:
	_alive = true
	_health = max_health


## A hit of damage on tick t.
func take(damage: float, t: int) -> Result:
	if not _alive or damage <= 0.0:
		return Result.IGNORED
	_last_damage = minf(damage, _health)
	_health -= _last_damage
	if _health > 0.0:
		return Result.DAMAGED
	_health = 0.0
	_alive = false
	_respawn_tick = t + maxi(1, roundi(respawn_delay * float(ticks_per_second)))
	return Result.KILLED


## True exactly once: on the first tick at or after the respawn tick.
func tick(t: int) -> bool:
	if _alive or t < _respawn_tick:
		return false
	reset()
	return true
