extends GutTest
## HitMarkerFade: behaviour 3, 4 and 10 of workflow/plans/018-hit-feedback.md.

const ALPHA_TOL: float = 0.001

var _fade: HitMarkerFade


func before_each() -> void:
	_fade = HitMarkerFade.new()


func test_alpha_is_0_before_any_show() -> void:
	assert_almost_eq(_fade.alpha(0.0), 0.0, ALPHA_TOL)
	assert_almost_eq(_fade.alpha(5.0), 0.0, ALPHA_TOL)


func test_linear_fade_over_default_duration() -> void:
	assert_almost_eq(_fade.duration, 0.25, ALPHA_TOL)
	_fade.show(false, 10.0)
	assert_almost_eq(_fade.alpha(10.0), 1.0, ALPHA_TOL)
	assert_almost_eq(_fade.alpha(10.125), 0.5, ALPHA_TOL)
	assert_almost_eq(_fade.alpha(10.25), 0.0, ALPHA_TOL)
	assert_almost_eq(_fade.alpha(11.0), 0.0, ALPHA_TOL)
	assert_false(_fade.killed)


func test_new_show_restarts_in_the_newest_colour() -> void:
	_fade.show(false, 10.0)
	_fade.show(true, 10.2)
	assert_almost_eq(_fade.alpha(10.2), 1.0, ALPHA_TOL)
	assert_almost_eq(_fade.alpha(10.325), 0.5, ALPHA_TOL)
	assert_true(_fade.killed)
	_fade.show(false, 10.3)
	assert_false(_fade.killed)
	assert_almost_eq(_fade.alpha(10.3), 1.0, ALPHA_TOL)


func test_duration_1_and_clamp() -> void:
	_fade.duration = 1.0
	_fade.show(false, 2.0)
	assert_almost_eq(_fade.alpha(2.25), 0.75, ALPHA_TOL)
	_fade.duration = 0.0
	assert_almost_eq(_fade.duration, 0.01, ALPHA_TOL)


func test_clear_hides_at_once() -> void:
	_fade.show(false, 10.0)
	_fade.clear()
	assert_almost_eq(_fade.alpha(10.0), 0.0, ALPHA_TOL)
