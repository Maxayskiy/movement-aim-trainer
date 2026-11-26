extends GutTest
## TargetHealth: behaviour 4, 6 and 8 of workflow/plans/017-static-target-dummy.md.
## Ticks counted by hand at 128 ticks per second.

const TPS: int = 128
const HEALTH_TOL: float = 0.001


func _health(delay: float = 1.0) -> TargetHealth:
	var health: TargetHealth = TargetHealth.new()
	health.ticks_per_second = TPS
	health.respawn_delay = delay
	health.reset()
	return health


## Kills a target at full health on tick t.
func _kill(health: TargetHealth, t: int) -> void:
	assert_eq(health.take(health.health, t), TargetHealth.Result.KILLED, "killed at %d" % t)


## The first tick in from..to-1 where tick() is true, or -1.
func _respawn_tick(health: TargetHealth, from: int, to: int) -> int:
	for t: int in range(from, to):
		if health.tick(t):
			return t
	return -1


func test_reset_is_alive_with_full_health() -> void:
	var health: TargetHealth = _health()
	assert_true(health.alive)
	assert_almost_eq(health.health, 100.0, HEALTH_TOL)


func test_four_hits_of_25_kill() -> void:
	var health: TargetHealth = _health()
	for expected: float in [75.0, 50.0, 25.0]:
		assert_eq(health.take(25.0, 1), TargetHealth.Result.DAMAGED)
		assert_almost_eq(health.health, expected, HEALTH_TOL)
		assert_almost_eq(health.last_damage, 25.0, HEALTH_TOL)
	assert_eq(health.take(25.0, 1), TargetHealth.Result.KILLED)
	assert_almost_eq(health.health, 0.0, HEALTH_TOL)
	assert_false(health.alive)
	assert_almost_eq(health.last_damage, 25.0, HEALTH_TOL)


func test_overkill_counts_only_the_health_left() -> void:
	var health: TargetHealth = _health()
	health.take(70.0, 1)
	assert_almost_eq(health.health, 30.0, HEALTH_TOL)
	assert_eq(health.take(50.0, 2), TargetHealth.Result.KILLED)
	assert_almost_eq(health.last_damage, 30.0, HEALTH_TOL)


func test_float_damage_is_not_rounded() -> void:
	var health: TargetHealth = _health()
	for i: int in 3:
		assert_eq(health.take(33.333, 1), TargetHealth.Result.DAMAGED)
	assert_almost_eq(health.health, 0.001, HEALTH_TOL / 10.0)
	assert_true(health.alive)


func test_zero_and_negative_damage_are_ignored() -> void:
	var health: TargetHealth = _health()
	health.take(10.0, 1)
	for damage: float in [0.0, -5.0]:
		assert_eq(health.take(damage, 2), TargetHealth.Result.IGNORED)
		assert_almost_eq(health.health, 90.0, HEALTH_TOL)
		assert_almost_eq(health.last_damage, 10.0, HEALTH_TOL)
		assert_true(health.alive)


func test_hit_while_dead_is_ignored() -> void:
	var health: TargetHealth = _health()
	_kill(health, 1)
	assert_eq(health.take(25.0, 2), TargetHealth.Result.IGNORED)
	assert_almost_eq(health.health, 0.0, HEALTH_TOL)
	assert_almost_eq(health.last_damage, 100.0, HEALTH_TOL)
	assert_false(health.alive)


func test_respawns_128_ticks_after_death() -> void:
	var health: TargetHealth = _health(1.0)
	_kill(health, 1000)
	assert_false(health.tick(1127))
	assert_false(health.alive)
	assert_true(health.tick(1128))
	assert_true(health.alive)
	assert_almost_eq(health.health, 100.0, HEALTH_TOL)
	assert_false(health.tick(1129))


func test_zero_delay_respawns_on_the_next_tick() -> void:
	var health: TargetHealth = _health(0.0)
	_kill(health, 10)
	assert_false(health.tick(10))
	assert_true(health.tick(11))


func test_half_second_delay_is_64_ticks() -> void:
	var health: TargetHealth = _health(0.5)
	_kill(health, 200)
	assert_eq(_respawn_tick(health, 200, 400), 264)


func test_delay_change_applies_from_the_next_death() -> void:
	var health: TargetHealth = _health(1.0)
	_kill(health, 100)
	health.respawn_delay = 3.0
	assert_eq(_respawn_tick(health, 100, 1000), 228)
	_kill(health, 300)
	assert_eq(_respawn_tick(health, 300, 1000), 684)


func test_max_health_change_caps_and_never_raises() -> void:
	var health: TargetHealth = _health()
	health.take(20.0, 1)
	health.max_health = 50.0
	assert_almost_eq(health.health, 50.0, HEALTH_TOL)
	health.max_health = 150.0
	assert_almost_eq(health.health, 50.0, HEALTH_TOL)
	_kill(health, 10)
	assert_true(health.tick(10 + TPS))
	assert_almost_eq(health.health, 150.0, HEALTH_TOL)


func test_max_health_under_1_is_clamped_with_a_warning() -> void:
	var health: TargetHealth = _health()
	health.max_health = 0.0
	assert_almost_eq(health.max_health, 1.0, HEALTH_TOL)
	assert_push_warning("max_health")


func test_negative_delay_is_clamped_to_0() -> void:
	var health: TargetHealth = _health()
	health.respawn_delay = -1.0
	assert_almost_eq(health.respawn_delay, 0.0, HEALTH_TOL)
