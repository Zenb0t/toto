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
