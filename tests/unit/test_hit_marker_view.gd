extends GutTest
## HitMarkerView.segments: behaviour 2 of workflow/plans/018-hit-feedback.md.

const PX_TOL: float = 0.01
const CENTER: Vector2 = Vector2(960.0, 540.0)
## Order: up-left, up-right, down-right, down-left.
const SIGNS: Array[Vector2] = [
	Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)
]


func _assert_point(got: Vector2, expected: Vector2, text: String) -> void:
	assert_almost_eq(got.x, expected.x, PX_TOL, text + " x")
	assert_almost_eq(got.y, expected.y, PX_TOL, text + " y")


func test_default_x() -> void:
	var points: PackedVector2Array = HitMarkerView.segments(CENTER, 8.0, 8.0)
	assert_eq(points.size(), 8)
	if points.size() != 8:
		return
	_assert_point(points[0], Vector2(954.343, 534.343), "up-left start")
	_assert_point(points[1], Vector2(948.686, 528.686), "up-left end")
	for i: int in 4:
		var start: Vector2 = CENTER + SIGNS[i] * Vector2(5.657, 5.657)
		var end: Vector2 = CENTER + SIGNS[i] * Vector2(11.314, 11.314)
		_assert_point(points[2 * i], start, "start %d" % i)
		_assert_point(points[2 * i + 1], end, "end %d" % i)
		assert_almost_eq(points[2 * i].distance_to(points[2 * i + 1]), 8.0, PX_TOL, "length")
		assert_almost_eq(points[2 * i].distance_to(CENTER), 8.0, PX_TOL, "gap")


func test_zero_gap() -> void:
	var points: PackedVector2Array = HitMarkerView.segments(CENTER, 0.0, 20.0)
	assert_eq(points.size(), 8)
	for i: int in range(0, points.size(), 2):
		_assert_point(points[i], CENTER, "start %d" % i)
		assert_almost_eq(points[i].distance_to(points[i + 1]), 20.0, PX_TOL, "length")
