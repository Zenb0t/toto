class_name DungeonMapParser
extends RefCounted
## Turns an ASCII drawing into a DungeonMap.
##   #  wall      .  floor      +  door
##   P  player spawn (on floor; optional on a map with stairs up, which are then the start)
##   >  stairs down, the exit (on floor; optional)     <  stairs up (on floor; optional)
##   *  an item lying on the floor
##   ~  deep water (blocks walking, not sight or shots)     L  lava (walkable, burns)
##   ,  shallow water (walkable, slowly)
##   F  campfire (on floor: scenery you can walk over; a camp's monsters stand round it)
##   T  tree grove    B  boulder    =  barricade (outdoors: each blocks walking, see DungeonMap.Blocker)
##   Enemy spawns (on floor), by monster (see Bestiary):  k kobold  g goblin  a goblin archer  s bandit
##   w apprentice  c crossbowman  f pyromancer  n necromancer  o orc  W orc wizard  d dwarf
##   e deep elf mage  O ogre  z skeleton  x skeleton archer  m skeletal mage  Z skeleton warrior

const WALL := "#"
const FLOOR := "."
const DOOR := "+"
const PLAYER := "P"
const EXIT := ">"
const STAIRS_UP := "<"
const LOOT := "*"
const WATER := "~"
const LAVA := "L"
const SHALLOW := ","
const CAMPFIRE := "F"
const GROVE := "T"
const BOULDER := "B"
const BARRICADE := "="
const NEIGHBOURS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


func parse(ascii: String) -> DungeonMap:
	var rows := ascii.strip_edges().split("\n")
	var size := Vector2i(rows[0].length(), rows.size())
	assert(Array(rows).all(func(row: String) -> bool: return row.length() == size.x), "every row must be the same width")

	var enemy_symbols := Bestiary.letters()
	var floor_cells := _cells_matching(rows, [FLOOR, PLAYER, EXIT, STAIRS_UP, LOOT, WATER, LAVA, SHALLOW, CAMPFIRE] + enemy_symbols)
	var door_cells := _cells_matching(rows, [DOOR])
	var exit_cells := _cells_matching(rows, [EXIT])
	assert(exit_cells.size() <= 1, "map has more than one exit")
	var stairs_up_cells := _cells_matching(rows, [STAIRS_UP])
	assert(stairs_up_cells.size() <= 1, "map has more than one stairs up")
	var player_cells := _cells_matching(rows, [PLAYER])
	if player_cells.is_empty():
		player_cells = stairs_up_cells
	assert(player_cells.size() == 1, "map needs exactly one player spawn (or stairs up to start on)")

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
		_monsters_by_cell(rows),
		room_count,
		exit_cells[0] if not exit_cells.is_empty() else DungeonMap.NO_CELL,
		_terrain_by_cell(rows),
		_cells_matching(rows, [LOOT]),
		stairs_up_cells[0] if not stairs_up_cells.is_empty() else DungeonMap.NO_CELL,
		_blockers_by_cell(rows),
		_cells_matching(rows, [CAMPFIRE]),
	)


func _blockers_by_cell(rows: PackedStringArray) -> Dictionary:
	var blockers := {}
	for cell in _cells_matching(rows, [GROVE]):
		blockers[cell] = DungeonMap.Blocker.GROVE
	for cell in _cells_matching(rows, [BOULDER]):
		blockers[cell] = DungeonMap.Blocker.BOULDER
	for cell in _cells_matching(rows, [BARRICADE]):
		blockers[cell] = DungeonMap.Blocker.BARRICADE
	return blockers


func _terrain_by_cell(rows: PackedStringArray) -> Dictionary:
	var terrain := {}
	for cell in _cells_matching(rows, [WATER]):
		terrain[cell] = DungeonMap.Terrain.WATER
	for cell in _cells_matching(rows, [LAVA]):
		terrain[cell] = DungeonMap.Terrain.LAVA
	for cell in _cells_matching(rows, [SHALLOW]):
		terrain[cell] = DungeonMap.Terrain.SHALLOW
	return terrain


func _monsters_by_cell(rows: PackedStringArray) -> Dictionary:
	var monsters := {}
	for cell in _cells_matching(rows, Bestiary.letters()):
		monsters[cell] = Bestiary.by_letter(rows[cell.y][cell.x]).id
	return monsters


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
