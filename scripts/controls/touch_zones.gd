class_name TouchZones
extends RefCounted
## Which of several round touch zones a finger landed in. Zones may overlap (the layout is the player's to
## arrange); the one whose centre is nearest wins.

const NONE := -1


## The index of the zone that owns the point, or NONE. centers and radii go together, one pair per zone.
static func owner_of(point: Vector2, centers: Array[Vector2], radii: Array[float]) -> int:
	var owner := NONE
	var best_distance := INF
	for index in centers.size():
		var distance := point.distance_to(centers[index])
		if distance <= radii[index] and distance < best_distance:
			owner = index
			best_distance = distance
	return owner
