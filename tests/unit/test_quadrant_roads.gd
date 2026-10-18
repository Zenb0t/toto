extends GutTest
## The plains' dirt roads from the village gates to the exits, checked on many seeds through the real map parser.

const SEEDS := 25

var _parser := DungeonMapParser.new()
var _recipe := QuadrantRecipe.plains()
var _map_by_seed := {}  # int -> DungeonMap


func before_all() -> void:
	for seed_value in SEEDS:
		_map_by_seed[seed_value] = _parser.parse(QuadrantGenerator.new().generate(_recipe, seed_value))


func _road_cells(map: DungeonMap) -> Dictionary:
	var cells := {}
	for cell in map.cells_with(DungeonMap.Terrain.ROAD):
		cells[cell] = true
	return cells


func _gate_front(map: DungeonMap, side: Vector2i) -> Vector2i:
	return map.village.area.position + VillagePalisade.outside_cell(map.village.area.size, side)


func _exit_front(side: Vector2i) -> Vector2i:
	return QuadrantExits.front_cell(_recipe, side)


## The sides whose road joins the village gate to the exit: both ends on a road, with road all the way between.
func _sides_joined(map: DungeonMap) -> Array[Vector2i]:
	var road := _road_cells(map)
	var joined: Array[Vector2i] = []
	for side in QuadrantExits.SIDES:
		var from := _gate_front(map, side)
		if not road.has(from) or not road.has(_exit_front(side)):
			continue
		var reached := {from: true}
		var frontier: Array[Vector2i] = [from]
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			for step in DungeonMapParser.NEIGHBOURS:
				if road.has(cell + step) and not reached.has(cell + step):
					reached[cell + step] = true
					frontier.append(cell + step)
		if reached.has(_exit_front(side)):
			joined.append(side)
	return joined


func _dot(a: Vector2i, b: Vector2i) -> int:
	return a.x * b.x + a.y * b.y


func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func test_two_roads_join_a_village_gate_to_its_exit() -> void:
	for seed_value in SEEDS:
		assert_eq(_sides_joined(_map_by_seed[seed_value]).size(), 2, "seed %d" % seed_value)


func test_the_seed_picks_which_exits_get_a_road() -> void:
	var picks := {}
	for seed_value in SEEDS:
		picks[_sides_joined(_map_by_seed[seed_value])] = true
	assert_gt(picks.size(), 2, "different seeds pick different exits")


func test_a_road_has_no_stretch_narrower_than_three_cells() -> void:
	for seed_value in SEEDS:
		var road := _road_cells(_map_by_seed[seed_value])
		for cell: Vector2i in road:
			var covered := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					covered = covered or _is_block_of_road(road, cell + Vector2i(dx, dy))
			assert_true(covered, "%s, seed %d" % [cell, seed_value])
			if not covered:
				return


func _is_block_of_road(road: Dictionary, middle: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if not road.has(middle + Vector2i(dx, dy)):
				return false
	return true


func test_a_road_bends_instead_of_running_ruler_straight() -> void:
	var bent := 0
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for side in _sides_joined(map):
			var across := Vector2i(absi(side.y), absi(side.x))
			var lanes := {}
			for cell: Vector2i in _road_cells(map):
				if _dot(cell - map.village.area.get_center(), side) > 0 and _dot(cell, side) > 0:
					lanes[_dot(cell, across)] = true
			if lanes.size() > 3:
				bent += 1
	assert_gt(bent, SEEDS / 2, "most roads leave the straight line between gate and exit")


func test_nothing_stands_on_a_road() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var road := _road_cells(map)
		for cell in map.enemy_spawns + map.campfire_cells + [map.player_spawn, map.exit_cell] + map.loot_cells:
			assert_false(road.has(cell), "%s, seed %d" % [cell, seed_value])
		for cell: Vector2i in road:
			assert_eq(map.blocker_at(cell), DungeonMap.NO_BLOCKER, "%s, seed %d" % [cell, seed_value])
			assert_false(map.is_in_village(cell), "%s, seed %d" % [cell, seed_value])


func test_no_road_goes_near_a_camp_a_campfire_or_the_crypt_entrance() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var road := _road_cells(map)
		var close := 0
		for cell: Vector2i in road:
			for fire in map.campfire_cells:
				close = maxi(close, 4 - _chebyshev(cell, fire))
			close = maxi(close, 4 - _chebyshev(cell, map.exit_cell))
		assert_eq(close, 0, "a road comes within 3 cells of something, seed %d" % seed_value)


func test_roads_are_walked_like_grass() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for cell: Vector2i in _road_cells(map):
			assert_true(map.is_walkable(cell) and map.is_see_through(cell), "%s, seed %d" % [cell, seed_value])
			assert_eq(map.ground_speed(cell), 1.0, "%s, seed %d" % [cell, seed_value])


func test_the_same_seed_gives_the_same_roads() -> void:
	var again := _parser.parse(QuadrantGenerator.new().generate(_recipe, 4))
	assert_eq(_road_cells(again), _road_cells(_map_by_seed[4]))


func test_the_number_of_roads_is_a_setting() -> void:
	for count in [0, 1, 4]:
		var recipe := QuadrantRecipe.plains()
		recipe.road_count = count
		for seed_value in 5:
			var map := _parser.parse(QuadrantGenerator.new().generate(recipe, seed_value))
			assert_eq(_sides_joined(map).size(), count, "%d roads, seed %d" % [count, seed_value])
			assert_eq(map.cells_with(DungeonMap.Terrain.ROAD).is_empty(), count == 0)


func test_the_number_of_roads_and_how_far_they_wander_can_be_tuned_in_the_world_tab() -> void:
	var fields := []
	for knob in _recipe.knobs():
		fields.append(knob.field)
	assert_true("road_count" in fields)
	assert_true("road_bend" in fields)
