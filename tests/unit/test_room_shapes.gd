extends GutTest

const BOUNDS := Rect2i(10, 10, 24, 16)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_every_kind_of_room_is_one_piece_inside_its_bounds() -> void:
	for kind in RoomShapes.Kind.values():
		for seed_value in 10:
			var cells := RoomShapes.build(kind, BOUNDS, _rng(seed_value))
			assert_true(RoomShapes.is_one_piece(cells), "kind %d seed %d" % [kind, seed_value])
			for cell: Vector2i in cells:
				assert_true(BOUNDS.has_point(cell), "kind %d seed %d: %s" % [kind, seed_value, cell])


func test_rooms_are_big_enough_to_fight_in() -> void:
	for kind in RoomShapes.Kind.values():
		for seed_value in 10:
			var cells := RoomShapes.build(kind, BOUNDS, _rng(seed_value))
			assert_gt(cells.size(), RoomShapes.MIN_THICKNESS * RoomShapes.MIN_THICKNESS, "kind %d" % kind)


func test_shapes_vary_with_the_seed() -> void:
	var a := RoomShapes.build(RoomShapes.Kind.L_SHAPE, BOUNDS, _rng(1))
	var b := RoomShapes.build(RoomShapes.Kind.L_SHAPE, BOUNDS, _rng(2))

	assert_ne(a.keys(), b.keys())


func test_pillars_take_cells_away_but_never_split_the_room() -> void:
	for seed_value in 20:
		var room := RoomShapes.build(RoomShapes.Kind.CROSS, BOUNDS, _rng(seed_value))
		var pillared := RoomShapes.with_pillars(room, 4, _rng(seed_value))
		assert_true(RoomShapes.is_one_piece(pillared), "seed %d" % seed_value)
		for cell: Vector2i in pillared:
			assert_true(room.has(cell))


func test_pillars_keep_clear_of_the_room_edge() -> void:
	var room := RoomShapes.build(RoomShapes.Kind.RECT, BOUNDS, _rng(3))
	var pillared := RoomShapes.with_pillars(room, 4, _rng(3))

	for cell: Vector2i in room:
		var on_edge := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN].any(
			func(step: Vector2i) -> bool: return not room.has(cell + step))
		if on_edge:
			assert_true(pillared.has(cell), "edge cell %s was taken by a pillar" % cell)


func test_a_room_in_two_pieces_is_not_one_piece() -> void:
	assert_false(RoomShapes.is_one_piece({Vector2i(0, 0): true, Vector2i(5, 5): true}))


func test_caves_are_one_piece_inside_their_bounds_and_big_enough() -> void:
	for seed_value in 30:
		var cave := RoomShapes.cave(BOUNDS, _rng(seed_value))
		assert_true(RoomShapes.is_one_piece(cave), "seed %d" % seed_value)
		assert_gt(cave.size(), RoomShapes.MIN_THICKNESS * RoomShapes.MIN_THICKNESS, "seed %d" % seed_value)
		for cell: Vector2i in cave:
			assert_true(BOUNDS.has_point(cell), "seed %d: %s" % [seed_value, cell])


func test_cave_walls_wander_but_the_middle_of_each_side_stays_straight() -> void:
	var cave := RoomShapes.cave(BOUNDS, _rng(4))
	var rows := {}
	for cell: Vector2i in cave:
		rows[cell.y] = mini(rows.get(cell.y, 1000), cell.x)
	var left_edges := rows.values()

	assert_gt(left_edges.max(), left_edges.min(), "the left wall wanders")
	var middle: int = (rows.keys().min() + rows.keys().max()) / 2
	assert_eq(rows[middle - 1], rows[middle])
	assert_eq(rows[middle + 1], rows[middle])
