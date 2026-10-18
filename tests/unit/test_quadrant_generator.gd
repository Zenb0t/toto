extends GutTest
## Rules every generated plains must follow, checked on many seeds through the real map parser.

const SEEDS := 20

var _parser := DungeonMapParser.new()
var _recipe := QuadrantRecipe.plains()
var _ascii_by_seed := {}  # int -> String
var _map_by_seed := {}  # int -> DungeonMap


func before_all() -> void:
	for seed_value in SEEDS:
		_ascii_by_seed[seed_value] = QuadrantGenerator.new().generate(_recipe, seed_value)
		_map_by_seed[seed_value] = _parser.parse(_ascii_by_seed[seed_value])


## Every cell the hero can walk to from the start.
func _reachable(map: DungeonMap) -> Dictionary:
	var reached := {map.player_spawn: true}
	var frontier: Array[Vector2i] = [map.player_spawn]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in DungeonMapParser.NEIGHBOURS:
			var next: Vector2i = cell + step
			if map.is_walkable(next) and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	return reached


func test_the_same_seed_gives_the_same_plains() -> void:
	assert_eq(QuadrantGenerator.new().generate(_recipe, 3), _ascii_by_seed[3])


func test_different_seeds_give_different_plains() -> void:
	assert_ne(_ascii_by_seed[0], _ascii_by_seed[1])


func test_the_plains_are_160_by_90_cells_by_default() -> void:
	for seed_value in SEEDS:
		assert_eq(_map_by_seed[seed_value].size, Vector2i(160, 90), "seed %d" % seed_value)


func test_the_hero_starts_in_the_village_by_the_inns_doorstep() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_true(map.is_in_village(map.player_spawn), "seed %d" % seed_value)
		var step := (map.player_spawn - map.village.inn_doorstep).abs()
		assert_eq(step.x + step.y, 1, "one step from the doorstep, seed %d" % seed_value)


func test_every_walkable_cell_can_be_reached_from_the_start() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_eq(_reachable(map).size(), map.walkable_cells().size(), "seed %d" % seed_value)


func test_at_least_seventy_percent_of_the_ground_inside_the_border_can_be_walked() -> void:
	var inside := _recipe.interior()
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var walkable := 0
		for y in range(inside.position.y, inside.end.y):
			for x in range(inside.position.x, inside.end.x):
				if map.is_walkable(Vector2i(x, y)):
					walkable += 1
		assert_gte(float(walkable) / (inside.size.x * inside.size.y), 0.7, "seed %d" % seed_value)


func test_there_are_groves_boulders_and_ponds() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_gt(map.cells_with_blocker(DungeonMap.Blocker.GROVE).size(), 1000, "groves, seed %d" % seed_value)
		assert_gt(map.cells_with_blocker(DungeonMap.Blocker.BOULDER).size(), 0, "boulders, seed %d" % seed_value)
		assert_gt(map.cells_with(DungeonMap.Terrain.WATER).size(), 0, "ponds, seed %d" % seed_value)
		assert_gt(map.cells_with(DungeonMap.Terrain.SHALLOW).size(), 0, "shores, seed %d" % seed_value)


func test_the_village_stands_in_the_middle_of_the_plains_with_a_gate_on_each_side() -> void:
	for seed_value in SEEDS:
		var village: Village = _map_by_seed[seed_value].village
		assert_eq(village.area.get_center(), Vector2i(80, 45), "seed %d" % seed_value)
		assert_gte(village.area.size.x, 36, "seed %d" % seed_value)
		assert_eq(village.gates.size(), 12, "three cells for each of the four gates, seed %d" % seed_value)


func test_open_grass_surrounds_the_palisade() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for cell in _ring_around(map.village.area):
			assert_true(map.is_walkable(cell), "seed %d cell %s" % [seed_value, cell])


func _ring_around(area: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(area.position.x - 1, area.end.x + 1):
		cells.append(Vector2i(x, area.position.y - 1))
		cells.append(Vector2i(x, area.end.y))
	for y in range(area.position.y, area.end.y):
		cells.append(Vector2i(area.position.x - 1, y))
		cells.append(Vector2i(area.end.x, y))
	return cells


func test_a_forest_border_closes_the_edge_but_for_the_four_exits() -> void:
	var thickness := _recipe.border_thickness
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var open_in_border := 0
		for y in map.size.y:
			for x in map.size.x:
				var on_border := minf(minf(x, y), minf(map.size.x - 1 - x, map.size.y - 1 - y)) < thickness
				if on_border and map.is_walkable(Vector2i(x, y)):
					open_in_border += 1
		var lane_cells_per_exit := QuadrantRecipe.EXIT_WIDTH * (thickness - 1)  # the outermost row is the barricade
		assert_eq(open_in_border, 4 * lane_cells_per_exit, "seed %d" % seed_value)


func test_each_side_has_a_barricaded_exit_in_the_middle_of_it() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var barricades := map.cells_with_blocker(DungeonMap.Blocker.BARRICADE)
		assert_eq(barricades.size(), 4 * QuadrantRecipe.EXIT_WIDTH, "seed %d" % seed_value)
		for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var on_side := barricades.filter(func(cell: Vector2i) -> bool:
				return cell.y == 0 if side == Vector2i.UP else cell.y == map.size.y - 1 if side == Vector2i.DOWN \
					else cell.x == 0 if side == Vector2i.LEFT else cell.x == map.size.x - 1)
			assert_eq(on_side.size(), QuadrantRecipe.EXIT_WIDTH, "side %s, seed %d" % [side, seed_value])
			var middle := Vector2.ZERO
			for cell: Vector2i in on_side:
				middle += Vector2(cell) / on_side.size()
			assert_eq(middle, Vector2(80, 0) if side == Vector2i.UP else Vector2(80, 89) if side == Vector2i.DOWN \
				else Vector2(0, 45) if side == Vector2i.LEFT else Vector2(159, 45), "side %s, seed %d" % [side, seed_value])


func test_every_exit_can_be_walked_up_to_from_the_start() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var reached := _reachable(map)
		for barricade in map.cells_with_blocker(DungeonMap.Blocker.BARRICADE):
			var in_front := false
			for step in DungeonMapParser.NEIGHBOURS:
				in_front = in_front or reached.has(barricade + step)
			assert_true(in_front, "barricade %s, seed %d" % [barricade, seed_value])
		assert_false(reached.has(map.cells_with_blocker(DungeonMap.Blocker.BARRICADE)[0]), "a barricade is not walked through")


func test_the_crypt_entrance_is_reachable_and_at_least_halfway_out_from_the_middle() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_ne(map.exit_cell, DungeonMap.NO_CELL, "seed %d" % seed_value)
		assert_true(_reachable(map).has(map.exit_cell), "seed %d" % seed_value)
		assert_gte(_recipe.outward(map.exit_cell), 0.5, "seed %d" % seed_value)


func test_the_crypt_entrance_stands_in_a_stone_mausoleum() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for offset in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(-2, -2), Vector2i(2, 2)]:
			var wall: Vector2i = map.exit_cell + offset
			assert_false(map.is_open(wall), "wall at %s, seed %d" % [offset, seed_value])
			assert_eq(map.blocker_at(wall), DungeonMap.NO_BLOCKER, "stone, not trees, at %s, seed %d" % [offset, seed_value])
		assert_true(map.is_walkable(map.exit_cell + Vector2i(0, 2)), "its door faces south, seed %d" % seed_value)


func test_the_only_monsters_are_the_ones_living_in_camps_or_in_the_ruin() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_gt(map.enemy_spawns.size(), 0, "seed %d" % seed_value)
		for cell in map.enemy_spawns:
			var in_a_camp := Camps.campfire_of(map, cell) != DungeonMap.NO_CELL
			assert_true(in_a_camp or Ruins.is_home_of(map.ruin_cell, cell), "seed %d" % seed_value)


func test_the_whole_plains_is_one_open_room_so_no_door_ever_locks() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_eq(map.room_count, 1, "seed %d" % seed_value)
		assert_eq(map.door_cells().size(), 0, "seed %d" % seed_value)


func test_a_recipe_that_breaks_a_rule_is_made_again_with_the_next_random_numbers() -> void:
	var generator := QuadrantGenerator.new()
	var demanding := QuadrantRecipe.new()
	demanding.min_walkable_share = 0.9

	var map := _parser.parse(generator.generate(demanding, 0))

	assert_gt(generator.attempts, 1, "the first try for seed 0 makes less than 90% walkable")
	assert_ne(generator.last_broken_rule, "")
	assert_eq(_reachable(map).size(), map.walkable_cells().size())


func test_a_recipe_asking_for_the_impossible_still_gives_a_playable_plains() -> void:
	var impossible := QuadrantRecipe.new()
	impossible.min_walkable_share = 0.95
	impossible.grove_share = 0.4
	impossible.boulder_count = 300

	var map := _parser.parse(QuadrantGenerator.new().generate(impossible, 9))

	assert_ne(map.exit_cell, DungeonMap.NO_CELL)
	assert_true(_reachable(map).has(map.exit_cell))
	assert_eq(_reachable(map).size(), map.walkable_cells().size())


func test_a_set_piece_that_fits_nowhere_on_the_tuned_plains_still_gives_a_playable_plains() -> void:
	var cramped := QuadrantRecipe.new()
	cramped.width = 100
	cramped.height = 60
	cramped.village_width = 60
	cramped.village_height = 44

	var ascii := QuadrantGenerator.new().generate(cramped, 1)

	assert_ne(ascii, "")
	var map := _parser.parse(ascii)
	assert_ne(map.exit_cell, DungeonMap.NO_CELL)
	assert_true(_reachable(map).has(map.exit_cell))


func test_the_size_the_forest_and_the_village_follow_the_recipe() -> void:
	var recipe := QuadrantRecipe.new()
	recipe.width = 100
	recipe.height = 60
	recipe.village_width = 30
	recipe.village_height = 24
	recipe.crypt_min_outward = 0.7
	recipe.camp_count = 2
	recipe.campfire_count = 1
	for seed_value in 6:
		var map := _parser.parse(QuadrantGenerator.new().generate(recipe, seed_value))

		assert_eq(map.size, Vector2i(100, 60))
		assert_eq(map.village.area.get_center(), Vector2i(50, 30))
		assert_gte(map.village.area.size.x, 30)
		assert_gte(recipe.outward(map.exit_cell), 0.7, "seed %d" % seed_value)
		assert_true(_reachable(map).has(map.exit_cell), "seed %d" % seed_value)
