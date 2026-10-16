class_name DungeonMap
extends RefCounted
## Read-only description of a dungeon: walkable cells, doors, rooms and spawn points.
## Rooms are areas of floor separated by doors; a door belongs to every room it touches.

const NO_ROOM := -1

var size: Vector2i
var player_spawn: Vector2i
var enemy_spawns: Array[Vector2i]
var room_count: int

var _room_by_cell: Dictionary  # Vector2i -> int
var _doors_by_room: Dictionary  # int -> Array[Vector2i]
var _door_cells: Dictionary  # Vector2i -> true
var _enemy_weapon_by_cell: Dictionary  # Vector2i -> weapon id


func _init(
	grid_size: Vector2i,
	room_by_cell: Dictionary,
	doors_by_room: Dictionary,
	door_cells: Dictionary,
	player_spawn_cell: Vector2i,
	enemy_weapon_by_cell: Dictionary,
	number_of_rooms: int,
) -> void:
	size = grid_size
	_room_by_cell = room_by_cell
	_doors_by_room = doors_by_room
	_door_cells = door_cells
	player_spawn = player_spawn_cell
	_enemy_weapon_by_cell = enemy_weapon_by_cell
	enemy_spawns.assign(enemy_weapon_by_cell.keys())
	room_count = number_of_rooms


## The weapon id the enemy spawning at cell carries.
func enemy_weapon_at(cell: Vector2i) -> String:
	return _enemy_weapon_by_cell.get(cell, "")


func is_walkable(cell: Vector2i) -> bool:
	return _room_by_cell.has(cell) or is_door(cell)


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


## The room's cell closest to its middle, so things placed there are always on its floor
## (even in a room that isn't a rectangle).
func room_center(room: int) -> Vector2i:
	var cells := cells_of_room(room)
	assert(not cells.is_empty(), "room %d has no cells" % room)
	var middle := Vector2.ZERO
	for cell in cells:
		middle += Vector2(cell)
	middle /= cells.size()
	var closest := cells[0]
	for cell in cells:
		if Vector2(cell).distance_squared_to(middle) < Vector2(closest).distance_squared_to(middle):
			closest = cell
	return closest


func walkable_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(_room_by_cell.keys())
	cells.append_array(door_cells())
	return cells


## True when no door is in any of the 8 surrounding cells, so a door could close without overlapping
## something standing here.
func is_clear_of_doors(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if is_door(cell + Vector2i(dx, dy)):
				return false
	return true
