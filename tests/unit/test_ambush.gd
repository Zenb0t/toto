extends GutTest
## The ambush roll of a campfire lighting: seeded by the map, the campfire and the lighting, so it can't be
## re-rolled; likelier in the crypt; and who comes is taken from the monsters near the fire.

const SEEDS := 2000
const FIRE := Vector2i(30, 20)

var _ambush: Ambush


func before_each() -> void:
	_ambush = Ambush.new()


func _hits_over_seeds(rule: Ambush, outdoors: bool) -> float:
	var hits := 0
	for seed_value in SEEDS:
		if rule.hits(seed_value, FIRE, 0, outdoors):
			hits += 1
	return float(hits) / SEEDS


func _plains_map() -> DungeonMap:
	return DungeonMapParser.new().parse(QuadrantGenerator.new().generate(QuadrantRecipe.plains(), 7))


func test_the_same_campfire_and_lighting_always_give_the_same_result() -> void:
	for seed_value in 50:
		var first := _ambush.hits(seed_value, FIRE, 2, true)
		assert_eq(Ambush.new().hits(seed_value, FIRE, 2, true), first, "seed %d" % seed_value)


func test_other_lightings_of_one_campfire_roll_differently() -> void:
	var results := {}
	for lighting in 40:
		results[_ambush.hits(1234, FIRE, lighting, true)] = true

	assert_eq(results.size(), 2, "some lightings are ambushed and some are not")


func test_other_campfires_roll_differently() -> void:
	var results := {}
	for x in 40:
		results[_ambush.hits(1234, Vector2i(x, 5), 0, true)] = true

	assert_eq(results.size(), 2)


func test_about_three_in_ten_lightings_on_the_plains_are_ambushed() -> void:
	assert_almost_eq(_hits_over_seeds(_ambush, true), 0.30, 0.04)


func test_the_crypt_is_ambushed_more_often_than_the_plains() -> void:
	var crypt := _hits_over_seeds(_ambush, false)

	assert_gt(crypt, _hits_over_seeds(_ambush, true) + 0.08)
	assert_almost_eq(crypt, 0.45, 0.04)


func test_the_chances_are_the_rules_knobs() -> void:
	var never := Ambush.new()
	never.chance = 0.0
	var always := Ambush.new()
	always.crypt_chance = 1.0

	assert_eq(_hits_over_seeds(never, true), 0.0)
	assert_eq(_hits_over_seeds(always, false), 1.0)


func test_every_number_of_the_rule_is_a_knob() -> void:
	var fields: Array[String] = []
	for knob in _ambush.knobs():
		fields.append(knob.field)

	assert_eq(fields, ["chance", "crypt_chance", "size", "delay_seconds", "margin_cells"] as Array[String])


func test_the_crew_is_the_size_the_rule_says() -> void:
	var map := _plains_map()
	var fire := map.campfire_cells[0]
	_ambush.size = 5

	assert_eq(_ambush.crew(map, fire, 7, 0).size(), 5)
	assert_eq(Ambush.new().crew(map, fire, 7, 0).size(), 3)


func test_the_crew_is_picked_from_the_monsters_the_map_has_near_the_fire() -> void:
	var map := _plains_map()
	var fire := map.campfire_cells[0]
	var nearest: Array[Vector2i] = map.enemy_spawns.duplicate()
	nearest.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Vector2(a - fire).length() < Vector2(b - fire).length())
	var area: Array[String] = []
	for cell in nearest.slice(0, Ambush.AREA_SPAWNS):
		area.append(map.monster_at(cell))

	for lighting in 20:
		for monster_id in _ambush.crew(map, fire, 7, lighting):
			assert_has(area, monster_id)


func test_the_same_lighting_brings_the_same_crew() -> void:
	var map := _plains_map()
	var fire := map.campfire_cells[0]

	assert_eq(_ambush.crew(map, fire, 7, 1), Ambush.new().crew(map, fire, 7, 1))


func test_a_map_without_monsters_sends_kobolds() -> void:
	var map := _plains_map()
	map.enemy_spawns.clear()

	assert_eq(_ambush.crew(map, map.campfire_cells[0], 7, 0), ["kobold", "kobold", "kobold"] as Array[String])


func test_each_campfire_has_its_own_band_of_ambushers() -> void:
	var map := _plains_map()

	assert_ne(Ambush.band_id(map, Vector2i(3, 4)), Ambush.band_id(map, Vector2i(4, 3)))
	assert_ne(Ambush.band_id(map, Vector2i(3, 4)), Camps.band_id(map, Vector2i(3, 4)))


func test_ambushers_bands_are_clear_of_the_camps_and_the_ruins_band() -> void:
	var map := _plains_map()
	var last_camp := Camps.band_id(map, map.size - Vector2i.ONE)
	var ruin_band := 2_000_000  # Ruins.NUMBER (#39)

	for fire in map.campfire_cells:
		var band := Ambush.band_id(map, fire)
		assert_gt(band, last_camp, "after every camp band")
		assert_gt(band, ruin_band, "after the ruin's band")
