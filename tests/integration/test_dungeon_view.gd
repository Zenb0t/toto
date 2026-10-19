extends GutTest
## The floor and its liquids are drawn in square pieces that, together, cover the map's drawn cells once.

## A hall wider than one floor piece, with a pool in the middle.
const WIDTH := 40


func _hall() -> DungeonMap:
	var rows := PackedStringArray(["#".repeat(WIDTH)])
	for y in 6:
		var row := "#" + ".".repeat(WIDTH - 2) + "#"
		if y >= 2 and y <= 3:
			row = "#" + ".".repeat(14) + "~".repeat(6) + ".".repeat(WIDTH - 22) + "#"
		rows.append(row)
	rows.append("#".repeat(WIDTH))
	rows[1] = "#P" + rows[1].substr(2)
	return DungeonMapParser.new().parse("\n".join(rows))


func _view(map: DungeonMap) -> DungeonView:
	var view: DungeonView = add_child_autofree(DungeonView.new())
	view.show_map(map)
	return view


func _cells_of(pieces: Array[FloorChunk]) -> Dictionary:
	var counted := {}
	for piece in pieces:
		for cell in piece.cells():
			counted[cell] = counted.get(cell, 0) + 1
	return counted


func _ground(view: DungeonView) -> Array[FloorChunk]:
	return view.floor_pieces().filter(func(piece: FloorChunk) -> bool: return piece.material == null)


func test_the_ground_pieces_cover_every_drawn_cell_once() -> void:
	var view := _view(_hall())
	var pieces: Array[FloorChunk] = []
	pieces.assign(_ground(view))

	var counted := _cells_of(pieces)

	assert_gt(pieces.size(), 1, "a hall wider than a piece is split")
	assert_eq(counted.size(), view.drawn_cells().size())
	for cell in view.drawn_cells():
		assert_eq(counted.get(cell, 0), 1, str(cell))


func test_deep_water_is_drawn_over_its_cells_with_one_set_of_waves() -> void:
	var map := _hall()
	var view := _view(map)
	var water: Array[FloorChunk] = []
	water.assign(view.floor_pieces().filter(func(piece: FloorChunk) -> bool: return piece.material != null))

	var counted := _cells_of(water)

	assert_eq(counted.size(), map.cells_with(DungeonMap.Terrain.WATER).size())
	assert_gt(water.size(), 1, "the pool straddles two pieces")
	for piece in water:
		assert_eq(piece.material, water[0].material, "the waves run on across the pieces")


func test_the_ground_is_drawn_under_the_water() -> void:
	var view := _view(_hall())
	var pieces := view.floor_pieces()

	var last_ground := -1
	var first_water := pieces.size()
	for i in pieces.size():
		if pieces[i].material == null:
			last_ground = i
		else:
			first_water = mini(first_water, i)

	assert_lt(last_ground, first_water)
