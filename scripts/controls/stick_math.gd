class_name StickMath
## Converts a finger position relative to a stick's origin into a 0..1 strength vector.


static func strength(origin: Vector2, finger: Vector2, radius: float) -> Vector2:
	assert(radius > 0.0, "radius must be positive")
	return (finger - origin).limit_length(radius) / radius
