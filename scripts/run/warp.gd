class_name Warp
extends RefCounted
## The playtest aid behind Tune → World → Warp: places of the slice the hero can jump to at once. Each target is a
## map and the spot on it where the hero lands, the same pair the transition rule gives for an exit
## (WorldLayout.Destination), so a warp goes through the same machinery as taking stairs. This class also finds the
## two landing cells that are not on a map's own marks (beside the ruin's chest, outside the arena's door). Pure.

const VILLAGE := "village"
const RUIN := "ruin"
const CRYPT_ENTRANCE := "crypt_entrance"
const ARENA := "arena"
## The four orthogonal steps, in the order the landing cells are tried.
const STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## A place the hero can warp to.
class Target:
	extends RefCounted
	var id: String
	var label: String
	var destination: WorldLayout.Destination

	func _init(target_id: String, target_label: String, leads_to: WorldLayout.Destination) -> void:
		id = target_id
		label = target_label
		destination = leads_to


## Every place, in the order the Tune screen lists them: the village (the start, by the inn), the ruin, the crypt
## entrance (in front of the mausoleum, where coming up from the first level lands), each crypt level (on its
## stairs up, where coming down lands) and the Lich's arena (outside its door, so walking in still locks it).
static func targets() -> Array[Target]:
	var plains := WorldLayout.PLAINS_ID
	var all: Array[Target] = [
		Target.new(VILLAGE, "The village", WorldLayout.Destination.new(plains, WorldLayout.Spot.START)),
		Target.new(RUIN, "The ruin", WorldLayout.Destination.new(plains, WorldLayout.Spot.RUIN)),
		Target.new(
			CRYPT_ENTRANCE, "The crypt entrance", WorldLayout.Destination.new(plains, WorldLayout.Spot.STAIRS_DOWN)),
	]
	for floor_number in range(1, WorldLayout.FLOOR_COUNT + 1):
		all.append(Target.new(
			level_id(floor_number), "Crypt level %d" % floor_number,
			WorldLayout.Destination.new(WorldLayout.floor_id(floor_number), WorldLayout.Spot.STAIRS_UP)))
	all.append(Target.new(
		ARENA, "The Lich's arena",
		WorldLayout.Destination.new(WorldLayout.floor_id(WorldLayout.FLOOR_COUNT), WorldLayout.Spot.ARENA_DOOR)))
	return all


static func level_id(floor_number: int) -> String:
	return "crypt_level_%d" % floor_number


## The target with that id, or null.
static func target(target_id: String) -> Target:
	for each in targets():
		if each.id == target_id:
			return each
	return null


## The walkable cell closest to the ruin's chest, other than the chest's own: inside the ruin's walls or in a gap,
## never in a wall. DungeonMap.NO_CELL for a map without a ruin.
static func cell_beside_ruin(map: DungeonMap) -> Vector2i:
	if map.ruin_cell == DungeonMap.NO_CELL:
		return DungeonMap.NO_CELL
	var best := DungeonMap.NO_CELL
	for cell in map.walkable_cells():
		if cell == map.ruin_cell or _is_no_closer(map.ruin_cell, cell, best):
			continue
		best = cell
	return best


## A standable cell just outside one of the arena's doors (not in the arena), or the map's start when the map has no
## arena. Doors are tried in a fixed order, so the same map always gives the same cell.
static func cell_outside_arena(map: DungeonMap) -> Vector2i:
	var arena := map.locking_room_of_kind(LockingRoom.Kind.ARENA)
	if arena == DungeonMap.NO_ROOM:
		return map.player_spawn
	var doors := map.doors_of_room(arena)
	doors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for door in doors:
		for step in STEPS:
			var cell := door + step
			if map.is_standable(cell) and not map.is_door(cell) and map.room_at(cell) != arena:
				return cell
	return map.player_spawn


## Whether `cell` is no closer to `origin` than `best` (so `best` stays); any cell beats NO_CELL.
static func _is_no_closer(origin: Vector2i, cell: Vector2i, best: Vector2i) -> bool:
	if best == DungeonMap.NO_CELL:
		return false
	var d_cell := origin.distance_squared_to(cell)
	var d_best := origin.distance_squared_to(best)
	if d_cell != d_best:
		return d_cell > d_best
	return cell.y > best.y or (cell.y == best.y and cell.x >= best.x)
