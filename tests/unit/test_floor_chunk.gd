extends GutTest
## The floor is drawn in square pieces, so the ones off screen are skipped.


func _rows(width: int, height: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in height:
		for x in width:
			cells.append(Vector2i(x, y))
	return cells


func test_every_cell_lands_in_exactly_one_piece() -> void:
	var cells := _rows(40, 20)

	var counted := {}
	for piece: Array[Vector2i] in FloorChunk.split(cells):
		for cell in piece:
			counted[cell] = counted.get(cell, 0) + 1

	assert_eq(counted.size(), cells.size())
	for cell: Vector2i in counted:
		assert_eq(counted[cell], 1, str(cell))


func test_a_piece_holds_only_the_cells_of_one_square() -> void:
	for piece: Array[Vector2i] in FloorChunk.split(_rows(40, 20)):
		var square := Vector2i(piece[0].x / FloorChunk.CELLS, piece[0].y / FloorChunk.CELLS)
		for cell in piece:
			assert_eq(Vector2i(cell.x / FloorChunk.CELLS, cell.y / FloorChunk.CELLS), square, str(cell))


func test_a_map_smaller_than_a_piece_is_one_piece() -> void:
	assert_eq(FloorChunk.split(_rows(10, 8)).size(), 1)


func test_cells_with_gaps_between_them_only_make_the_pieces_they_need() -> void:
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(100, 50)]

	assert_eq(FloorChunk.split(cells).size(), 2)


func test_a_piece_hands_its_own_cells_to_whatever_paints_it() -> void:
	var cells: Array[Vector2i] = [Vector2i(3, 4), Vector2i(5, 6)]
	var painted: Array[Vector2i] = []
	var piece: FloorChunk = add_child_autofree(FloorChunk.new(cells, func(_canvas: CanvasItem, given: Array[Vector2i]) -> void:
		painted.assign(given)))

	piece.queue_redraw()
	await wait_physics_frames(2)

	assert_eq(painted, cells)
