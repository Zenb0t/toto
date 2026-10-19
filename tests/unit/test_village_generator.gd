extends GutTest
## Rules every village must keep, checked on many seeds through the real map parser. A village drawing is a whole
## little map (it holds the hero's start), so the parser reads it as it is.

const SEEDS := 40
const DEFAULT_SIZE := Vector2i(36, 28)
const SPECIALS := [Village.Kind.SMITHY, Village.Kind.MARKET, Village.Kind.CHURCH]

var _parser := DungeonMapParser.new()
var _result_by_seed := {}  # int -> VillageGenerator.Result
var _map_by_seed := {}  # int -> DungeonMap


func before_all() -> void:
	for seed_value in SEEDS:
		_result_by_seed[seed_value] = _village(seed_value)
		_map_by_seed[seed_value] = _parser.parse(_result_by_seed[seed_value].ascii())


func _village(seed_value: int, size := DEFAULT_SIZE, prop_share := 0.15) -> VillageGenerator.Result:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return VillageGenerator.new().generate(size, prop_share, rng)


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


func _count(map: DungeonMap, kind: Village.Kind) -> int:
	var count := 0
	for building in map.village.buildings:
		if building.kind == kind:
			count += 1
	return count


func test_the_same_seed_gives_the_same_village() -> void:
	assert_eq(_village(3).ascii(), _result_by_seed[3].ascii())


func test_different_seeds_give_different_villages() -> void:
	assert_ne(_result_by_seed[0].ascii(), _result_by_seed[1].ascii())


func test_the_village_is_36_by_28_cells_unless_it_had_to_grow() -> void:
	for seed_value in SEEDS:
		var result: VillageGenerator.Result = _result_by_seed[seed_value]
		var grew: bool = "bigger village" in result.fallbacks
		assert_eq(result.size == DEFAULT_SIZE, not grew, "seed %d" % seed_value)
		assert_eq(_map_by_seed[seed_value].village.area, Rect2i(Vector2i.ZERO, result.size), "seed %d" % seed_value)


func test_a_palisade_runs_all_round_with_a_three_wide_gate_in_the_middle_of_each_side() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var area := map.village.area
		assert_eq(map.village.gates.size(), 12, "seed %d" % seed_value)
		for gate in map.village.gates:
			assert_true(map.is_walkable(gate), "seed %d" % seed_value)
		for x in range(area.position.x, area.end.x):
			for y in [area.position.y, area.end.y - 1]:
				var cell := Vector2i(x, y)
				var is_gate := absi(x - area.size.x / 2) <= 1
				assert_eq(map.blocker_at(cell) == DungeonMap.Blocker.PALISADE, not is_gate, "seed %d %s" % [seed_value, cell])


func test_every_gate_the_square_the_inn_and_every_doorstep_can_be_walked_to_from_the_start() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var reached := _reachable(map)
		for gate in map.village.gates:
			assert_true(reached.has(gate), "gate %s, seed %d" % [gate, seed_value])
		assert_true(reached.has(map.village.well_cell + Vector2i(-4, -4)), "the square's corner, seed %d" % seed_value)
		assert_true(reached.has(map.village.inn_doorstep), "the inn's doorstep, seed %d" % seed_value)
		for lot: VillageLotPacker.Placed in _result_by_seed[seed_value].lots:
			assert_true(reached.has(lot.doorstep), "%s doorstep, seed %d" % [lot.lot_id, seed_value])


func test_the_run_starts_on_the_square_right_in_front_of_the_inns_doorstep() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var from_doorstep := map.player_spawn - map.village.inn_doorstep
		assert_eq(absi(from_doorstep.x) + absi(from_doorstep.y), 1, "seed %d" % seed_value)
		var from_well := (map.player_spawn - map.village.well_cell).abs()
		assert_lte(maxi(from_well.x, from_well.y), 4, "on the square, seed %d" % seed_value)


func test_the_inn_faces_the_square() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var inn := map.village.building_of(Village.Kind.INN)
		var door := map.village.inn_doorstep
		var beside_the_inn := false
		for step in DungeonMapParser.NEIGHBOURS:
			beside_the_inn = beside_the_inn or inn.rect.has_point(door + step)
		assert_true(beside_the_inn, "the doorstep touches the inn, seed %d" % seed_value)
		var in_front: Vector2i = map.player_spawn
		assert_eq(map.terrain_at(in_front), DungeonMap.Terrain.PATH, "seed %d" % seed_value)
		var well_distance := (in_front - map.village.well_cell).abs()
		assert_eq(maxi(well_distance.x, well_distance.y), 4, "the square's edge, seed %d" % seed_value)


func test_there_is_one_inn_one_or_two_other_special_buildings_and_three_to_five_houses() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var houses := _count(map, Village.Kind.HOUSE)
		var specials := 0
		for kind in SPECIALS:
			assert_lte(_count(map, kind), 1, "seed %d" % seed_value)
			specials += _count(map, kind)
		assert_eq(_count(map, Village.Kind.INN), 1, "seed %d" % seed_value)
		assert_between(specials, 1, 2, "seed %d" % seed_value)
		assert_between(houses, 3, 5, "seed %d" % seed_value)


func test_buildings_never_touch_each_other_or_the_palisade() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		for building in map.village.buildings:
			assert_true(map.village.area.grow(-2).encloses(building.rect), "seed %d" % seed_value)
			for other in map.village.buildings:
				if other != building:
					assert_false(building.rect.grow(1).intersects(other.rect), "seed %d" % seed_value)


func test_every_building_can_be_walked_up_to_and_faces_a_street() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var reached := _reachable(map)
		for lot: VillageLotPacker.Placed in _result_by_seed[seed_value].lots:
			assert_eq(map.terrain_at(lot.front), DungeonMap.Terrain.PATH, "%s, seed %d" % [lot.lot_id, seed_value])
			var door_wall := lot.doorstep - lot.facing
			assert_eq(map.blocker_at(door_wall), DungeonMap.Blocker.BUILDING, "%s, seed %d" % [lot.lot_id, seed_value])
			assert_true(reached.has(lot.front), "%s, seed %d" % [lot.lot_id, seed_value])


func test_lots_stand_every_which_way_so_they_face_their_own_street() -> void:
	var facings := {}
	for seed_value in SEEDS:
		for lot: VillageLotPacker.Placed in _result_by_seed[seed_value].lots:
			facings[lot.facing] = true
	assert_eq(facings.size(), 4, "doors face south, west, north and east across the seeds")


func test_a_house_shows_one_of_four_colours_and_a_village_shows_as_many_as_it_has_houses() -> void:
	var colours_seen := {}
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var colours := {}
		var houses := 0
		for building in map.village.buildings:
			if building.kind == Village.Kind.HOUSE:
				houses += 1
				colours[building.variant] = true
				colours_seen[building.variant] = true
		assert_eq(colours.size(), mini(houses, Village.HOUSE_COLORS), "seed %d" % seed_value)
	assert_eq(colours_seen.size(), Village.HOUSE_COLORS)


func test_the_colours_differ_from_seed_to_seed() -> void:
	var looks := {}
	for seed_value in SEEDS:
		var colours: Array = []
		for building in _map_by_seed[seed_value].village.buildings:
			if building.kind == Village.Kind.HOUSE:
				colours.append(building.variant)
		looks[colours] = true
	assert_gt(looks.size(), 5)


func test_no_monster_lives_in_the_village() -> void:
	for seed_value in SEEDS:
		assert_eq(_map_by_seed[seed_value].enemy_spawns.size(), 0, "seed %d" % seed_value)


func test_the_streets_are_three_wide_from_each_gate_to_the_square() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var middle := map.village.area.size / 2
		for offset in range(-1, 2):
			for y in range(1, 8):
				assert_eq(map.terrain_at(Vector2i(middle.x + offset, y)), DungeonMap.Terrain.PATH, "seed %d" % seed_value)
			for x in range(1, 8):
				assert_eq(map.terrain_at(Vector2i(x, middle.y + offset)), DungeonMap.Terrain.PATH, "seed %d" % seed_value)


func test_the_well_stands_in_the_middle_of_a_nine_by_nine_square() -> void:
	for seed_value in SEEDS:
		var map: DungeonMap = _map_by_seed[seed_value]
		var well := map.village.well_cell
		assert_eq(map.blocker_at(well), DungeonMap.Blocker.WELL, "seed %d" % seed_value)
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var cell := well + Vector2i(dx, dy)
				var is_well := absi(dx) <= 1 and absi(dy) <= 1
				if not is_well:
					assert_true(map.is_walkable(cell), "seed %d %s" % [seed_value, cell])
					assert_eq(map.terrain_at(cell), DungeonMap.Terrain.PATH, "seed %d %s" % [seed_value, cell])


func test_the_seed_moves_the_square_off_the_middle_of_the_village() -> void:
	var offsets := {}
	for seed_value in SEEDS:
		offsets[_map_by_seed[seed_value].village.well_cell] = true
	assert_gt(offsets.size(), 4)


func test_barrels_and_crates_fill_a_share_of_the_leftover_ground_and_wall_nothing_off() -> void:
	for seed_value in 12:
		var bare := _parser.parse(_village(seed_value, DEFAULT_SIZE, 0.0).ascii())
		var stocked := _parser.parse(_village(seed_value).ascii())
		var extra := stocked.cells_with_blocker(DungeonMap.Blocker.PROP).size() \
				- bare.cells_with_blocker(DungeonMap.Blocker.PROP).size()
		assert_gt(extra, 10, "props fill leftovers, seed %d" % seed_value)
		assert_eq(_reachable(stocked).size(), _reachable(bare).size() - extra, "nothing cut off, seed %d" % seed_value)


func test_more_props_when_the_share_is_higher() -> void:
	var few := _parser.parse(_village(4, DEFAULT_SIZE, 0.05).ascii()).cells_with_blocker(DungeonMap.Blocker.PROP).size()
	var many := _parser.parse(_village(4, DEFAULT_SIZE, 0.4).ascii()).cells_with_blocker(DungeonMap.Blocker.PROP).size()
	assert_gt(many, few * 2)


func test_a_village_that_cannot_fit_its_plan_gives_up_houses_then_the_market_and_then_grows() -> void:
	var seen_order_ok := true
	var grew := 0
	for seed_value in 6:
		var result := _village(seed_value, Vector2i(24, 20))
		var map := _parser.parse(result.ascii())
		var order := ["fewer houses", "no market", "bigger village"]
		var last := -1
		for fallback: String in result.fallbacks:
			seen_order_ok = seen_order_ok and order.find(fallback) > last
			last = order.find(fallback)
		if result.size != Vector2i(24, 20):
			grew += 1
		assert_not_null(map.village, "seed %d" % seed_value)
		assert_gte(_count(map, Village.Kind.HOUSE), VillageGenerator.MIN_HOUSES, "seed %d" % seed_value)
		assert_eq(_count(map, Village.Kind.INN), 1, "seed %d" % seed_value)
		assert_true(_reachable(map).has(map.village.inn_doorstep), "seed %d" % seed_value)
	assert_true(seen_order_ok, "fewer houses, then no market, then a bigger village")
	assert_gt(grew, 0, "24x20 is too small for an inn and three houses")


func test_a_village_that_fits_on_the_first_tries_gives_up_nothing() -> void:
	var easy := _village(0)

	assert_eq(easy.fallbacks, [] as Array[String])
	assert_lte(easy.attempts, VillageGenerator.TRIES)


func test_a_seed_gets_twenty_tries_before_the_plan_shrinks() -> void:
	for seed_value in SEEDS:
		var result: VillageGenerator.Result = _result_by_seed[seed_value]
		if not result.fallbacks.is_empty():
			assert_gt(result.attempts, VillageGenerator.TRIES, "seed %d" % seed_value)


func test_buildings_keep_the_gap_asked_for_between_them() -> void:
	for seed_value in 10:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := _parser.parse(VillageGenerator.new().generate(Vector2i(48, 36), 0.01, rng, 2).ascii())
		for building in map.village.buildings:
			for other in map.village.buildings:
				if other != building:
					assert_false(building.rect.grow(2).intersects(other.rect), "seed %d" % seed_value)


func test_buildings_spread_round_the_whole_village_rather_than_bunching_by_the_square() -> void:
	for seed_value in 10:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := _parser.parse(VillageGenerator.new().generate(Vector2i(48, 36), 0.01, rng, 2).ascii())
		var middle := map.village.area.get_center()
		var quarters := {}
		for building in map.village.buildings:
			var center := building.rect.get_center()
			quarters[Vector2i(signi(center.x - middle.x), signi(center.y - middle.y))] = true
		assert_gte(quarters.size(), 3, "seed %d" % seed_value)
