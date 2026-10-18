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
##   r  dirt road (outdoors: grass that looks like beaten earth, see DungeonMap.Terrain.ROAD)
##   T  tree grove    B  boulder    =  barricade (outdoors: each blocks walking, see DungeonMap.Blocker)
##   The village (see Village): Y palisade   G gate (floor)   :  street or square (walkable beaten earth)
##   U  well   X  barrel or crate   D  the inn's doorstep (floor)   I inn   C church   S smithy   M market
##   1 2 3 4  a house, by colour   @  the hero's start on a street (like P)
##   A  boss arena, R  trap room: a mark on a floor cell of a room that locks when the hero walks in (see LockingRoom)
##   Enemy spawns (on floor), by monster (see Bestiary):  k kobold  g goblin  a goblin archer  s bandit
##   w apprentice  c crossbowman  f pyromancer  n necromancer  o orc  W orc wizard  d dwarf
##   e deep elf mage  O ogre  z skeleton  x skeleton archer  m skeletal mage  Z skeleton warrior  l the Lich

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
const ROAD := "r"
const GROVE := "T"
const BOULDER := "B"
const BARRICADE := "="
const NEIGHBOURS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


func parse(ascii: String) -> DungeonMap:
	var rows := ascii.strip_edges().split("\n")
	var size := Vector2i(rows[0].length(), rows.size())
	assert(Array(rows).all(func(row: String) -> bool: return row.length() == size.x), "every row must be the same width")

	var enemy_symbols := Bestiary.letters()
	var floor_cells := _cells_matching(rows, [FLOOR, PLAYER, EXIT, STAIRS_UP, LOOT, WATER, LAVA, SHALLOW, CAMPFIRE,
		Village.GATE, Village.STREET, Village.DOORSTEP, Village.START, ROAD] + LockingRoom.marks() + enemy_symbols)
	var door_cells := _cells_matching(rows, [DOOR])
	var exit_cells := _cells_matching(rows, [EXIT])
	assert(exit_cells.size() <= 1, "map has more than one exit")
	var stairs_up_cells := _cells_matching(rows, [STAIRS_UP])
	assert(stairs_up_cells.size() <= 1, "map has more than one stairs up")
	var player_cells := _cells_matching(rows, [PLAYER, Village.START])
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
		_village(rows),
		_cells_matching(rows, [CAMPFIRE]),
		_locking_rooms(rows, room_by_cell),
	)


## The rooms that carry a locking mark (see LockingRoom), by kind.
func _locking_rooms(rows: PackedStringArray, room_by_cell: Dictionary) -> Dictionary:
	var locking := {}
	for mark in LockingRoom.marks():
		for cell in _cells_matching(rows, [mark]):
			locking[room_by_cell[cell]] = LockingRoom.kind_of(mark)
	return locking


func _blockers_by_cell(rows: PackedStringArray) -> Dictionary:
	var blockers := {}
	for cell in _cells_matching(rows, [GROVE]):
		blockers[cell] = DungeonMap.Blocker.GROVE
	for cell in _cells_matching(rows, [BOULDER]):
		blockers[cell] = DungeonMap.Blocker.BOULDER
	for cell in _cells_matching(rows, [BARRICADE]):
		blockers[cell] = DungeonMap.Blocker.BARRICADE
	for cell in _cells_matching(rows, [Village.PALISADE]):
		blockers[cell] = DungeonMap.Blocker.PALISADE
	for cell in _cells_matching(rows, [Village.WELL]):
		blockers[cell] = DungeonMap.Blocker.WELL
	for cell in _cells_matching(rows, [Village.PROP]):
		blockers[cell] = DungeonMap.Blocker.PROP
	for cell in _cells_matching(rows, _building_letters()):
		blockers[cell] = DungeonMap.Blocker.BUILDING
	return blockers


func _building_letters() -> Array:
	var letters := [Village.INN, Village.CHURCH, Village.SMITHY, Village.MARKET]
	for letter in Village.HOUSE_LETTERS:
		letters.append(letter)
	return letters


## The village the drawing holds (its palisade is what marks it), or null on a map without one.
func _village(rows: PackedStringArray) -> Village:
	var palisade := _cells_matching(rows, [Village.PALISADE])
	if palisade.is_empty():
		return null
	var low := palisade[0]
	var high := palisade[0]
	for cell in palisade:
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	var village := Village.new(Rect2i(low, high - low + Vector2i.ONE))
	village.gates = _cells_matching(rows, [Village.GATE])
	var doorsteps := _cells_matching(rows, [Village.DOORSTEP])
	if not doorsteps.is_empty():
		village.inn_doorstep = doorsteps[0]
	var wells := _cells_matching(rows, [Village.WELL])
	if not wells.is_empty():
		village.well_cell = _middle_of(wells)
	village.buildings = _buildings(rows)
	return village


## Each run of side-by-side cells drawn with one building letter is one building.
func _buildings(rows: PackedStringArray) -> Array[Village.Building]:
	var buildings: Array[Village.Building] = []
	var seen := {}
	for start in _cells_matching(rows, _building_letters()):
		if seen.has(start):
			continue
		var letter: String = rows[start.y][start.x]
		var low := start
		var high := start
		var frontier: Array[Vector2i] = [start]
		seen[start] = true
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
			high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
			for step in NEIGHBOURS:
				var next := cell + step
				if not seen.has(next) and next.x >= 0 and next.y >= 0 and next.y < rows.size() \
						and next.x < rows[next.y].length() and rows[next.y][next.x] == letter:
					seen[next] = true
					frontier.append(next)
		var rect := Rect2i(low, high - low + Vector2i.ONE)
		buildings.append(Village.Building.new(
			Village.kind_of_letter(letter), Village.variant_of_letter(letter), rect, _door_side(rows, rect)))
	return buildings


## The side of a building whose door is on it: the one with the most doorstep cells, which are plain ground with a
## street right behind them.
func _door_side(rows: PackedStringArray, rect: Rect2i) -> Vector2i:
	var best := Vector2i.DOWN
	var best_count := 0
	for side in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT]:
		var count := 0
		for cell in _side_cells(rect, side):
			if _symbol(rows, cell) in [FLOOR, Village.DOORSTEP] and _symbol(rows, cell + side) in [Village.STREET, Village.START]:
				count += 1
		if count > best_count:
			best_count = count
			best = side
	return best


## The cells just outside one side of a rectangle.
func _side_cells(rect: Rect2i, side: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if side.y != 0:
		for x in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, rect.end.y if side.y > 0 else rect.position.y - 1))
	else:
		for y in range(rect.position.y, rect.end.y):
			cells.append(Vector2i(rect.end.x if side.x > 0 else rect.position.x - 1, y))
	return cells


func _symbol(rows: PackedStringArray, cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= rows[cell.y].length():
		return ""
	return rows[cell.y][cell.x]


func _middle_of(cells: Array[Vector2i]) -> Vector2i:
	return DungeonMap.middle_cell(cells)


func _terrain_by_cell(rows: PackedStringArray) -> Dictionary:
	var terrain := {}
	for cell in _cells_matching(rows, [WATER]):
		terrain[cell] = DungeonMap.Terrain.WATER
	for cell in _cells_matching(rows, [LAVA]):
		terrain[cell] = DungeonMap.Terrain.LAVA
	for cell in _cells_matching(rows, [SHALLOW]):
		terrain[cell] = DungeonMap.Terrain.SHALLOW
	for cell in _cells_matching(rows, [Village.STREET, Village.START]):
		terrain[cell] = DungeonMap.Terrain.PATH
	for cell in _cells_matching(rows, [ROAD]):
		terrain[cell] = DungeonMap.Terrain.ROAD
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
