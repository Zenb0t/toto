extends GutTest
## The crypt's last level holds the boss arena: a locking room with four pillars and the Lich in his crypt at the
## front. Checked on many seeds through the real map parser.

const SEEDS := 40
const LAST := WorldLayout.FLOOR_COUNT

var _parser := DungeonMapParser.new()


func _level(seed_value: int, level := LAST) -> DungeonMap:
	return _parser.parse(DungeonGenerator.new().generate(seed_value, level))


func _lich_cells(map: DungeonMap) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for spawn in map.enemy_spawns:
		if map.monster_at(spawn) == Lich.ID:
			cells.append(spawn)
	return cells


func _arena_of(map: DungeonMap) -> int:
	return map.locking_room_of_kind(LockingRoom.Kind.ARENA)


func _reachable_from(map: DungeonMap, start: Vector2i) -> Dictionary:
	var reached := {start: true}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if map.is_walkable(next) and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	return reached


## Blocks of wall standing inside the room, not part of its outer wall: pillars.
func _pillars_in(map: DungeonMap, room: int) -> int:
	var cells := map.cells_of_room(room)
	var low := cells[0]
	var high := cells[0]
	for cell in cells:
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	var seen := {}
	var pillars := 0
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var start := Vector2i(x, y)
			if seen.has(start) or map.is_open(start):
				continue
			var touches_outside := false
			var frontier: Array[Vector2i] = [start]
			seen[start] = true
			while not frontier.is_empty():
				var cell: Vector2i = frontier.pop_back()
				for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = cell + step
					if next.x < low.x or next.y < low.y or next.x > high.x or next.y > high.y:
						touches_outside = true
					elif not map.is_open(next) and not seen.has(next):
						seen[next] = true
						frontier.append(next)
			if not touches_outside:
				pillars += 1
	return pillars


func test_the_last_level_has_one_boss_arena_with_the_lich_in_it() -> void:
	for seed_value in SEEDS:
		var map := _level(seed_value)
		var at := "seed %d" % seed_value

		assert_eq(map.locking_room_ids().size(), 1, at)
		assert_ne(_arena_of(map), DungeonMap.NO_ROOM, at)
		assert_eq(_lich_cells(map).size(), 1, at)
		assert_eq(map.room_at(_lich_cells(map)[0]), _arena_of(map), at)


func test_the_arena_has_four_pillars() -> void:
	for seed_value in SEEDS:
		var map := _level(seed_value)

		assert_eq(_pillars_in(map, _arena_of(map)), BossArena.PILLAR_COUNT, "seed %d" % seed_value)


func test_the_lich_waits_alone_in_his_arena() -> void:
	for seed_value in SEEDS:
		var map := _level(seed_value)
		var others := map.enemy_spawns.filter(
			func(cell: Vector2i) -> bool: return map.room_at(cell) == _arena_of(map) and map.monster_at(cell) != Lich.ID)

		assert_eq(others.size(), 0, "seed %d" % seed_value)


func test_the_arena_can_be_walked_to_from_the_stairs_up() -> void:
	for seed_value in SEEDS:
		var map := _level(seed_value)
		var reached := _reachable_from(map, map.player_spawn)

		assert_true(reached.has(_lich_cells(map)[0]), "seed %d" % seed_value)
		assert_eq(reached.size(), map.walkable_cells().size(), "seed %d: every cell can be reached" % seed_value)


func test_the_arena_is_never_the_start_room_a_campfire_room_or_a_trap_room() -> void:
	for seed_value in SEEDS:
		var map := _level(seed_value)
		var arena := _arena_of(map)
		var at := "seed %d" % seed_value

		assert_ne(arena, map.room_at(map.stairs_up_cell), at)
		assert_ne(arena, map.room_at(map.campfire_cells[0]), at)
		assert_eq(map.locking_kind(arena), LockingRoom.Kind.ARENA, at)
		assert_eq(map.locking_room_of_kind(LockingRoom.Kind.TRAP), DungeonMap.NO_ROOM, at)


func test_the_last_level_has_no_stairs_down_but_still_stairs_up_and_a_campfire() -> void:
	for seed_value in SEEDS:
		var map := _level(seed_value)

		assert_eq(map.exit_cell, DungeonMap.NO_CELL, "seed %d" % seed_value)
		assert_ne(map.stairs_up_cell, DungeonMap.NO_CELL, "seed %d" % seed_value)
		assert_eq(map.campfire_cells.size(), 1, "seed %d" % seed_value)


func test_the_earlier_levels_have_no_arena_and_no_lich() -> void:
	for seed_value in SEEDS:
		for level in range(1, LAST):
			var map := _level(seed_value, level)

			assert_eq(map.locking_room_of_kind(LockingRoom.Kind.ARENA), DungeonMap.NO_ROOM, "seed %d level %d" % [seed_value, level])
			assert_true(_lich_cells(map).is_empty(), "seed %d level %d" % [seed_value, level])


func test_the_arena_is_a_big_hall_with_his_crypt_at_the_front() -> void:
	for seed_value in SEEDS:
		var map := _level(seed_value)
		var lich := _lich_cells(map)[0]
		var cells := map.cells_of_room(_arena_of(map))
		var rows: Array = cells.map(func(cell: Vector2i) -> int: return cell.y)
		# The crypt is at the north end, or the south end when a corridor comes from the north.
		var from_the_end: int = mini(lich.y - rows.min(), rows.max() - lich.y)

		assert_gt(cells.size(), 250, "seed %d" % seed_value)
		assert_lt(from_the_end, BossArena.CRYPT_SIZE.y, "seed %d: he stands in the recess at the front" % seed_value)


func test_the_arena_is_made_the_same_way_every_time() -> void:
	assert_eq(DungeonGenerator.new().generate(5, LAST), DungeonGenerator.new().generate(5, LAST))


func test_a_locking_mark_makes_a_room_lock_and_other_rooms_never_do() -> void:
	var map := _parser.parse("""
#########
#P..#R..#
#...+...#
#########
""".strip_edges())

	assert_eq(map.locking_room_ids().size(), 1)
	assert_eq(map.locking_kind(map.room_at(Vector2i(6, 1))), LockingRoom.Kind.TRAP)
	assert_eq(map.locking_kind(map.room_at(Vector2i(1, 1))), LockingRoom.NONE)


func test_the_crypt_turns_its_back_on_a_corridor_that_comes_from_the_north() -> void:
	var graph := RoomGraph.new()
	var arena := Vector2i(1, 1)
	graph.slots = [Vector2i(1, 0), arena, Vector2i(2, 1)]
	graph.links = [[Vector2i(1, 0), arena], [arena, Vector2i(2, 1)]]

	assert_true(BossArena.faces_south(graph, arena), "a room above it: the crypt faces south")
	graph.links = [[arena, Vector2i(2, 1)]]
	assert_false(BossArena.faces_south(graph, arena))


func test_the_mirrored_arena_has_the_same_floor_with_the_crypt_at_the_other_end() -> void:
	var bounds := Rect2i(2, 2, 24, 18)
	var north := BossArena.room(bounds)
	var south := BossArena.room(bounds, true)

	assert_eq(south.size(), north.size())
	assert_lt(BossArena.lich_cell(bounds).y, bounds.position.y + bounds.size.y / 2)
	assert_gt(BossArena.lich_cell(bounds, true).y, bounds.position.y + bounds.size.y / 2)
	assert_true(south.has(BossArena.lich_cell(bounds, true)))
