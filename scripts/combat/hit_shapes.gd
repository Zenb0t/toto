class_name HitShapes
extends RefCounted
## Pure hit tests for area attacks.


## True when the point is within reach and inside the arc centred on the direction.
static func in_arc(origin: Vector2, direction: Vector2, reach: float, arc_degrees: float, point: Vector2) -> bool:
	var offset := point - origin
	if offset.length() > reach:
		return false
	if offset.is_zero_approx() or arc_degrees >= 360.0:
		return true
	return absf(rad_to_deg(direction.angle_to(offset))) <= arc_degrees / 2.0


static func in_circle(center: Vector2, radius: float, point: Vector2) -> bool:
	return center.distance_to(point) <= radius
