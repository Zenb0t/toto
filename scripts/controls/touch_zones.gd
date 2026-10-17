class_name TouchZones
extends RefCounted
## Which of several round touch zones a finger landed in. Zones may overlap (the layout is the player's to
## arrange); the one whose centre is nearest wins.

const NONE := -1


## Whether a point lands on one of these on-screen controls while it shows. Touch controls leave such touches
## to them (the minimap, the Map button), whatever their own zones cover.
static func is_kept_by(point: Vector2, keepers: Array[Control]) -> bool:
	for keeper in keepers:
		if is_instance_valid(keeper) and keeper.is_visible_in_tree() and keeper.get_global_rect().has_point(point):
			return true
	return false


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
