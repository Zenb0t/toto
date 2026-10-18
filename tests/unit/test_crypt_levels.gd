extends GutTest
## The crypt: three levels, each with stairs both ways and one campfire, bands that are asleep or wandering.
## Checked on many seeds through the real map parser.

const SEEDS := 30

var _parser := DungeonMapParser.new()


func _level(seed_value: int, level: int, crypt := CryptRecipe.new()) -> DungeonMap:
	return _parser.parse(DungeonGenerator.new().generate(seed_value, level, crypt))


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


func _rooms_from_stairs(map: DungeonMap, room: int) -> int:
	# Rooms apart, by doors: breadth first over the rooms the doors join.
	var start := map.room_at(map.stairs_up_cell)
	var apart := {start: 0}
	var frontier: Array[int] = [start]
	while not frontier.is_empty():
		var here: int = frontier.pop_front()
		for next in _neighbouring_rooms(map, here):
			if not apart.has(next):
				apart[next] = apart[here] + 1
				frontier.append(next)
	return apart[room]


## Corridors between doors are small rooms of the map; a real room is bigger than this.
const REAL_ROOM_CELLS := 40


## The real rooms a room opens onto: the ones reached by walking out of it through corridors alone.
func _neighbouring_rooms(map: DungeonMap, room: int) -> Array[int]:
	var neighbours: Array[int] = []
	var seen := {}
	var is_corridor := {}  # room -> bool
	var frontier: Array[Vector2i] = map.cells_of_room(room)
	for cell in frontier:
		seen[cell] = true
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or not map.is_walkable(next):
				continue
			var other := map.room_at(next)
			if not is_corridor.has(other):
				is_corridor[other] = map.cells_of_room(other).size() < REAL_ROOM_CELLS
			if is_corridor[other]:
				seen[next] = true
				frontier.append(next)
			elif other != room and other not in neighbours:
				neighbours.append(other)
	return neighbours


func test_the_crypt_has_three_levels_behind_the_crypt_entrance() -> void:
	assert_eq(WorldLayout.FLOOR_COUNT, 3)
	assert_eq(WorldLayout.map_ids().size(), 4, "the plains and three levels")
	for level in range(1, WorldLayout.FLOOR_COUNT + 1):
		assert_eq(WorldLayout.spec(5, WorldLayout.floor_id(level)).place_name(), "Crypt level %d" % level)


func test_every_level_has_stairs_up_and_down_in_different_rooms() -> void:
	for seed_value in SEEDS:
		for level in range(1, WorldLayout.FLOOR_COUNT + 1):
			var map := _level(seed_value, level)
			var at := "seed %d level %d" % [seed_value, level]

			assert_ne(map.stairs_up_cell, DungeonMap.NO_CELL, at)
			assert_ne(map.exit_cell, DungeonMap.NO_CELL, at)
			assert_ne(map.room_at(map.stairs_up_cell), map.room_at(map.exit_cell), at)


func test_every_level_has_exactly_one_campfire_that_can_be_walked_to() -> void:
	for seed_value in SEEDS:
		for level in range(1, WorldLayout.FLOOR_COUNT + 1):
			var map := _level(seed_value, level)
			var at := "seed %d level %d" % [seed_value, level]

			assert_eq(map.campfire_cells.size(), 1, at)
			assert_true(_reachable_from(map, map.player_spawn).has(map.campfire_cells[0]), at)


func test_the_campfire_is_in_neither_the_arrival_room_nor_the_exit_room() -> void:
	for seed_value in SEEDS:
		for level in range(1, WorldLayout.FLOOR_COUNT + 1):
			var map := _level(seed_value, level)
			var room := map.room_at(map.campfire_cells[0])
			var at := "seed %d level %d" % [seed_value, level]

			assert_ne(room, DungeonMap.NO_ROOM, at)
			assert_ne(room, map.room_at(map.stairs_up_cell), at)
			assert_ne(room, map.room_at(map.exit_cell), at)


func test_the_campfire_lies_the_wanted_number_of_rooms_from_the_stairs_when_the_level_has_such_a_room() -> void:
	var exact := 0
	for seed_value in SEEDS:
		var crypt := CryptRecipe.new()
		crypt.campfire_rooms_from_stairs = 2
		var map := _level(seed_value, 1, crypt)
		var apart := _rooms_from_stairs(map, map.room_at(map.campfire_cells[0]))
		assert_between(apart, 1, 3, "seed %d" % seed_value)
		if apart == 2:
			exact += 1
	assert_gt(exact, SEEDS / 2, "most levels have a room two rooms from the stairs")


func test_a_farther_campfire_distance_puts_the_campfire_deeper_on_average() -> void:
	var near_total := 0
	var far_total := 0
	for seed_value in SEEDS:
		var near := CryptRecipe.new()
		near.campfire_rooms_from_stairs = 1
		var far := CryptRecipe.new()
		far.campfire_rooms_from_stairs = 4
		var near_map := _level(seed_value, 1, near)
		var far_map := _level(seed_value, 1, far)
		near_total += _rooms_from_stairs(near_map, near_map.room_at(near_map.campfire_cells[0]))
		far_total += _rooms_from_stairs(far_map, far_map.room_at(far_map.campfire_cells[0]))

	assert_gt(far_total, near_total)


func test_no_monster_stands_close_enough_to_make_the_campfire_a_camp() -> void:
	for seed_value in SEEDS:
		for level in range(1, WorldLayout.FLOOR_COUNT + 1):
			var map := _level(seed_value, level)
			for spawn in map.enemy_spawns:
				assert_eq(Camps.campfire_of(map, spawn), DungeonMap.NO_CELL, "seed %d level %d" % [seed_value, level])
			assert_eq(Camps.lone_campfires(map), map.campfire_cells, "a lone campfire, ready to rest at")


func test_the_campfire_room_still_holds_monsters_on_most_levels() -> void:
	var guarded := 0
	var levels := 0
	for seed_value in SEEDS:
		var map := _level(seed_value, 2)
		var room := map.room_at(map.campfire_cells[0])
		levels += 1
		if map.enemy_spawns.any(func(spawn: Vector2i) -> bool: return map.room_at(spawn) == room):
			guarded += 1
	assert_gt(guarded, levels * 3 / 4)


func test_the_same_seed_and_recipe_make_the_same_level() -> void:
	var crypt := CryptRecipe.new()
	crypt.campfire_rooms_from_stairs = 4

	assert_eq(DungeonGenerator.new().generate(9, 2, crypt), DungeonGenerator.new().generate(9, 2, crypt))


func test_crypt_bands_start_mostly_asleep_a_few_wander_and_none_is_awake() -> void:
	var crypt := CryptRecipe.new()
	var asleep := 0
	var wandering := 0
	for seed_value in SEEDS:
		var map := _level(seed_value, 1)
		var bands := {}
		for spawn in map.enemy_spawns:
			var home := Band.home_of(map, spawn, crypt.wandering_share, 0.5)
			bands[home.id] = home
		for id: int in bands:
			match Band.start_of(seed_value, id, bands[id].wandering_share):
				Band.Start.ASLEEP:
					asleep += 1
				Band.Start.WANDERING:
					wandering += 1
				_:
					fail_test("a band starts awake")

	assert_gt(wandering, 0, "a few patrols")
	assert_gt(asleep, wandering * 3, "mostly asleep")


func test_the_wandering_share_knob_decides_how_many_crypt_bands_wander() -> void:
	var map := _level(3, 1)
	var homes: Array[Band.Home] = []
	for spawn in map.enemy_spawns:
		homes.append(Band.home_of(map, spawn, 1.0, 0.0))

	for home in homes:
		assert_eq(Band.start_of(7, home.id, home.wandering_share), Band.Start.WANDERING)
	var quiet := CryptRecipe.new()
	quiet.wandering_share = 0.0
	for home in homes:
		assert_eq(Band.start_of(7, home.id, quiet.wandering_share), Band.Start.ASLEEP)


func test_the_crypt_specs_hand_their_recipe_to_the_levels_it_makes() -> void:
	var crypt := CryptRecipe.new()
	crypt.campfire_rooms_from_stairs = 5
	crypt.wandering_share = 0.4

	var spec := WorldLayout.spec(11, WorldLayout.floor_id(2), QuadrantRecipe.plains(), crypt)

	assert_eq(spec.room_wandering_share(), 0.4)
	assert_eq(spec.ascii(), DungeonGenerator.new().generate(spec.seed_value, 2, crypt))


func test_the_plains_are_named_the_plains() -> void:
	assert_eq(WorldLayout.spec(11, WorldLayout.PLAINS_ID).place_name(), "The plains")
