extends GutTest
## Which room of a level holds the campfire, from the room graph alone.


func _graph(seed_value: int) -> RoomGraph:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return RoomGraph.grow(
		DungeonGenerator.GRID, rng.randi_range(DungeonGenerator.MIN_ROOMS, DungeonGenerator.MAX_ROOMS),
		rng.randi_range(0, DungeonGenerator.MAX_EXTRA_LINKS), rng)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_the_campfire_never_lies_in_the_start_room_or_the_exit_room() -> void:
	for seed_value in 60:
		var graph := _graph(seed_value)
		for rooms_from_stairs in range(0, 8):
			var slot := CryptCampfire.slot_for(graph, rooms_from_stairs, _rng(seed_value))
			assert_ne(slot, graph.start_slot(), "seed %d" % seed_value)
			assert_ne(slot, graph.deepest_slot(), "seed %d" % seed_value)
			assert_has(graph.slots, slot)


func test_the_campfire_lies_in_the_room_nearest_the_wanted_distance() -> void:
	for seed_value in 60:
		var graph := _graph(seed_value)
		var slot := CryptCampfire.slot_for(graph, 2, _rng(seed_value))
		for other in graph.slots:
			if other != graph.start_slot() and other != graph.deepest_slot():
				assert_lte(absi(graph.depth_of(slot) - 2), absi(graph.depth_of(other) - 2), "seed %d" % seed_value)


func test_the_same_graph_and_rng_choose_the_same_room() -> void:
	var graph := _graph(4)

	assert_eq(CryptCampfire.slot_for(graph, 3, _rng(9)), CryptCampfire.slot_for(graph, 3, _rng(9)))
