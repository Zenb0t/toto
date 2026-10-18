extends GutTest
## The crypt's trap rooms, from the generator through the real map parser, on many seeds.

const SEEDS := 40

var _parser := DungeonMapParser.new()


func _level(seed_value: int, level: int, crypt := CryptRecipe.new()) -> DungeonMap:
	return _parser.parse(DungeonGenerator.new().generate(seed_value, level, crypt))


func _trap_rooms(map: DungeonMap) -> Array[int]:
	var rooms: Array[int] = []
	for room in map.locking_room_ids():
		if map.locking_kind(room) == LockingRoom.Kind.TRAP:
			rooms.append(room)
	return rooms


func _enemies_in(map: DungeonMap, room: int) -> int:
	return map.enemy_spawns.filter(func(cell: Vector2i) -> bool: return map.room_at(cell) == room).size()


func test_the_first_two_levels_have_exactly_one_trap_room_and_the_last_has_none() -> void:
	for seed_value in SEEDS:
		assert_eq(_trap_rooms(_level(seed_value, 1)).size(), 1, "level 1, seed %d" % seed_value)
		assert_eq(_trap_rooms(_level(seed_value, 2)).size(), 1, "level 2, seed %d" % seed_value)
		assert_eq(_trap_rooms(_level(seed_value, 3)).size(), 0, "level 3, seed %d" % seed_value)


func test_a_trap_room_is_never_the_campfires_the_arrival_or_the_stairs_down_room() -> void:
	for seed_value in SEEDS:
		for level in [1, 2]:
			var map := _level(seed_value, level)
			var trap := _trap_rooms(map)[0]
			var label := "level %d, seed %d" % [level, seed_value]
			assert_ne(trap, map.room_at(map.campfire_cells[0]), "campfire room, " + label)
			assert_ne(trap, map.room_at(map.stairs_up_cell), "start room, " + label)
			assert_ne(trap, map.room_at(map.exit_cell), "stairs down room, " + label)


func test_a_trap_room_holds_a_band_and_no_item_lying_about() -> void:
	for seed_value in SEEDS:
		var map := _level(seed_value, 1)
		var trap := _trap_rooms(map)[0]
		assert_gt(_enemies_in(map, trap), 0, "seed %d" % seed_value)
		for cell in map.loot_cells:
			assert_ne(map.room_at(cell), trap, "seed %d" % seed_value)


func test_a_trap_band_is_bigger_the_deeper_the_knob_sets_it() -> void:
	var usual := CryptRecipe.new()
	usual.trap_band_extra_depth = 0
	var tougher := CryptRecipe.new()
	tougher.trap_band_extra_depth = 4
	var usual_total := 0
	var tougher_total := 0
	for seed_value in SEEDS:
		var weak := _level(seed_value, 1, usual)
		var strong := _level(seed_value, 1, tougher)
		usual_total += _enemies_in(weak, _trap_rooms(weak)[0])
		tougher_total += _enemies_in(strong, _trap_rooms(strong)[0])
	assert_gt(tougher_total, usual_total)


func test_the_trap_band_strength_is_a_tunable_knob() -> void:
	var fields := CryptRecipe.new().knobs().map(func(knob: Knob) -> String: return knob.field)
	assert_has(fields, "trap_band_extra_depth")


func test_the_same_seed_makes_the_same_trap_room() -> void:
	assert_eq(DungeonGenerator.new().generate(7, 2), DungeonGenerator.new().generate(7, 2))


func test_only_the_marked_room_locks_and_a_room_cleared_in_the_record_does_not_lock_again() -> void:
	var map := _level(3, 1)
	var trap := _trap_rooms(map)[0]
	var counts := {}
	for cell in map.enemy_spawns:
		counts[map.room_at(cell)] = counts.get(map.room_at(cell), 0) + 1

	var progress := DungeonProgress.new(counts, map.locking_room_ids())
	for room in map.room_count:
		if room != trap:
			progress.enter_room(room)
	assert_eq(progress.locked_room, DungeonProgress.NO_ROOM, "no unmarked room locks")
	progress.enter_room(trap)
	assert_eq(progress.locked_room, trap)

	counts.erase(trap)  # as main.gd counts a return: nobody of the trap band is left in the record
	var returning := DungeonProgress.new(counts, map.locking_room_ids())
	returning.enter_room(trap)
	assert_eq(returning.locked_room, DungeonProgress.NO_ROOM, "a cleared trap room stays open")


func test_the_trap_slot_is_never_the_start_the_deepest_or_a_taken_slot() -> void:
	for seed_value in SEEDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var graph := RoomGraph.grow(DungeonGenerator.GRID, rng.randi_range(6, 8), 1, rng)
		var taken: Array[Vector2i] = [graph.slots[1]]
		var slot := TrapRoom.slot_for(graph, taken, rng)
		assert_ne(slot, graph.start_slot())
		assert_ne(slot, graph.deepest_slot())
		assert_does_not_have(taken, slot)


func test_only_the_first_two_levels_have_a_trap_room() -> void:
	assert_true(TrapRoom.on_level(1))
	assert_true(TrapRoom.on_level(2))
	assert_false(TrapRoom.on_level(3))
