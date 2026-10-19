extends GutTest
## The land of the plains split into zones: mostly meadow, a few woods and ponds, never on the village's ground.

const SEEDS := 10

var _recipe := QuadrantRecipe.plains()


func _zones(seed_value: int, recipe := _recipe) -> Array[PlainsZones.Zone]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return PlainsZones.plan(recipe, rng)


func test_the_recipe_sets_how_many_woods_and_ponds_there_are() -> void:
	for seed_value in SEEDS:
		var zones := _zones(seed_value)

		assert_eq(PlainsZones.of_kind(zones, PlainsZones.Kind.WOOD).size(), _recipe.wood_count, "seed %d" % seed_value)
		assert_eq(PlainsZones.of_kind(zones, PlainsZones.Kind.POND).size(), _recipe.pond_count, "seed %d" % seed_value)


func test_most_of_the_land_is_meadow() -> void:
	for seed_value in SEEDS:
		var zones := _zones(seed_value)

		assert_gte(PlainsZones.of_kind(zones, PlainsZones.Kind.MEADOW).size(), zones.size() / 2, "seed %d" % seed_value)


func test_no_wood_or_pond_reaches_the_village_or_the_grass_round_it() -> void:
	for seed_value in SEEDS:
		for zone in _zones(seed_value):
			if zone.kind != PlainsZones.Kind.MEADOW:
				var from_middle := Vector2(zone.center - _recipe.center()).length()
				assert_gt(from_middle - zone.reach, _recipe.village_radius(), "seed %d" % seed_value)


func test_woods_keep_off_the_forest_border() -> void:
	var inside := _recipe.interior()
	for seed_value in SEEDS:
		for zone in PlainsZones.of_kind(_zones(seed_value), PlainsZones.Kind.WOOD):
			var reach := PlainsZones.wood_radius(zone, _recipe) * (1.0 + PlainsWoods.EDGE_WOBBLE)
			var wood := Rect2i(zone.center, Vector2i.ZERO).grow(floori(reach))
			assert_true(inside.grow(-PlainsZones.WOOD_ROOM).encloses(wood), "seed %d" % seed_value)


func test_a_wood_never_spills_out_of_its_zone() -> void:
	for seed_value in SEEDS:
		for zone in PlainsZones.of_kind(_zones(seed_value), PlainsZones.Kind.WOOD):
			assert_lte(PlainsZones.wood_radius(zone, _recipe), zone.reach * _recipe.wood_reach, "seed %d" % seed_value)


func test_zones_do_not_overlap() -> void:
	var zones := _zones(1)

	for zone in zones:
		for other in zones:
			if other != zone:
				assert_gte(Vector2(zone.center).distance_to(Vector2(other.center)), zone.reach + other.reach - 0.01)


func test_asking_for_more_woods_than_fit_gives_as_many_as_there_is_room_for() -> void:
	var greedy := QuadrantRecipe.plains()
	greedy.wood_count = 100

	var zones := _zones(1, greedy)

	assert_lt(PlainsZones.of_kind(zones, PlainsZones.Kind.WOOD).size(), 100)
	assert_gt(PlainsZones.of_kind(zones, PlainsZones.Kind.WOOD).size(), 0)
