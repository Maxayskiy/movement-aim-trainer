extends GutTest
## Behaviour 3-10 of workflow/plans/014-movement-course.md, by ray cast on the
## loaded course.

const COURSE_PATH: String = "res://levels/movement_course/movement_course.tscn"
const POS_TOL: float = 0.001
const ANGLE_TOL: float = 0.1
const RAY_TOP: float = 50.0
const RAY_LENGTH: float = 60.0
const EDGE_STEP: float = 0.01

const SLOPE_ANGLES: Array[float] = [15.0, 30.0, 44.0, 46.0]
const SLOPE_XS: Array[float] = [22.0, 32.0, 42.0, 52.0]
const SLOPE_LOW_Z: float = 25.0
const SLOPE_LENGTH: float = 8.0
const SLOPE_TOP_DEPTH: float = 4.0

## [label, gap, block centre z] (plan, Behaviour 4).
const GAPS: Array = [
	[400, 7.73, -18.0], [450, 8.73, -9.0], [500, 9.66, 0.0], [550, 10.60, 9.0], [600, 11.44, 18.0]
]
const BHOP_EDGE_X: float = 60.0
const BHOP_TOP: float = 0.6

const SEAM_TOP: float = 1.5529
const EDGE_TOP: float = 3.0
const SURF_ORIGIN: Vector3 = Vector3(0.0, 0.0, -60.0)
const SURF_ANGLE: float = 53.13
const STAIR_RISE: float = 0.4064

var _course: Node3D
var _exclude: Array[RID] = []


func after_all() -> void:
	if is_instance_valid(_course):
		_course.free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Loads the course once and waits two physics frames.
func _ready_course() -> void:
	if is_instance_valid(_course):
		return
	var scene: PackedScene = load(COURSE_PATH) as PackedScene
	_course = scene.instantiate() as Node3D
	add_child(_course)
	var player: CollisionObject3D = _course.get_node("Player") as CollisionObject3D
	_exclude = [player.get_rid()]
	await get_tree().physics_frame
	await get_tree().physics_frame


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = _course.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = _exclude
	return space.intersect_ray(query)


func _ray_dir(from: Vector3, dir: Vector3) -> Dictionary:
	return _ray(from, from + dir * RAY_LENGTH)


func _down(x: float, z: float) -> Dictionary:
	return _ray(Vector3(x, RAY_TOP, z), Vector3(x, RAY_TOP - RAY_LENGTH, z))


## Height of the first surface under (x, z), or NAN if none.
func _height(x: float, z: float) -> float:
	var hit: Dictionary = _down(x, z)
	return (hit["position"] as Vector3).y if hit else NAN


func _angle_from_up(x: float, z: float) -> float:
	var hit: Dictionary = _down(x, z)
	if not hit:
		return NAN
	return rad_to_deg((hit["normal"] as Vector3).angle_to(Vector3.UP))


func _assert_height(x: float, z: float, expected: float, what: String) -> void:
	assert_almost_eq(_height(x, z), expected, POS_TOL, "%s at (%.4f, %.4f)" % [what, x, z])


func _hit_pos(hit: Dictionary) -> Vector3:
	return hit["position"] as Vector3 if hit else Vector3(NAN, NAN, NAN)


# Behaviour 6.
func test_steps() -> void:
	await _ready_course()
	var heights: Array[float] = [0.30, 0.44, 0.46, 0.60]
	var xs: Array[float] = [-21.0, -15.0, -9.0, -3.0]
	for i: int in heights.size():
		_assert_height(xs[i], 26.5, heights[i], "step %.2f" % heights[i])


# Behaviour 7.
func test_slopes() -> void:
	await _ready_course()
	for i: int in SLOPE_ANGLES.size():
		var angle: float = SLOPE_ANGLES[i]
		var a: float = deg_to_rad(angle)
		var x: float = SLOPE_XS[i]
		var rise: float = SLOPE_LENGTH * sin(a)
		var edge_z: float = SLOPE_LOW_Z + SLOPE_LENGTH * cos(a)
		var mid_z: float = SLOPE_LOW_Z + SLOPE_LENGTH / 2.0 * cos(a)
		assert_almost_eq(_angle_from_up(x, mid_z), angle, ANGLE_TOL, "slope %d normal" % angle)
		_assert_height(
			x, edge_z - EDGE_STEP, rise - EDGE_STEP * tan(a), "slope %d below top edge" % angle
		)
		if angle == 46.0:
			continue
		_assert_height(x, edge_z + SLOPE_TOP_DEPTH / 2.0, rise, "top %d centre" % angle)
		_assert_height(x, edge_z + EDGE_STEP, rise, "top %d past top edge" % angle)


# Behaviour 8.
func test_ledges() -> void:
	await _ready_course()
	_assert_height(5.0, 27.0, 1.563, "ledge 1.563")
	_assert_height(11.0, 27.0, 1.663, "ledge 1.663")


# Behaviour 4: heights and gap lengths.
func test_bhop_gaps() -> void:
	await _ready_course()
	_assert_height(40.0, 0.0, BHOP_TOP, "platform")
	for row: Array in GAPS:
		var label: int = row[0]
		var gap: float = row[1]
		var z: float = row[2]
		_assert_height(BHOP_EDGE_X + 3.0 + gap, z, BHOP_TOP, "block %d" % label)
		var mid: Vector3 = Vector3(BHOP_EDGE_X + gap / 2.0, BHOP_TOP / 2.0, z)
		var x_a: float = _hit_pos(_ray_dir(mid, Vector3.LEFT)).x
		var x_b: float = _hit_pos(_ray_dir(mid, Vector3.RIGHT)).x
		assert_almost_eq(x_b - x_a, gap, POS_TOL, "gap %d" % label)
		_assert_height(mid.x, z, 0.0, "floor in gap %d" % label)


# Behaviour 5: 15 deg plateau tiles.
func test_seam_plateau_tiles() -> void:
	await _ready_course()
	var centre: Vector2 = Vector2(-55.0, -40.7956)
	for offset: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var p: Vector2 = centre + offset
		_assert_height(p.x, p.y, SEAM_TOP, "15 deg tile")


# Behaviour 5: ramp normals and edges.
## [x, angle, low edge z, top edge z, plateau top, rises toward -Z]
func _seam_ramps() -> Array:
	var c15: float = 6.0 * cos(deg_to_rad(15.0))
	var c30: float = 6.0 * cos(deg_to_rad(30.0))
	return [
		[-55.0, 15.0, -25.0, -25.0 - c15, SEAM_TOP, true],
		[-55.0, 15.0, -56.5911, -56.5911 + c15, SEAM_TOP, false],
		[-32.0, 30.0, -25.0, -25.0 - c30, EDGE_TOP, true],
		[-32.0, 30.0, -45.3923, -45.3923 + c30, EDGE_TOP, false],
	]


func test_seam_ramps() -> void:
	await _ready_course()
	for r: Array in _seam_ramps():
		var x: float = r[0]
		var angle: float = r[1]
		var low_z: float = r[2]
		var top_z: float = r[3]
		var top: float = r[4]
		# Unit step from low edge toward the top edge.
		var up: float = -1.0 if r[5] else 1.0
		var drop: float = EDGE_STEP * tan(deg_to_rad(angle))
		var what: String = "%d ramp at z %.2f" % [angle, low_z]
		var mid_z: float = (low_z + top_z) / 2.0
		assert_almost_eq(_angle_from_up(x, mid_z), angle, ANGLE_TOL, what + " normal")
		_assert_height(x, top_z + up * EDGE_STEP, top, what + ", plateau past top edge")
		_assert_height(x, top_z - up * EDGE_STEP, top - drop, what + ", ramp below top edge")
		_assert_height(x, low_z + up * EDGE_STEP, drop, what + ", ramp past low edge")
		_assert_height(x, low_z - up * EDGE_STEP, 0.0, what + ", floor before low edge")


# Behaviour 9.
func test_crouch_tunnel() -> void:
	await _ready_course()
	var roof: Dictionary = _ray_dir(Vector3(-45.0, 0.01, 31.0), Vector3.UP)
	assert_almost_eq(_hit_pos(roof).y, 1.016, POS_TOL, "roof underside")
	var centre: Vector3 = Vector3(-45.0, 0.5, 31.0)
	var west: float = _hit_pos(_ray_dir(centre, Vector3.LEFT)).x
	var east: float = _hit_pos(_ray_dir(centre, Vector3.RIGHT)).x
	assert_almost_eq(east - west, 5.0, POS_TOL, "inside width")


# Behaviour 10.
func test_surf() -> void:
	await _ready_course()
	# Top-face centres of RampLeft and RampRight (local centre + 0.3 * local up).
	for x: float in [-6.336, 6.336]:
		var angle: float = _angle_from_up(SURF_ORIGIN.x + x, SURF_ORIGIN.z)
		assert_almost_eq(angle, SURF_ANGLE, ANGLE_TOL, "surf face at x %.3f" % x)
	_assert_height(-15.0, SURF_ORIGIN.z + 11.0, 8.9408, "drop ledge")
	for k: int in range(1, 23):
		var z: float = SURF_ORIGIN.z + 35.336 - 1.016 * (k - 1)
		_assert_height(-15.0, z, k * STAIR_RISE, "stair %d" % k)


# Behaviour 3: walls.
func test_strafe_lane_walls() -> void:
	await _ready_course()
	_assert_height(-87.0, -43.5, 22.0, "west wall top")
	_assert_height(-73.0, -43.5, 22.0, "east wall top")
	var inside: Vector3 = Vector3(-80.0, 1.0, -43.5)
	assert_almost_eq(_hit_pos(_ray_dir(inside, Vector3.LEFT)).x, -86.5, POS_TOL, "west inner face")
	assert_almost_eq(_hit_pos(_ray_dir(inside, Vector3.RIGHT)).x, -73.5, POS_TOL, "east inner face")
	var south: Dictionary = _ray_dir(Vector3(-87.0, 1.0, 20.0), Vector3.FORWARD)
	assert_almost_eq(_hit_pos(south).z, 10.0, POS_TOL, "south end")
	var north: Dictionary = _ray_dir(Vector3(-87.0, 1.0, -110.0), Vector3.BACK)
	assert_almost_eq(_hit_pos(north).z, -97.0, POS_TOL, "north end")


# Behaviour 3: distance lines and numbers.
func test_strafe_lane_markers() -> void:
	await _ready_course()
	var lines: Node = _course.get_node("Stations/StrafeLane/Lines")
	assert_eq(lines.get_child_count(), 11, "11 lines")
	var numbers: Node = _course.get_node("Stations/StrafeLane/Numbers")
	assert_eq(numbers.get_child_count(), 22, "22 numbers")
	for d: int in range(0, 101, 10):
		var z: float = 10.0 - d
		var line: Node3D = lines.get_node_or_null("Line%03d" % d) as Node3D
		assert_not_null(line, "line %d" % d)
		if line:
			assert_almost_eq(line.global_position.z, z, POS_TOL, "line %d z" % d)
		_assert_height(-80.0, z, 0.0, "floor under line %d" % d)
		for side: String in ["West", "East"]:
			var number: Label3D = numbers.get_node_or_null("%s%03d" % [side, d]) as Label3D
			assert_not_null(number, "%s number %d" % [side, d])
			if number:
				assert_eq(number.text, str(d))
				assert_almost_eq(number.global_position.z, z, POS_TOL, "%s %d z" % [side, d])
