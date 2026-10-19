class_name PoissonDisc
extends RefCounted
## Spreads points over an area evenly but with no pattern: no two closer than a spacing, and no gap much wider
## (Bridson's algorithm). The plains use it wherever things should look scattered by nature rather than by dice:
## the zones' centres, the trees at a wood's edge, lone trees. Pure: the caller passes the random number generator.

## How many new points are tried round each point before it is given up on.
const TRIES_PER_POINT := 20


## Cells inside `area`, about `spacing` cells apart at least (points are rounded down to cells, so two can be up to a
## cell closer). The same area, spacing and random numbers always give the same cells, in the same order.
static func sample(area: Rect2i, spacing: float, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if area.size.x <= 0 or area.size.y <= 0 or spacing <= 0.0:
		return cells
	var bucket_size := spacing / sqrt(2.0)  # A bucket this wide holds one point at most.
	var buckets := {}  # Vector2i -> Vector2: the point in each bucket
	var points: Array[Vector2] = []
	var active: Array[Vector2] = []
	var first := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
	_keep(first, bucket_size, buckets, points, active)
	while not active.is_empty():
		var index := rng.randi_range(0, active.size() - 1)
		var around := active[index]
		var placed := false
		for _try in TRIES_PER_POINT:
			var angle := rng.randf() * TAU
			var candidate := around + Vector2.from_angle(angle) * spacing * rng.randf_range(1.0, 2.0)
			if _inside(candidate, area) and _is_far_enough(candidate, spacing, bucket_size, buckets):
				_keep(candidate, bucket_size, buckets, points, active)
				placed = true
				break
		if not placed:
			active.remove_at(index)
	for point in points:
		cells.append(Vector2i(point.floor()))
	return cells


static func _keep(
		point: Vector2, bucket_size: float, buckets: Dictionary, points: Array[Vector2], active: Array[Vector2]
) -> void:
	buckets[_bucket_of(point, bucket_size)] = point
	points.append(point)
	active.append(point)


static func _inside(point: Vector2, area: Rect2i) -> bool:
	return point.x >= area.position.x and point.y >= area.position.y and point.x < area.end.x and point.y < area.end.y


static func _is_far_enough(point: Vector2, spacing: float, bucket_size: float, buckets: Dictionary) -> bool:
	var bucket := _bucket_of(point, bucket_size)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var other: Variant = buckets.get(bucket + Vector2i(dx, dy))
			if other != null and point.distance_to(other) < spacing:
				return false
	return true


static func _bucket_of(point: Vector2, bucket_size: float) -> Vector2i:
	return Vector2i((point / bucket_size).floor())
