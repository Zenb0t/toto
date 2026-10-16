class_name AutoAim
## Picks what a tap-to-attack should aim at.

const NO_TARGET := -1


## Index of the closest candidate within max_range, or NO_TARGET.
static func nearest_index(from: Vector2, candidates: Array[Vector2], max_range: float) -> int:
	var best_index := NO_TARGET
	var best_distance := max_range
	for index in candidates.size():
		var distance := from.distance_to(candidates[index])
		if distance <= best_distance:
			best_distance = distance
			best_index = index
	return best_index
