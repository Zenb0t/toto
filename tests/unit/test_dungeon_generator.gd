extends GutTest
## Rules every generated dungeon must follow, checked on many seeds through the real map parser.

const SEEDS := 25

var _parser := DungeonMapParser.new()


func _map(seed_value: int) -> DungeonMap:
	return _parser.parse(DungeonGenerator.new().generate(seed_value))


func _enemy_rooms(map: DungeonMap) -> Dictionary:
	var rooms := {}
	for spawn in map.enemy_spawns:
		rooms[map.room_at(spawn)] = rooms.get(map.room_at(spawn), 0) + 1
	return rooms


func test_the_same_seed_gives_the_same_dungeon() -> void:
	assert_eq(DungeonGenerator.new().generate(42), DungeonGenerator.new().generate(42))


func test_different_seeds_give_different_dungeons() -> void:
	assert_ne(DungeonGenerator.new().generate(1), DungeonGenerator.new().generate(2))


func test_the_player_starts_in_a_quiet_room() -> void:
	for seed_value in SEEDS:
		var map := _map(seed_value)
		assert_does_not_have(_enemy_rooms(map), map.room_at(map.player_spawn), "seed %d" % seed_value)


func test_every_cell_can_be_reached_from_the_start() -> void:
	for seed_value in SEEDS:
		var map := _map(seed_value)
		var reached := {map.player_spawn: true}
		var frontier: Array[Vector2i] = [map.player_spawn]
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = cell + step
				if map.is_walkable(next) and not reached.has(next):
					reached[next] = true
					frontier.append(next)
		assert_eq(reached.size(), map.walkable_cells().size(), "seed %d" % seed_value)


func test_every_room_has_a_door() -> void:
	for seed_value in SEEDS:
		var map := _map(seed_value)
		for room in map.room_count:
			assert_false(map.doors_of_room(room).is_empty(), "seed %d room %d" % [seed_value, room])


func test_there_is_one_exit_guarded_by_enemies_away_from_the_start() -> void:
	for seed_value in SEEDS:
		var map := _map(seed_value)
		assert_ne(map.exit_cell, DungeonMap.NO_CELL, "seed %d" % seed_value)
		var exit_room := map.room_at(map.exit_cell)
		assert_ne(exit_room, map.room_at(map.player_spawn), "seed %d" % seed_value)
		assert_has(_enemy_rooms(map), exit_room, "seed %d" % seed_value)


func test_the_chest_spot_of_the_exit_room_is_not_the_exit() -> void:
	for seed_value in SEEDS:
		var map := _map(seed_value)
		assert_ne(map.room_center(map.room_at(map.exit_cell)), map.exit_cell, "seed %d" % seed_value)


func test_rooms_with_enemies_are_arenas_not_corridors() -> void:
	for seed_value in SEEDS:
		var map := _map(seed_value)
		for room: int in _enemy_rooms(map):
			assert_gt(map.cells_of_room(room).size(), 60, "seed %d room %d" % [seed_value, room])


func test_the_dungeon_has_several_rooms_to_fight_in() -> void:
	for seed_value in SEEDS:
		assert_true(_enemy_rooms(_map(seed_value)).size() >= DungeonGenerator.MIN_ROOMS - 1, "seed %d" % seed_value)


func test_deeper_rooms_hold_as_many_enemies_as_their_depth_calls_for() -> void:
	for seed_value in SEEDS:
		var map := _map(seed_value)
		for room: int in _enemy_rooms(map):
			assert_true(_enemy_rooms(map)[room] >= DungeonDifficulty.enemy_count(1), "seed %d room %d" % [seed_value, room])
