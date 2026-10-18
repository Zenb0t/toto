extends GutTest
## The plains' camps and campfires, checked on many seeds through the real map parser.

const SEEDS := 30

var _parser := DungeonMapParser.new()
var _recipe := QuadrantRecipe.plains()
var _map_by_seed := {}  # int -> DungeonMap


func before_all() -> void:
	for seed_value in SEEDS:
		_map_by_seed[seed_value] = _parser.parse(QuadrantGenerator.new().generate(_recipe, seed_value))


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


func _letters_of_camp(map: DungeonMap, fire: Vector2i) -> Array[String]:
	var letters: Array[String] = []
	for cell in map.enemy_spawns:
		if Camps.campfire_of(map, cell) == fire:
			letters.append(Bestiary.by_id(map.monster_at(cell)).letter)
	return letters


func _outward(cell: Vector2i) -> float:
	return _recipe.outward(cell)


func test_the_plains_hold_six_camps_and_three_lone_campfires() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_eq(Camps.camp_campfires(map).size(), 6, "camps, seed %d" % seed_value)
		assert_eq(Camps.lone_campfires(map).size(), 3, "lone campfires, seed %d" % seed_value)


func test_every_campfire_and_every_camp_monster_can_be_reached() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var reached := _reachable(map)
		for fire in map.campfire_cells:
			assert_true(reached.has(fire), "campfire %s, seed %d" % [fire, seed_value])
		for cell in map.enemy_spawns:
			assert_true(reached.has(cell), "monster at %s, seed %d" % [cell, seed_value])


func test_camps_keep_eighteen_cells_apart() -> void:
	for seed_value in SEEDS:
		var fires := Camps.camp_campfires(_map_by_seed[seed_value])
		for i in fires.size():
			for j in range(i + 1, fires.size()):
				assert_gte(Vector2(fires[i]).distance_to(Vector2(fires[j])), 18.0, "seed %d" % seed_value)


func test_lone_campfires_keep_thirty_five_cells_apart_and_twelve_from_any_camp() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var lone := Camps.lone_campfires(map)
		for i in lone.size():
			for j in range(i + 1, lone.size()):
				assert_gte(Vector2(lone[i]).distance_to(Vector2(lone[j])), 35.0, "apart, seed %d" % seed_value)
			for camp in Camps.camp_campfires(map):
				assert_gte(Vector2(lone[i]).distance_to(Vector2(camp)), 12.0, "from camps, seed %d" % seed_value)


func test_one_lone_campfire_lies_near_the_clear_ring() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var nearest := INF
		for fire in Camps.lone_campfires(map):
			nearest = minf(nearest, Vector2(fire).distance_to(Vector2(_recipe.center())))
		assert_lte(nearest, float(_recipe.safe_ring + QuadrantRecipe.NEAR_CAMPFIRE_BEYOND_RING), "seed %d" % seed_value)


func test_nothing_stands_inside_the_clear_ring() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var middle := Vector2(_recipe.center())
		for fire in map.campfire_cells:
			assert_gt(Vector2(fire).distance_to(middle), float(_recipe.safe_ring), "campfire, seed %d" % seed_value)
		for cell in map.enemy_spawns:
			assert_gt(Vector2(cell).distance_to(middle), float(_recipe.safe_ring), "monster, seed %d" % seed_value)


func test_a_camp_is_two_to_four_goblins_kobolds_and_archers_round_its_fire() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for fire in Camps.camp_campfires(map):
			var letters := _letters_of_camp(map, fire)
			assert_between(letters.size(), 2, 4, "size, seed %d" % seed_value)
			for letter in letters:
				assert_true(letter in ["k", "g", "a"], "%s, seed %d" % [letter, seed_value])


func test_farther_camps_are_bigger_and_tougher_than_nearer_ones() -> void:
	var near_threat := 0.0
	var far_threat := 0.0
	var near_size := 0.0
	var far_size := 0.0
	var camps := 0
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var fires := Camps.camp_campfires(map)
		fires.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return _outward(a) < _outward(b))
		var half := fires.size() / 2
		for i in fires.size():
			var letters := _letters_of_camp(map, fires[i])
			if i < half:
				near_threat += CampCrews.threat(letters)
				near_size += letters.size()
			else:
				far_threat += CampCrews.threat(letters)
				far_size += letters.size()
		camps += half
	assert_gt(far_threat / camps, near_threat / camps)
	assert_gt(far_size / camps, near_size / camps)


func test_the_placement_rule_makes_bands_no_smaller_and_no_weaker_the_farther_out_they_are() -> void:
	var rng := RandomNumberGenerator.new()
	var previous_size := 0
	for step in 21:
		var outward := step / 20.0
		var size := CampCrews.band_size(_recipe, outward)
		assert_gte(size, previous_size, "size at %.2f" % outward)
		previous_size = size
	var near_total := 0
	var far_total := 0
	for seed_value in 200:
		rng.seed = seed_value
		near_total += CampCrews.threat(CampCrews.band_letters(_recipe, 0.3, rng))
		rng.seed = seed_value
		far_total += CampCrews.threat(CampCrews.band_letters(_recipe, 1.0, rng))
	assert_gt(float(far_total), near_total * 1.5)


func test_goblin_archers_only_stand_toward_the_edge() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value in 50:
		rng.seed = seed_value
		assert_false("a" in CampCrews.band_letters(_recipe, 0.35, rng), "near, seed %d" % seed_value)
	rng.seed = 1
	assert_true("a" in CampCrews.band_letters(_recipe, 1.0, rng), "at the edge")


func test_the_same_seed_gives_the_same_camps_and_the_same_roll_to_sleep_or_wander() -> void:
	var again := _parser.parse(QuadrantGenerator.new().generate(_recipe, 3))
	var map: DungeonMap = _map_by_seed[3]

	assert_eq(again.campfire_cells, map.campfire_cells)
	assert_eq(again.enemy_spawns, map.enemy_spawns)
	assert_eq(Camps.camp_campfires(again), Camps.camp_campfires(map))
	for fire in Camps.camp_campfires(map):
		assert_eq(_letters_of_camp(again, fire), _letters_of_camp(map, fire))
	for cell in map.enemy_spawns:
		var first := Band.home_of(map, cell, 0.25, _recipe.camp_wandering_share())
		var second := Band.home_of(again, cell, 0.25, _recipe.camp_wandering_share())
		assert_eq(first.cell, second.cell)
		assert_eq(Band.start_of(3, second.id, second.wandering_share), Band.start_of(3, first.id, first.wandering_share))


func test_about_half_the_camps_start_asleep_and_the_rest_wander() -> void:
	var asleep := 0
	var total := 0
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for fire in Camps.camp_campfires(map):
			total += 1
			if Band.start_of(seed_value, Camps.band_id(map, fire), _recipe.camp_wandering_share()) == Band.Start.ASLEEP:
				asleep += 1
	assert_between(float(asleep) / total, 0.35, 0.65)


func test_camps_that_never_sleep_all_wander() -> void:
	var recipe := QuadrantRecipe.plains()
	recipe.camp_asleep_chance = 0.0
	var map := _parser.parse(QuadrantGenerator.new().generate(recipe, 5))
	for fire in Camps.camp_campfires(map):
		assert_eq(Band.start_of(5, Camps.band_id(map, fire), recipe.camp_wandering_share()), Band.Start.WANDERING)


func test_camp_count_spacing_and_sizes_are_tunable_in_the_world_group() -> void:
	var fields := QuadrantRecipe.plains().knobs().map(func(knob: Knob) -> String: return knob.field)
	for field in ["camp_count", "camp_spacing", "camp_size_min", "camp_size_max", "camp_asleep_chance"]:
		assert_true(field in fields, field)


func test_a_tuned_camp_count_changes_how_many_camps_the_plains_hold() -> void:
	var recipe := QuadrantRecipe.plains()
	recipe.camp_count = 3

	var map := _parser.parse(QuadrantGenerator.new().generate(recipe, 2))

	assert_eq(Camps.camp_campfires(map).size(), 3)


func test_a_monster_far_from_any_campfire_belongs_to_no_camp() -> void:
	var map := _parser.parse("#####\n#Pg.#\n#####")

	assert_eq(Camps.campfire_of(map, Vector2i(2, 1)), DungeonMap.NO_CELL)


func test_campfires_show_on_the_minimap_once_in_sight() -> void:
	var map: DungeonMap = _map_by_seed[0]
	var fire: Vector2i = map.campfire_cells[0]
	var exploration := Exploration.new()
	exploration.look_from(fire, func(_cell: Vector2i) -> bool: return true)

	var image := MinimapPainter.paint(map, exploration, map.player_spawn)

	assert_eq(image.get_pixelv(fire).to_html(), MinimapPainter.CAMPFIRE_COLOR.to_html())
