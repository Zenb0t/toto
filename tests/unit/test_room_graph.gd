extends GutTest

const GRID := Vector2i(4, 3)


func _grow(seed_value: int, rooms := 7, extra_links := 1) -> RoomGraph:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return RoomGraph.grow(GRID, rooms, extra_links, rng)


func test_it_has_as_many_rooms_as_asked_each_in_its_own_slot() -> void:
	var graph := _grow(1, 7)

	assert_eq(graph.slots.size(), 7)
	for slot in graph.slots:
		assert_eq(graph.slots.count(slot), 1)
		assert_true(slot.x >= 0 and slot.y >= 0 and slot.x < GRID.x and slot.y < GRID.y, str(slot))


func test_links_only_join_neighbouring_rooms() -> void:
	for seed_value in 20:
		for link: Array in _grow(seed_value).links:
			var a: Vector2i = link[0]
			var b: Vector2i = link[1]
			assert_eq(absi(a.x - b.x) + absi(a.y - b.y), 1, "%s-%s" % [a, b])


func test_every_room_can_be_reached_from_the_start() -> void:
	for seed_value in 20:
		var graph := _grow(seed_value)
		for slot in graph.slots:
			assert_true(graph.depth_of(slot) >= 0)


func test_extra_links_add_loops_beyond_the_tree() -> void:
	var graph := _grow(3, 7, 2)

	assert_gt(graph.links.size(), graph.slots.size() - 1)


func test_the_start_is_at_depth_zero_and_the_deepest_room_is_farthest() -> void:
	var graph := _grow(4)

	assert_eq(graph.depth_of(graph.start_slot()), 0)
	for slot in graph.slots:
		assert_true(graph.depth_of(slot) <= graph.depth_of(graph.deepest_slot()))


func test_the_same_seed_grows_the_same_graph() -> void:
	assert_eq(_grow(5).slots, _grow(5).slots)
	assert_eq(_grow(5).links, _grow(5).links)


func test_a_dead_end_has_a_single_link() -> void:
	var graph := _grow(6, 7, 0)
	var dead_ends := graph.slots.filter(func(slot: Vector2i) -> bool: return graph.link_count(slot) == 1)

	assert_gt(dead_ends.size(), 0)
	for slot: Vector2i in graph.slots:
		var by_hand := graph.links.filter(func(link: Array) -> bool: return slot in link).size()
		assert_eq(graph.link_count(slot), by_hand)
