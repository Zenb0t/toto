extends GutTest
## How a band starts (asleep or wandering) comes from the map's seed.

const HOMES := 40


func _starts(map_seed: int, wandering_share := Band.DEFAULT_WANDERING_SHARE) -> Array[Band.Start]:
	var starts: Array[Band.Start] = []
	for home in HOMES:
		starts.append(Band.start_of(map_seed, home, wandering_share))
	return starts


func test_the_same_map_starts_its_bands_the_same_way() -> void:
	assert_eq(_starts(1234), _starts(1234))


func test_another_map_starts_its_bands_differently() -> void:
	assert_ne(_starts(1234), _starts(98765))


func test_most_bands_sleep_and_a_few_wander() -> void:
	var wandering := _starts(42).count(Band.Start.WANDERING)

	assert_gt(wandering, 0)
	assert_lt(wandering, HOMES / 2)


func test_the_wandering_share_decides_how_many_wander() -> void:
	assert_eq(_starts(42, 0.0).count(Band.Start.WANDERING), 0)
	assert_eq(_starts(42, 1.0).count(Band.Start.WANDERING), HOMES)


func _map(ascii: String) -> DungeonMap:
	return DungeonMapParser.new().parse(ascii)


func test_a_camps_monsters_live_together_at_its_campfire() -> void:
	var map := _map("#########\n#P.k....#\n#..F....#\n#...g...#\n#########")

	var kobold := Band.home_of(map, Vector2i(3, 1), 0.25, 0.5)
	var goblin := Band.home_of(map, Vector2i(4, 3), 0.25, 0.5)

	assert_eq(kobold.cell, Vector2i(3, 2))
	assert_eq(goblin.cell, Vector2i(3, 2))
	assert_eq(kobold.id, goblin.id)
	assert_eq(kobold.wandering_share, 0.5, "a camp starts by the camps' share")


func test_two_camps_are_two_bands() -> void:
	var map := _map("##################\n#P.k.........g...#\n#..F.........F...#\n##################")

	assert_ne(Band.home_of(map, Vector2i(3, 1), 0.25, 0.5).id, Band.home_of(map, Vector2i(13, 1), 0.25, 0.5).id)


func test_a_monster_away_from_any_campfire_lives_where_the_dungeons_bands_do() -> void:
	var map := _map("##############\n#P.F.......g.#\n##############")

	var home := Band.home_of(map, Vector2i(11, 1), 0.25, 0.5)

	assert_ne(home.cell, Vector2i(3, 1))
	assert_eq(home.wandering_share, 0.25)


func test_the_band_of_a_locking_room_is_always_awake_never_asleep() -> void:
	for home in 50:
		assert_eq(Band.start_of(3, home, 0.0, true), Band.Start.WANDERING)
		assert_eq(Band.start_of(3, home, 0.0), Band.Start.ASLEEP)
