class_name DungeonMapParser
extends RefCounted
## Turns an ASCII drawing into a DungeonMap.
##   #  wall      .  floor      +  door
##   P  player spawn (on floor)     >  exit (on floor; optional)
##   Enemy spawns (on floor), by the weapon they carry:  s  sword   w  wand   c  crossbow   f  fireball

const WALL := "#"
const FLOOR := "."
const DOOR := "+"
const PLAYER := "P"
const EXIT := ">"
## Enemy spawn symbols and the weapon id each enemy carries.
const ENEMY_WEAPONS := {"s": "sword", "w": "wand", "c": "crossbow", "f": "fireball"}
const NEIGHBOURS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


func parse(ascii: String) -> DungeonMap:
	var rows := ascii.strip_edges().split("\n")
	var size := Vector2i(rows[0].length(), rows.size())
	assert(Array(rows).all(func(row: String) -> bool: return row.length() == size.x), "every row must be the same width")

	var enemy_symbols := ENEMY_WEAPONS.keys()
	var floor_cells := _cells_matching(rows, [FLOOR, PLAYER, EXIT] + enemy_symbols)
	var door_cells := _cells_matching(rows, [DOOR])
	var player_cells := _cells_matching(rows, [PLAYER])
	assert(player_cells.size() == 1, "map needs exactly one player spawn")
	var exit_cells := _cells_matching(rows, [EXIT])
	assert(exit_cells.size() <= 1, "map has more than one exit")

	var room_by_cell := _label_rooms(floor_cells)
	var room_count := 0
	for room: int in room_by_cell.values():
		room_count = maxi(room_count, room + 1)

	return DungeonMap.new(
		size,
		room_by_cell,
		_doors_by_room(door_cells, room_by_cell),
		_as_set(door_cells),
		player_cells[0],
		_enemy_weapons_by_cell(rows),
		room_count,
		exit_cells[0] if not exit_cells.is_empty() else DungeonMap.NO_CELL,
	)


func _enemy_weapons_by_cell(rows: PackedStringArray) -> Dictionary:
	var weapons := {}
	for cell in _cells_matching(rows, ENEMY_WEAPONS.keys()):
		weapons[cell] = ENEMY_WEAPONS[rows[cell.y][cell.x]]
	return weapons


func _cells_matching(rows: PackedStringArray, symbols: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] in symbols:
				cells.append(Vector2i(x, y))
	return cells


## Flood-fills connected floor into numbered rooms. Doors are not floor, so they split rooms apart.
func _label_rooms(floor_cells: Array[Vector2i]) -> Dictionary:
	var floor_set := _as_set(floor_cells)
	var room_by_cell := {}
	var next_room := 0
	for start in floor_cells:
		if room_by_cell.has(start):
			continue
		var frontier: Array[Vector2i] = [start]
		room_by_cell[start] = next_room
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			for step in NEIGHBOURS:
				var neighbour := cell + step
				if floor_set.has(neighbour) and not room_by_cell.has(neighbour):
					room_by_cell[neighbour] = next_room
					frontier.append(neighbour)
		next_room += 1
	return room_by_cell


func _doors_by_room(door_cells: Array[Vector2i], room_by_cell: Dictionary) -> Dictionary:
	var doors_by_room := {}
	for door in door_cells:
		for step in NEIGHBOURS:
			var room: int = room_by_cell.get(door + step, DungeonMap.NO_ROOM)
			if room == DungeonMap.NO_ROOM:
				continue
			var doors: Array = doors_by_room.get_or_add(room, [])
			if not doors.has(door):
				doors.append(door)
	return doors_by_room


func _as_set(cells: Array[Vector2i]) -> Dictionary:
	var set := {}
	for cell in cells:
		set[cell] = true
	return set
