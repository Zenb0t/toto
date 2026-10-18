extends GutTest
## The ruin in a corner of the plains, checked on many seeds through the real map parser: where it stands, how to get in,
## who lives there and what its chest holds.

const SEEDS := 20

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


## The walkable cells in the ruin's wall (not its corners), each with the step that leads out of the ruin through it.
func _gap_cells(map: DungeonMap) -> Dictionary:
	var rect := Ruins.rect_around(map.ruin_cell)
	var gaps := {}
	for x in range(rect.position.x + 1, rect.end.x - 1):
		for edge in [[rect.position.y, Vector2i.UP], [rect.end.y - 1, Vector2i.DOWN]]:
			if map.is_walkable(Vector2i(x, edge[0])):
				gaps[Vector2i(x, edge[0])] = edge[1]
	for y in range(rect.position.y + 1, rect.end.y - 1):
		for edge in [[rect.position.x, Vector2i.LEFT], [rect.end.x - 1, Vector2i.RIGHT]]:
			if map.is_walkable(Vector2i(edge[0], y)):
				gaps[Vector2i(edge[0], y)] = edge[1]
	return gaps


func _threat_of_camps(map: DungeonMap) -> Array[int]:
	var letters_by_fire := {}
	for cell in map.enemy_spawns:
		var fire := Camps.campfire_of(map, cell)
		if fire != DungeonMap.NO_CELL:
			letters_by_fire.get_or_add(fire, [] as Array[String]).append(Bestiary.by_id(map.monster_at(cell)).letter)
	var threats: Array[int] = []
	for fire in letters_by_fire:
		var letters: Array[String] = []
		letters.assign(letters_by_fire[fire])
		threats.append(CampCrews.threat(letters))
	return threats


func _ruin_band(map: DungeonMap) -> Array[String]:
	var letters: Array[String] = []
	for cell in map.enemy_spawns:
		if Band.home_of(map, cell, 0.15, 0.5).id == Ruins.NUMBER:
			letters.append(Bestiary.by_id(map.monster_at(cell)).letter)
	return letters


func test_every_plains_has_a_ruin_whose_chest_can_be_reached_from_the_village() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_ne(map.ruin_cell, DungeonMap.NO_CELL, "ruin, seed %d" % seed_value)
		assert_true(_reachable(map).has(map.ruin_cell), "chest, seed %d" % seed_value)


func test_the_ruin_stands_in_a_corner_and_never_the_crypt_entrances() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var out := _recipe.outward_by_axis(map.ruin_cell)
		assert_gte(minf(out.x, out.y), Ruins.CORNER_SHARE, "corner, seed %d" % seed_value)
		assert_ne(_recipe.corner_of(map.ruin_cell), _recipe.corner_of(map.exit_cell), "crypt corner, seed %d" % seed_value)


func test_the_crypt_entrance_still_lies_at_least_halfway_out() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		assert_gte(_recipe.outward(map.exit_cell), _recipe.crypt_min_outward, "seed %d" % seed_value)


func test_the_ruins_wall_has_two_or_three_gaps_each_leading_out_onto_the_plains() -> void:
	var reached := {}
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var gaps := _gap_cells(map)
		var count := gaps.size() / 3.0
		assert_true(count == 2.0 or count == 3.0, "gaps, seed %d: %s" % [seed_value, count])
		reached = _reachable(map)
		for cell: Vector2i in gaps:
			assert_true(reached.has(cell + gaps[cell]), "outside gap cell %s, seed %d" % [cell, seed_value])


func test_a_recipe_can_ask_for_exactly_three_gaps() -> void:
	var recipe := QuadrantRecipe.plains()
	recipe.ruin_gaps_min = 3
	recipe.ruin_gaps_max = 3
	var map := _parser.parse(QuadrantGenerator.new().generate(recipe, 5))

	assert_eq(_gap_cells(map).size(), 9)


func test_the_ruin_is_drawn_in_several_mirrored_ways() -> void:
	var drawings := {}
	for seed_value in 40:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var rows := Ruins.draw(_recipe, rng)
		drawings["\n".join(rows)] = true
		assert_eq(rows.size(), Ruins.SIZE.y)
		assert_eq(rows[Ruins.chest_offset().y][Ruins.chest_offset().x], Ruins.CHEST, "chest in the middle")
	assert_gt(drawings.size(), 4)


func test_the_ruin_holds_the_toughest_band_on_the_map() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var threat := CampCrews.threat(_ruin_band(map))
		assert_eq(_ruin_band(map).size(), Ruins.band_size(_recipe), "band size, seed %d" % seed_value)
		for camp_threat in _threat_of_camps(map):
			assert_gt(threat, camp_threat, "ruin against a camp, seed %d" % seed_value)


func test_the_ruin_stays_the_toughest_when_the_camps_are_tuned_up() -> void:
	var recipe := QuadrantRecipe.plains()
	recipe.camp_size_min = 6
	recipe.camp_size_max = 8
	for seed_value in 3:
		var map := _parser.parse(QuadrantGenerator.new().generate(recipe, seed_value))
		for camp_threat in _threat_of_camps(map):
			assert_gt(CampCrews.threat(_ruin_band(map)), camp_threat, "seed %d" % seed_value)


func test_the_ruins_band_always_starts_wandering_with_its_home_in_the_middle() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for cell in map.enemy_spawns:
			var home := Band.home_of(map, cell, 0.0, 0.0)
			if home.id != Ruins.NUMBER:
				continue
			assert_eq(home.cell, map.ruin_cell)
			assert_eq(Band.start_of(seed_value, home.id, home.wandering_share), Band.Start.WANDERING)


func test_the_ruins_band_id_is_neither_a_camps_nor_a_rooms() -> void:
	for seed_value in 5:
		var map: DungeonMap = _map_by_seed[seed_value]
		for fire in Camps.camp_campfires(map):
			assert_ne(Camps.band_id(map, fire), Ruins.NUMBER)
		assert_gt(Ruins.NUMBER, map.room_count)


func test_no_camp_monster_is_taken_for_the_ruins() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for cell in map.enemy_spawns:
			if Camps.campfire_of(map, cell) != DungeonMap.NO_CELL:
				assert_ne(Band.home_of(map, cell, 0.15, 0.5).id, Ruins.NUMBER, "seed %d" % seed_value)


func test_the_ruins_chest_always_holds_a_piece_of_gear_the_hero_does_not_hold() -> void:
	var items := GameTuning.item_ids()
	for seed_value in 30:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var held: Array[String] = [items[seed_value % items.size()], items[(seed_value * 3 + 1) % items.size()]]
		var found := LootTable.pick_item_id(items, held, rng)
		assert_true(found in items)
		assert_false(found in held, "seed %d" % seed_value)


func test_the_ruin_knobs_are_in_the_world_section_with_their_defaults() -> void:
	var fields: Array[String] = []
	for knob in _recipe.knobs():
		fields.append(knob.field)
	for field in ["ruin_gaps_min", "ruin_gaps_max", "ruin_band_size"]:
		assert_true(field in fields, field)
	assert_eq(_recipe.ruin_gaps_min, 2)
	assert_eq(_recipe.ruin_gaps_max, 3)
