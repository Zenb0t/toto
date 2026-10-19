class_name DungeonMap
extends RefCounted
## Read-only description of a dungeon: walkable cells, doors, rooms, terrain and spawn points.
## Rooms are areas separated by doors; a door belongs to every room it touches. A room's water and lava
## are part of it: deep water can't be walked on but can be seen and shot across; shallow water can be
## waded through, slowly; lava can be walked on, but it burns.

## PATH is beaten earth, walkable like floor: the village's streets and square. ROAD is the dirt road between the
## village and the quadrant exits: also only a look, as walkable and as clear as grass.
enum Terrain { FLOOR, WATER, LAVA, SHALLOW, PATH, ROAD }
## Solid things outdoors that aren't plain wall: tree groves (they block walking and sight), boulders (small
## cover: they block walking and shots, but sight passes over them), barricades (they shut a quadrant exit), and
## the village's palisade (blocks walking, sight and shots), well and props (barrels, crates: low, like boulders)
## and buildings (solid; see Village.Building).
enum Blocker { GROVE, BOULDER, BARRICADE, PALISADE, WELL, PROP, BUILDING }

## Wading through shallow water, everyone moves at this share of their speed.
const WADING_SPEED := 0.6
const NO_ROOM := -1
const NO_CELL := Vector2i(-1, -1)
## blocker_at's answer for a cell that holds none.
const NO_BLOCKER := -1
## The blockers sight passes over.
const LOW_BLOCKERS := [Blocker.BOULDER, Blocker.WELL, Blocker.PROP]
## The blockers the village is built of: each is drawn as a model standing on the ground, not as a wall.
const VILLAGE_BLOCKERS := [Blocker.PALISADE, Blocker.WELL, Blocker.PROP, Blocker.BUILDING]

var size: Vector2i
var player_spawn: Vector2i
var enemy_spawns: Array[Vector2i]
var room_count: int
## Where the stairs down (the way out) are, or NO_CELL for a map without an exit.
var exit_cell: Vector2i
## Where the stairs up are, or NO_CELL for a map without them (the top of the descent).
var stairs_up_cell: Vector2i
## Where an item lies on the floor from the start.
var loot_cells: Array[Vector2i] = []
## The village on this map, or null (only the plains have one).
var village: Village
## Where campfires burn (walkable scenery; see Camps for the ones that are a band's home).
var campfire_cells: Array[Vector2i] = []
## The rooms that lock when the hero walks in (room -> LockingRoom.Kind): the boss arena and trap rooms.
var locking_rooms := {}
## Where each locking room's mark lies (room -> cell): a free floor cell in its middle, where a trap room's chest stands.
var locking_marks := {}
## Where the ruin's guaranteed chest stands (its middle, and its band's home), or NO_CELL for a map without a ruin.
var ruin_cell: Vector2i = NO_CELL

var _room_by_cell: Dictionary  # Vector2i -> int
var _doors_by_room: Dictionary  # int -> Array[Vector2i]
var _door_cells: Dictionary  # Vector2i -> true
var _monster_by_cell: Dictionary  # Vector2i -> monster id
var _terrain_by_cell: Dictionary  # Vector2i -> Terrain, only for cells that aren't plain floor
var _blocker_by_cell: Dictionary  # Vector2i -> Blocker, for the outdoor things that stand in the way


func _init(
	grid_size: Vector2i,
	room_by_cell: Dictionary,
	doors_by_room: Dictionary,
	door_cells: Dictionary,
	player_spawn_cell: Vector2i,
	monster_by_cell: Dictionary,
	number_of_rooms: int,
	exit: Vector2i = NO_CELL,
	terrain_by_cell: Dictionary = {},
	loot: Array[Vector2i] = [],
	stairs_up: Vector2i = NO_CELL,
	blocker_by_cell: Dictionary = {},
	village_on_map: Village = null,
	campfires: Array[Vector2i] = [],
	locking: Dictionary = {},
	ruin_chest: Vector2i = NO_CELL,
	marks: Dictionary = {},
) -> void:
	size = grid_size
	_room_by_cell = room_by_cell
	_doors_by_room = doors_by_room
	_door_cells = door_cells
	player_spawn = player_spawn_cell
	_monster_by_cell = monster_by_cell
	enemy_spawns.assign(monster_by_cell.keys())
	room_count = number_of_rooms
	exit_cell = exit
	_terrain_by_cell = terrain_by_cell
	loot_cells = loot
	stairs_up_cell = stairs_up
	_blocker_by_cell = blocker_by_cell
	village = village_on_map
	campfire_cells = campfires
	locking_rooms = locking
	ruin_cell = ruin_chest
	locking_marks = marks


## The id of the monster (see Bestiary) spawning at cell, or "" if none does.
func monster_at(cell: Vector2i) -> String:
	return _monster_by_cell.get(cell, "")


## True for anything that isn't solid wall: room cells (water and lava included) and doors.
func is_open(cell: Vector2i) -> bool:
	return _room_by_cell.has(cell) or is_door(cell)


func is_walkable(cell: Vector2i) -> bool:
	return is_open(cell) and terrain_at(cell) != Terrain.WATER


## Sight and shots cross water and lava; only walls (and closed doors, handled by the doors) stop them.
## Boulders, the well and props are low enough to see over (shots still stop at them).
func is_see_through(cell: Vector2i) -> bool:
	return is_open(cell) or blocker_at(cell) in LOW_BLOCKERS


## Which Blocker stands on a cell, or NO_BLOCKER.
func blocker_at(cell: Vector2i) -> int:
	return _blocker_by_cell.get(cell, NO_BLOCKER)


func cells_with_blocker(blocker: Blocker) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _blocker_by_cell:
		if _blocker_by_cell[cell] == blocker:
			cells.append(cell)
	return cells


## Whether a cell lies inside the village's palisade (or on it).
func is_in_village(cell: Vector2i) -> bool:
	return village != null and village.contains(cell)

func is_campfire(cell: Vector2i) -> bool:
	return cell in campfire_cells


## Which kind of locking room a room is (a LockingRoom.Kind), or LockingRoom.NONE for one that never locks.
func locking_kind(room: int) -> int:
	return locking_rooms.get(room, LockingRoom.NONE)


## The rooms that lock when the hero walks in, for DungeonProgress.
func locking_room_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(locking_rooms.keys())
	return ids


## The cell a locking room's mark lies on (where a trap room's chest stands), or NO_CELL for a room that never locks.
func locking_mark_cell(room: int) -> Vector2i:
	return locking_marks.get(room, NO_CELL)


## The room of the given kind, or NO_ROOM (the boss arena, say).
func locking_room_of_kind(kind: LockingRoom.Kind) -> int:
	for room: int in locking_rooms:
		if locking_rooms[room] == kind:
			return room
	return NO_ROOM


func terrain_at(cell: Vector2i) -> Terrain:
	return _terrain_by_cell.get(cell, Terrain.FLOOR)


## How fast one moves on a cell, as a share of one's speed: slower wading through shallow water.
func ground_speed(cell: Vector2i) -> float:
	return WADING_SPEED if terrain_at(cell) == Terrain.SHALLOW else 1.0


## Where it is safe to stand or put something: walkable and not burning.
func is_standable(cell: Vector2i) -> bool:
	return is_walkable(cell) and terrain_at(cell) != Terrain.LAVA


func cells_with(terrain: Terrain) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _terrain_by_cell:
		if _terrain_by_cell[cell] == terrain:
			cells.append(cell)
	return cells


func is_door(cell: Vector2i) -> bool:
	return _door_cells.has(cell)


func room_at(cell: Vector2i) -> int:
	return _room_by_cell.get(cell, NO_ROOM)


func doors_of_room(room: int) -> Array[Vector2i]:
	var doors: Array[Vector2i] = []
	doors.assign(_doors_by_room.get(room, []))
	return doors


func door_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(_door_cells.keys())
	return cells


func cells_of_room(room: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _room_by_cell:
		if _room_by_cell[cell] == room:
			cells.append(cell)
	return cells


## The room's free, standable cell closest to its middle, so things placed there (the chest) are always on
## safe floor, even in a room that isn't a rectangle or has a pool in the middle, and never on another item.
func room_center(room: int) -> Vector2i:
	return middle_cell(cells_of_room(room).filter(
		func(cell: Vector2i) -> bool: return is_standable(cell) and cell not in loot_cells))


## Of the given cells, the one closest to their middle.
static func middle_cell(cells: Array) -> Vector2i:
	assert(not cells.is_empty(), "no cells to pick the middle of")
	var middle := Vector2.ZERO
	for cell: Vector2i in cells:
		middle += Vector2(cell)
	middle /= cells.size()
	var closest: Vector2i = cells[0]
	for cell: Vector2i in cells:
		if Vector2(cell).distance_squared_to(middle) < Vector2(closest).distance_squared_to(middle):
			closest = cell
	return closest


## Every cell that isn't wall (see is_open).
func open_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(_room_by_cell.keys())
	cells.append_array(door_cells())
	return cells


func walkable_cells() -> Array[Vector2i]:
	return open_cells().filter(is_walkable)


## True when no door is in any of the 8 surrounding cells, so a door could close without overlapping
## something standing here.
func is_clear_of_doors(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if is_door(cell + Vector2i(dx, dy)):
				return false
	return true
