class_name DungeonGenerator
extends RefCounted
## Builds a random dungeon as an ASCII map (the same format DungeonMapParser reads, so everything that
## works on the hand-made map works here). The same seed always gives the same map.
##
## Rooms of varied shapes sit on a grid of slots (see RoomGraph) and are joined by short, three-wide
## corridors with a door at each end. Some rooms are hand-written set pieces instead (see Vaults), the way
## Dungeon Crawl Stone Soup mixes vaults into its random levels. The player arrives in a quiet room (on the
## stairs up, which lead back out to the mausoleum from the first level); the exit (the stairs down) is in the room
## farthest from it; rooms get tougher the farther they are from the start (see DungeonDifficulty). Each level has a
## campfire in an ordinary room a few rooms from the stairs (see CryptCampfire). The crypt's last level has no
## stairs down: the room farthest from the stairs up is the boss arena instead (see BossArena), marked as a locking
## room, with the Lich in it and nothing else. The first two levels each hold a trap room (see TrapRoom): an
## ordinary-looking room whose band is picked tougher and which carries the trap mark at its middle, where its chest goes.

## Bumped whenever the same seed would make a different map, so a saved MapRecord can tell it no longer fits.
const VERSION := 5

const GRID := Vector2i(4, 3)
## Every slot holds one room plus the gap around it, where corridors run.
const SLOT_SIZE := Vector2i(28, 20)
## Cells between a slot's edge and its room, so neighbouring rooms are always a corridor apart.
const ROOM_MARGIN := 2
const CORRIDOR_HALF_WIDTH := 1
const MIN_ROOMS := 6
const MAX_ROOMS := 8
const MAX_EXTRA_LINKS := 2
const MAX_PILLARS := 4
## Chance that a room (other than the start) is a vault instead of a random shape.
const VAULT_CHANCE := 0.3
## Chance that a dead-end room (one way in) has an item lying on its floor: a reward for exploring.
const DEAD_END_LOOT_CHANCE := 0.5
## Enemies start this many cells clear of a room's edge, so they don't spawn in a doorway.
const SPAWN_EDGE_CLEARANCE := 3

const WALL := "#"
const FLOOR := "."
const DOOR := "+"
const SHALLOW := ","
## Puddles in a wet branch's caves: how many, how big, and how far from the cave's edge.
const MAX_PUDDLES := 3
const PUDDLE_RADIUS := 2
const PUDDLE_EDGE_CLEARANCE := 4
const EXIT := ">"
const STAIRS_UP := "<"
const LOOT := "*"
const CAMPFIRE := "F"
## The slot of a level without a boss arena.
const NO_SLOT := Vector2i(-1, -1)
const NO_CELL := Vector2i(-1, -1)


## floor_number: 1 for the top level; deeper levels hold tougher monsters (see DungeonDifficulty.danger).
## crypt: what the level is made of (the campfire's distance from the stairs). branch: the kind of rooms, vaults and
## monsters (see Branch); the crypt unless a test or a later idea asks for another. The level holds one campfire
## in an ordinary room (see CryptCampfire), clear of monsters (see Camps).
func generate(seed_value: int, floor_number := 1, crypt := CryptRecipe.new(), branch: Branch = null) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var level_branch := branch if branch != null else Branch.crypt()
	var graph := RoomGraph.grow(GRID, rng.randi_range(MIN_ROOMS, MAX_ROOMS), rng.randi_range(0, MAX_EXTRA_LINKS), rng)
	var campfire_slot := CryptCampfire.slot_for(graph, crypt.campfire_rooms_from_stairs, rng)
	var arena_slot := BossArena.slot_for(graph) if floor_number >= CryptRecipe.LEVELS else NO_SLOT
	var taken_slots: Array[Vector2i] = [campfire_slot, arena_slot]
	var trap_slot := TrapRoom.slot_for(graph, taken_slots, rng) if TrapRoom.on_level(floor_number) else NO_SLOT
	var rooms := {}  # slot -> {cell: map symbol}
	for slot in graph.slots:
		var is_start: bool = slot == graph.start_slot()
		var is_vault: bool = not is_start and slot != campfire_slot and slot != arena_slot and slot != trap_slot \
				and rng.randf() < VAULT_CHANCE
		rooms[slot] = _shape_room(is_start, is_vault, room_bounds(slot), level_branch, rng) \
				if slot != arena_slot else _as_floor(BossArena.room(room_bounds(slot)))
	var corridors := _connect(graph, rooms, arena_slot, rng)
	return _draw(graph, rooms, corridors, Slots.new(campfire_slot, arena_slot, trap_slot), floor_number, crypt, level_branch, rng)


## The slots of a level that are not ordinary rooms (NO_SLOT for the ones the level lacks).
class Slots:
	extends RefCounted
	var campfire: Vector2i
	var arena: Vector2i
	var trap: Vector2i

	func _init(campfire_slot: Vector2i, arena_slot: Vector2i, trap_slot: Vector2i) -> void:
		campfire = campfire_slot
		arena = arena_slot
		trap = trap_slot


static func map_size() -> Vector2i:
	return GRID * SLOT_SIZE + Vector2i(2, 2)


## The area a slot's room may use: the slot minus its margin, inside the map's outer wall.
static func room_bounds(slot: Vector2i) -> Rect2i:
	return Rect2i(Vector2i.ONE + slot * SLOT_SIZE, SLOT_SIZE).grow(-ROOM_MARGIN)


## The start room is a plain rectangle. The rest are the branch's vaults (is_vault), natural caves (as many as the
## branch has), or built shapes; caves and built rooms get a few pillars (rocks, in a cave).
func _shape_room(
		is_start: bool, is_vault: bool, bounds: Rect2i, branch: Branch, rng: RandomNumberGenerator) -> Dictionary:
	if is_start:
		return _as_floor(RoomShapes.build(RoomShapes.Kind.RECT, bounds, rng))
	if is_vault:
		return Vaults.stamp(branch.vaults[rng.randi_range(0, branch.vaults.size() - 1)], bounds, rng)
	var is_cave := rng.randf() < branch.cave_share
	var shape := RoomShapes.cave(bounds, rng) if is_cave else RoomShapes.build(RoomShapes.random_kind(rng), bounds, rng)
	var room := _as_floor(RoomShapes.with_pillars(shape, rng.randi_range(0, MAX_PILLARS), rng))
	if is_cave and branch.puddles:
		_add_puddles(room, rng)
	return room


## Shallow water in the middle of a cave, kept away from its edges (so corridors and doorways stay dry).
## Shallow water can be waded through, so the cave stays in one piece.
func _add_puddles(room: Dictionary, rng: RandomNumberGenerator) -> void:
	var inner: Array[Vector2i] = []
	for cell: Vector2i in room:
		if _clear_of_edge(cell, room, PUDDLE_EDGE_CLEARANCE):
			inner.append(cell)
	for _i in rng.randi_range(1, MAX_PUDDLES):
		if inner.is_empty():
			return
		var center: Vector2i = inner[rng.randi_range(0, inner.size() - 1)]
		for dy in range(-PUDDLE_RADIUS, PUDDLE_RADIUS + 1):
			for dx in range(-PUDDLE_RADIUS, PUDDLE_RADIUS + 1):
				var cell := center + Vector2i(dx, dy)
				if Vector2(dx, dy).length() <= PUDDLE_RADIUS + 0.4 and room.get(cell) == FLOOR:
					room[cell] = SHALLOW


func _as_floor(cells: Dictionary) -> Dictionary:
	var floor_plan := {}
	for cell: Vector2i in cells:
		floor_plan[cell] = FLOOR
	return floor_plan


## Corridors for every link, as {cell: FLOOR or DOOR}. A link that finds no straight, sealed spot between
## two odd shapes makes them plain rectangles (the boss arena keeps its shape), and the corridors are laid again.
func _connect(graph: RoomGraph, rooms: Dictionary, arena_slot: Vector2i, rng: RandomNumberGenerator) -> Dictionary:
	while true:
		var corridors := {}
		var failed: Array = []
		for link: Array in graph.links:
			var corridor := _corridor(link[0], link[1], rooms)
			if corridor.is_empty():
				failed = link
				break
			corridors.merge(corridor)
		if failed.is_empty():
			return corridors
		for slot: Vector2i in failed:
			if slot != arena_slot:
				rooms[slot] = _as_floor(RoomShapes.build(RoomShapes.Kind.RECT, room_bounds(slot), rng))
	return {}


## A three-wide corridor straight across the gap between two neighbouring rooms, or empty if there is no
## spot where both rooms have a straight wall facing each other and the corridor touches no other floor.
func _corridor(a: Vector2i, b: Vector2i, rooms: Dictionary) -> Dictionary:
	var horizontal := a.y == b.y
	var a_comes_first := a.x < b.x if horizontal else a.y < b.y
	var first: Dictionary = rooms[a] if a_comes_first else rooms[b]
	var second: Dictionary = rooms[b] if a_comes_first else rooms[a]
	for across in _shared_lines(first, second, horizontal):
		var corridor := _corridor_at(across, first, second, horizontal, rooms)
		if not corridor.is_empty():
			return corridor
	return {}


## Lines (rows for side-by-side rooms, columns for stacked ones) both rooms reach, middle ones first.
func _shared_lines(first: Dictionary, second: Dictionary, horizontal: bool) -> Array[int]:
	var in_first := {}
	for cell: Vector2i in first:
		in_first[_across(cell, horizontal)] = true
	var shared: Array[int] = []
	for cell: Vector2i in second:
		var line := _across(cell, horizontal)
		if in_first.has(line) and line not in shared:
			shared.append(line)
	if shared.is_empty():
		return shared
	var middle: float = (shared.min() + shared.max()) / 2.0
	shared.sort_custom(func(p: int, q: int) -> bool: return absf(p - middle) < absf(q - middle))
	return shared


func _corridor_at(across: int, first: Dictionary, second: Dictionary, horizontal: bool, rooms: Dictionary) -> Dictionary:
	var lines := range(across - CORRIDOR_HALF_WIDTH, across + CORRIDOR_HALF_WIDTH + 1)
	var start_edges := lines.map(func(line: int) -> int: return _far_edge(first, line, horizontal))
	var end_edges := lines.map(func(line: int) -> int: return _near_edge(second, line, horizontal))
	if start_edges.has(null) or end_edges.has(null):
		return {}
	if start_edges.min() != start_edges.max() or end_edges.min() != end_edges.max():
		return {}
	var door_a: int = start_edges[0] + 1
	var door_b: int = end_edges[0] - 1
	if door_b - door_a < 2:
		return {}
	var corridor := {}
	for line: int in lines:
		for along in range(door_a, door_b + 1):
			corridor[_cell(along, line, horizontal)] = DOOR if along == door_a or along == door_b else FLOOR
	# Sealed: the corridor's own floor must not sit next to any room's floor (only its doors may).
	for along in range(door_a + 1, door_b):
		for side in [lines[0] - 1, lines[-1] + 1]:
			if _in_any_room(_cell(along, side, horizontal), rooms):
				return {}
	return corridor


func _draw(
		graph: RoomGraph, rooms: Dictionary, corridors: Dictionary, special: Slots, floor_number: int,
		crypt: CryptRecipe, branch: Branch, rng: RandomNumberGenerator
) -> String:
	var campfire_slot := special.campfire
	var arena_slot := special.arena
	var size := map_size()
	var rows: Array[Array] = []
	for y in size.y:
		var row := []
		row.resize(size.x)
		row.fill(WALL)
		rows.append(row)
	for slot in graph.slots:
		for cell: Vector2i in rooms[slot]:
			rows[cell.y][cell.x] = rooms[slot][cell]
	for cell: Vector2i in corridors:
		rows[cell.y][cell.x] = corridors[cell]
	var start_center := _center_cell(rooms[graph.start_slot()])
	rows[start_center.y][start_center.x] = STAIRS_UP
	var exit_cell := NO_CELL
	if arena_slot == NO_SLOT:
		exit_cell = _exit_cell(rooms[graph.deepest_slot()])
		rows[exit_cell.y][exit_cell.x] = EXIT
	else:
		_place_arena(rows, room_bounds(arena_slot))
	for slot in graph.slots:
		if slot == graph.start_slot() or slot == arena_slot:
			continue
		var taken: Array[Vector2i] = []
		if exit_cell != NO_CELL:
			taken.append(exit_cell)
		var fires: Array[Vector2i] = []
		if slot == campfire_slot:
			fires = _spawn_cells(rooms[slot], 1, taken, [], rng)
			rows[fires[0].y][fires[0].x] = CAMPFIRE
			taken.append(fires[0])
		if slot != special.trap and _hides_loot(slot, graph, rooms[slot], rng):
			var loot_cell := _spawn_cells(rooms[slot], 1, taken, [], rng)[0]
			rows[loot_cell.y][loot_cell.x] = LOOT
			taken.append(loot_cell)
		var danger := DungeonDifficulty.danger(graph.depth_of(slot), floor_number)
		var depth := TrapRoom.band_depth(danger, crypt.trap_band_extra_depth) if slot == special.trap \
				else DungeonDifficulty.rolled_depth(danger, rng)
		var letters := DungeonDifficulty.enemy_letters(depth, rng, branch.favoured)
		for cell in _spawn_cells(rooms[slot], letters.size(), taken, fires, rng):
			rows[cell.y][cell.x] = letters.pop_back()
		if slot == special.trap:
			var chest_cell := _center_cell(rooms[slot])
			rows[chest_cell.y][chest_cell.x] = LockingRoom.mark_of(LockingRoom.Kind.TRAP)
	return "\n".join(rows.map(func(row: Array) -> String: return "".join(PackedStringArray(row))))


## The Lich in his crypt, and the mark that makes the arena a locking room.
func _place_arena(rows: Array[Array], bounds: Rect2i) -> void:
	var lich := BossArena.lich_cell(bounds)
	rows[lich.y][lich.x] = Lich.LETTER
	var mark := BossArena.mark_cell(bounds)
	rows[mark.y][mark.x] = LockingRoom.mark_of(LockingRoom.Kind.ARENA)


## Dead ends (other than the exit's room) sometimes hide an item, unless they are vaults with treasure of their own.
func _hides_loot(slot: Vector2i, graph: RoomGraph, room: Dictionary, rng: RandomNumberGenerator) -> bool:
	if slot == graph.deepest_slot() or graph.link_count(slot) != 1 or LOOT in room.values():
		return false
	return rng.randf() < DEAD_END_LOOT_CHANCE


## The exit sits in the corner of its room farthest from the middle, clear of the walls.
func _exit_cell(room: Dictionary) -> Vector2i:
	var area := _main_area(room)
	var middle := _center_cell(room)
	var farthest := middle
	for cell: Vector2i in area:
		if room[cell] == FLOOR and _clear_of_edge(cell, area, 1) \
				and cell.distance_squared_to(middle) > farthest.distance_squared_to(middle):
			farthest = cell
	return farthest


## Random cells away from the room's edge and its middle, spread a little apart, and farther than a camp's
## radius from every cell in `clear_of` (campfires: a monster that close would make the campfire a camp's home,
## see Camps). Narrow or crowded rooms let enemies start closer to the walls rather than leave anyone out.
func _spawn_cells(
		room: Dictionary, count: int, taken: Array[Vector2i], clear_of: Array[Vector2i], rng: RandomNumberGenerator
) -> Array[Vector2i]:
	var chosen: Array[Vector2i] = []
	for clearance in range(SPAWN_EDGE_CLEARANCE, 0, -1):
		chosen = _spread_cells(room, count, clearance, taken, clear_of, rng)
		if chosen.size() == count:
			break
	return chosen


func _spread_cells(
		room: Dictionary, count: int, clearance: int, taken: Array[Vector2i], clear_of: Array[Vector2i],
		rng: RandomNumberGenerator
) -> Array[Vector2i]:
	var area := _main_area(room)
	var middle := _center_cell(room)
	var candidates: Array[Vector2i] = []
	for cell: Vector2i in area:
		if room[cell] == FLOOR and cell != middle and cell not in taken and _clear_of_edge(cell, area, clearance) \
				and clear_of.all(func(fire: Vector2i) -> bool: return not _near(cell, fire)):
			candidates.append(cell)
	var chosen: Array[Vector2i] = []
	while chosen.size() < count and not candidates.is_empty():
		var cell: Vector2i = candidates.pop_at(rng.randi_range(0, candidates.size() - 1))
		if chosen.all(func(other: Vector2i) -> bool: return other.distance_to(cell) >= 3.0):
			chosen.append(cell)
	return chosen


## Whether a cell is within a camp's radius (either way) of another.
func _near(cell: Vector2i, other: Vector2i) -> bool:
	var apart := (cell - other).abs()
	return maxi(apart.x, apart.y) <= Camps.RADIUS_CELLS


func _clear_of_edge(cell: Vector2i, area: Dictionary, clearance: int) -> bool:
	for y in range(-clearance, clearance + 1):
		for x in range(-clearance, clearance + 1):
			if not area.has(cell + Vector2i(x, y)):
				return false
	return true


## The room's middle: the same rule DungeonMap.room_center (where a chest goes) uses on the parsed room.
func _center_cell(room: Dictionary) -> Vector2i:
	var area := _main_area(room)
	return DungeonMap.middle_cell(area.keys().filter(func(cell: Vector2i) -> bool: return room[cell] == FLOOR))


## The room as the map parser will see it: its largest piece, without anything a door shuts off (like a vault's
## closet). Water and lava are part of it.
func _main_area(room: Dictionary) -> Dictionary:
	var unvisited := {}
	for cell: Vector2i in room:
		if room[cell] != DOOR:
			unvisited[cell] = true
	var largest := {}
	while not unvisited.is_empty():
		var piece := _piece_from(unvisited.keys()[0], unvisited)
		if piece.size() > largest.size():
			largest = piece
	return largest


## Takes the connected piece containing start out of cells, and returns it.
func _piece_from(start: Vector2i, cells: Dictionary) -> Dictionary:
	var piece := {start: true}
	cells.erase(start)
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if cells.has(next):
				cells.erase(next)
				piece[next] = true
				frontier.append(next)
	return piece


func _in_any_room(cell: Vector2i, rooms: Dictionary) -> bool:
	return rooms.values().any(func(room: Dictionary) -> bool: return room.has(cell))


## The last cell of a line inside the room, toward the next room (null if the room doesn't reach the line).
func _far_edge(room: Dictionary, line: int, horizontal: bool) -> Variant:
	var edge: Variant = null
	for cell: Vector2i in room:
		if _across(cell, horizontal) == line:
			edge = _along(cell, horizontal) if edge == null else maxi(edge, _along(cell, horizontal))
	return edge


## The first cell of a line inside the room, coming from the previous room.
func _near_edge(room: Dictionary, line: int, horizontal: bool) -> Variant:
	var edge: Variant = null
	for cell: Vector2i in room:
		if _across(cell, horizontal) == line:
			edge = _along(cell, horizontal) if edge == null else mini(edge, _along(cell, horizontal))
	return edge


## Side-by-side rooms are joined along x and lined up on y; stacked rooms the other way round.
func _along(cell: Vector2i, horizontal: bool) -> int:
	return cell.x if horizontal else cell.y


func _across(cell: Vector2i, horizontal: bool) -> int:
	return cell.y if horizontal else cell.x


func _cell(along: int, across: int, horizontal: bool) -> Vector2i:
	return Vector2i(along, across) if horizontal else Vector2i(across, along)
