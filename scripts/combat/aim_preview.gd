class_name AimPreview
extends RefCounted
## Draws an AimShape on a canvas: the player's aim while dragging, and an enemy's telegraphed attack.

const WIDTH := 4.0
const ARC_POINTS := 24


## landing_distance places the landing spot of LOB shapes; other shapes ignore it.
static func draw(
		canvas: CanvasItem, shape: AimShape, direction: Vector2, landing_distance: float, color: Color) -> void:
	match shape.kind:
		AimShape.Kind.LINE:
			var end := direction * shape.length
			canvas.draw_line(Vector2.ZERO, end, color, WIDTH * 3.0)
			if shape.end_radius > 0.0:
				canvas.draw_circle(end, shape.end_radius, color)
		AimShape.Kind.CONE:
			canvas.draw_colored_polygon(
				ArcPolygon.wedge(direction, shape.length, shape.spread_degrees, ARC_POINTS), color)
		AimShape.Kind.LOB:
			var landing := direction * minf(landing_distance, shape.length)
			canvas.draw_line(Vector2.ZERO, landing, color, WIDTH)
			canvas.draw_circle(landing, shape.end_radius, color)
		AimShape.Kind.FAN:
			for angle in Spread.angles_degrees(shape.count, shape.spread_degrees):
				canvas.draw_line(Vector2.ZERO, direction.rotated(deg_to_rad(angle)) * shape.length, color, WIDTH)
