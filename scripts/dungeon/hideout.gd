class_name Hideout
extends RefCounted
## Where the Lich hides when he is hurt before the boss arena locks: a cell of the arena that no doorway can see,
## the one nearest to where he stands, which is in his crypt (see BossArena), the recess at the front of the hall,
## whose side walls shade its corners from the doorways. A hero shooting from a doorway never has a clear shot at
## him and has to walk in, which locks the arena. Pure: it only reads the map, so it holds for any arena a generator draws.

## How far from a cell's middle, in cells, its body is checked for being seen (his body is not a point).
const BODY_REACH := 0.3
## A viewer may stand anywhere in a doorway: its middle and its four sides, this far from the middle in cells.
const DOORWAY_REACH := 0.45


## The cell, or DungeonMap.NO_CELL for a map with no boss arena: of the cells of the arena that no doorway and
## not the middle of the room can see, the one nearest to `near` (where he stands: his crypt), so he withdraws no farther than he must. When
## the whole room can be seen from some doorway, the cell farthest from the doorways.
static func cell_for(map: DungeonMap, near: Vector2i, sight: Pathfinder = null) -> Vector2i:
	var room := map.locking_room_of_kind(LockingRoom.Kind.ARENA)
	if room == DungeonMap.NO_ROOM:
		return DungeonMap.NO_CELL
	var finder := sight if sight != null else Pathfinder.new(map)
	var doors := map.doors_of_room(room)
	var viewpoints := _viewpoints(doors)
	# A real hiding place is tucked away: a hero who walks in to the middle of the room does not see it either.
	viewpoints.append(DungeonView.cell_center(map.room_center(room)))
	var cells := map.cells_of_room(room).filter(map.is_standable)
	cells.sort()
	var hidden: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if not _is_seen(finder, viewpoints, cell):
			hidden.append(cell)
	if hidden.is_empty():
		return _farthest_from(doors, cells)
	var best: Vector2i = hidden[0]
	for cell in hidden:
		if Vector2(cell).distance_to(Vector2(near)) < Vector2(best).distance_to(Vector2(near)):
			best = cell
	return best


## Whether anyone standing in one of the doorways of the room could see the cell (or any part of a body on it).
static func is_seen_from_doorways(map: DungeonMap, room: int, cell: Vector2i, sight: Pathfinder = null) -> bool:
	var finder := sight if sight != null else Pathfinder.new(map)
	return _is_seen(finder, _viewpoints(map.doors_of_room(room)), cell)


static func _viewpoints(doors: Array[Vector2i]) -> PackedVector2Array:
	var points := PackedVector2Array()
	for door in doors:
		var middle := DungeonView.cell_center(door)
		for spot: Vector2 in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			points.append(middle + spot * DOORWAY_REACH * DungeonView.TILE_SIZE)
	return points


static func _is_seen(finder: Pathfinder, viewpoints: PackedVector2Array, cell: Vector2i) -> bool:
	var middle := DungeonView.cell_center(cell)
	for spot: Vector2 in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var target := middle + spot * BODY_REACH * DungeonView.TILE_SIZE
		for from in viewpoints:
			if finder.can_see(from, target):
				return true
	return false


static func _farthest_from(doors: Array[Vector2i], cells: Array[Vector2i]) -> Vector2i:
	var best := DungeonMap.NO_CELL
	var best_gap := -INF
	for cell in cells:
		var gap := INF
		for door in doors:
			gap = minf(gap, Vector2(door).distance_to(Vector2(cell)))
		if gap > best_gap:
			best = cell
			best_gap = gap
	return best
