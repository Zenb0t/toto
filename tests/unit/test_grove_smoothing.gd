extends GutTest
## Woods are rounded off: no stray specks of trees, no holes or nooks inside a wood.


func _grid(rows: Array[String]) -> QuadrantGrid:
	var grid := QuadrantGrid.new(Vector2i(rows[0].length(), rows.size()))
	for y in rows.size():
		for x in rows[y].length():
			grid.put(Vector2i(x, y), rows[y][x])
	return grid


func _smoothed(rows: Array[String], passes := 1) -> QuadrantGrid:
	var grid := _grid(rows)
	GroveSmoothing.smooth(grid, Rect2i(Vector2i.ZERO, grid.size), passes)
	return grid


func test_a_tree_standing_alone_is_cleared() -> void:
	var grid := _smoothed([
		".....",
		".....",
		"..T..",
		".....",
		".....",
	])

	assert_eq(grid.at(Vector2i(2, 2)), QuadrantGrid.GRASS)


func test_a_hole_inside_a_wood_fills_with_trees() -> void:
	var grid := _smoothed([
		"TTTTT",
		"TTTTT",
		"TT.TT",
		"TTTTT",
		"TTTTT",
	])

	assert_eq(grid.at(Vector2i(2, 2)), QuadrantGrid.GROVE)


func test_the_inside_of_a_solid_wood_stays_trees() -> void:
	var grid := _smoothed([
		".......",
		".TTTTT.",
		".TTTTT.",
		".TTTTT.",
		".......",
	], 2)

	assert_eq(grid.at(Vector2i(3, 2)), QuadrantGrid.GROVE)


func test_water_and_rocks_are_left_as_they_are() -> void:
	var grid := _smoothed([
		"TTT",
		"T~T",
		"TBT",
		"TTT",
	])

	assert_eq(grid.at(Vector2i(1, 1)), QuadrantGrid.DEEP_WATER)
	assert_eq(grid.at(Vector2i(1, 2)), QuadrantGrid.BOULDER)
