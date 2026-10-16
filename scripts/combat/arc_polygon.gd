class_name ArcPolygon
extends RefCounted
## Builds the outline of a pie-slice wedge, for drawing melee arcs and their aim preview.


static func wedge(direction: Vector2, radius: float, arc_degrees: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array([Vector2.ZERO])
	var half := deg_to_rad(minf(arc_degrees, 359.0)) / 2.0
	for index in points + 1:
		var angle := -half + 2.0 * half * index / points
		polygon.append(direction.normalized().rotated(angle) * radius)
	return polygon
