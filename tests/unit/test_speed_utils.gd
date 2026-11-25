extends GutTest


func test_horizontal_speed_ignores_vertical_velocity() -> void:
	var v: Vector3 = Vector3(3.0, 100.0, 4.0)
	assert_almost_eq(SpeedUtils.horizontal_speed(v), 5.0, 0.0001)


func test_horizontal_speed_is_zero_when_standing_still() -> void:
	assert_eq(SpeedUtils.horizontal_speed(Vector3.ZERO), 0.0)


func test_horizontal_speed_of_pure_fall_is_zero() -> void:
	assert_eq(SpeedUtils.horizontal_speed(Vector3(0.0, -20.0, 0.0)), 0.0)


func test_to_ups_of_max_run_speed_is_400() -> void:
	assert_eq(SpeedUtils.to_ups(10.16), 400)


func test_to_ups_of_zero_is_zero() -> void:
	assert_eq(SpeedUtils.to_ups(0.0), 0)


func test_to_ups_keeps_sign() -> void:
	assert_eq(SpeedUtils.to_ups(-5.0), -197)
