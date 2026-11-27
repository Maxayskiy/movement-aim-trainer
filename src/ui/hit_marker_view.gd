class_name HitMarkerView
extends Control
## Draws the hit marker: an X of 4 diagonal lines around the centre of this
## control. HitFeedback sets config, color and alpha.

var config: HitFeedbackConfig
var color: Color = Color.WHITE
var alpha: float = 0.0


## 8 points: start/end pairs for the diagonals up-left, up-right, down-right, down-left.
static func segments(center: Vector2, gap: float, length: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var dirs: Array[Vector2] = [
		Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)
	]
	for raw: Vector2 in dirs:
		var dir: Vector2 = raw.normalized()
		points.append(center + dir * gap)
		points.append(center + dir * (gap + length))
	return points


func _draw() -> void:
	if alpha <= 0.0 or config == null:
		return
	var points: PackedVector2Array = segments(size / 2.0, config.marker_gap, config.marker_length)
	var outline: float = config.marker_outline
	var thickness: float = config.marker_thickness
	if outline > 0.0:
		var outline_color: Color = config.marker_outline_color
		outline_color.a *= alpha
		for i: int in range(0, points.size(), 2):
			var dir: Vector2 = (points[i + 1] - points[i]).normalized()
			draw_line(
				points[i] - dir * outline,
				points[i + 1] + dir * outline,
				outline_color,
				thickness + 2.0 * outline,
				true
			)
	var line_color: Color = color
	line_color.a *= alpha
	for i: int in range(0, points.size(), 2):
		draw_line(points[i], points[i + 1], line_color, thickness, true)
