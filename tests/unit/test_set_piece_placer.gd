extends GutTest
## The set-piece placer finds a spot for each piece by its rules and stamps it there.

var _recipe := QuadrantRecipe.plains()


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _gate() -> SetPiece:
	return SetPiece.new("gate", PackedStringArray(["#.#", "#>#"]), ">", 0.6, 1)


func test_a_piece_lands_as_far_out_as_it_asks_and_clear_of_the_start() -> void:
	for seed_value in 30:
		var placements := SetPiecePlacer.reserve(_recipe, [_gate()], [], _rng(seed_value))

		assert_eq(placements.size(), 1, "seed %d" % seed_value)
		var anchor := placements[0].anchor_cell()
		assert_gte(_recipe.outward(anchor), 0.6, "seed %d" % seed_value)
		assert_gt(Vector2(anchor - _recipe.center()).length(), _recipe.safe_ring, "seed %d" % seed_value)
		assert_true(_recipe.interior().encloses(placements[0].rect().grow(1)), "seed %d" % seed_value)


func test_pieces_keep_clear_of_each_other_and_of_the_areas_they_are_told_to_avoid() -> void:
	var avoid: Array[Rect2i] = [Rect2i(0, 0, _recipe.width / 2, _recipe.height)]
	var two: Array[SetPiece] = [_gate(), _gate()]

	for seed_value in 20:
		var placements := SetPiecePlacer.reserve(_recipe, two, avoid, _rng(seed_value))

		assert_eq(placements.size(), 2, "seed %d" % seed_value)
		assert_false(placements[0].rect().grow(1).intersects(placements[1].rect().grow(1)), "seed %d" % seed_value)
		for placement in placements:
			assert_false(placement.rect().grow(1).intersects(avoid[0]), "seed %d" % seed_value)


func test_a_piece_that_fits_nowhere_is_left_without_a_spot() -> void:
	var impossible := SetPiece.new("far", PackedStringArray(["#>#"]), ">", 1.5)

	var placements := SetPiecePlacer.reserve(_recipe, [impossible], [], _rng(1))

	assert_eq(placements.size(), 0)


func test_stamping_draws_the_piece_and_clears_the_ground_around_it() -> void:
	var grid := QuadrantGrid.new(Vector2i(20, 20), QuadrantGrid.GROVE)
	var placement := SetPiecePlacer.Placement.new(_gate(), Vector2i(8, 8))

	SetPiecePlacer.stamp(grid, placement)

	assert_eq(grid.at(Vector2i(9, 9)), ">")
	assert_eq(grid.at(Vector2i(8, 8)), "#")
	assert_eq(grid.at(Vector2i(9, 8)), ".", "the gap in the piece's own drawing")
	assert_eq(grid.at(Vector2i(7, 7)), ".", "the apron is plain ground")
	assert_eq(grid.at(Vector2i(10, 10)), ".")
	assert_eq(grid.at(Vector2i(5, 5)), "T", "further out is untouched")
