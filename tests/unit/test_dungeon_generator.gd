extends GutTest

const GRID := Vector2i(48, 32)


func _generate(seed_value: int) -> DungeonLayout:
	return DungeonGenerator.new(GRID).generate(seed_value)


func _reachable_from(layout: DungeonLayout, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbour: Vector2i = cell + step
			if layout.is_floor(neighbour) and not seen.has(neighbour):
				seen[neighbour] = true
				frontier.append(neighbour)
	return seen


func test_same_seed_produces_identical_dungeon() -> void:
	var first := _generate(1234)
	var second := _generate(1234)

	assert_eq(first.floor_cells(), second.floor_cells())
	assert_eq(first.rooms, second.rooms)


func test_different_seeds_produce_different_dungeons() -> void:
	assert_ne(_generate(1).floor_cells(), _generate(2).floor_cells())


func test_dungeon_contains_multiple_rooms() -> void:
	for seed_value in range(20):
		assert_gt(_generate(seed_value).rooms.size(), 1, "seed %d" % seed_value)


func test_every_floor_cell_is_reachable_from_the_first_room() -> void:
	for seed_value in range(20):
		var layout := _generate(seed_value)

		var reachable := _reachable_from(layout, layout.room_center(0))

		assert_eq(reachable.size(), layout.floor_cells().size(), "seed %d" % seed_value)


func test_outer_border_is_always_wall() -> void:
	for seed_value in range(20):
		var layout := _generate(seed_value)
		for x in GRID.x:
			assert_false(layout.is_floor(Vector2i(x, 0)))
			assert_false(layout.is_floor(Vector2i(x, GRID.y - 1)))
		for y in GRID.y:
			assert_false(layout.is_floor(Vector2i(0, y)))
			assert_false(layout.is_floor(Vector2i(GRID.x - 1, y)))


func test_cells_outside_the_grid_are_not_floor() -> void:
	var layout := _generate(7)

	assert_false(layout.is_floor(Vector2i(-1, 5)))
	assert_false(layout.is_floor(Vector2i(5, GRID.y)))
