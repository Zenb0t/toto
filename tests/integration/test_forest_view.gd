extends GutTest
## Outdoors, tree groves are drawn as trees (ForestView, through MapView3D) rather than as blocks, and show like
## walls do: hidden until seen, dimmed when out of sight, shrunk in front of the hero.

const SIZE := 24
## A square wood, 12 cells wide, in the middle of a grass field.
const WOOD := Rect2i(6, 6, 12, 12)
const EDGE := Vector2i(6, 10)
const DEEP_EVEN := Vector2i(12, 12)
const DEEP_ODD := Vector2i(12, 11)


func _field() -> DungeonMap:
	var rows := PackedStringArray()
	for y in SIZE:
		var row := ""
		for x in SIZE:
			if Vector2i(x, y) == Vector2i(1, 1):
				row += "P"
			else:
				row += "T" if WOOD.has_point(Vector2i(x, y)) else "."
		rows.append(row)
	return DungeonMapParser.new().parse("\n".join(rows))


func _walls_of(map: DungeonMap) -> Array[Vector2i]:
	var walls: Array[Vector2i] = []
	for y in map.size.y:
		for x in map.size.x:
			var cell := Vector2i(x, y)
			if not map.is_open(cell):
				walls.append(cell)
	return walls


func _view_of(map: DungeonMap) -> MapView3D:
	var view: MapView3D = autofree(MapView3D.new())
	view.show_map(map, _walls_of(map), BranchLook.plains())
	return view


func test_every_tree_cell_near_open_ground_gets_a_tree() -> void:
	var cells := ForestView.tree_cells(_field())

	for y in range(WOOD.position.y, WOOD.end.y):
		for x in range(WOOD.position.x, WOOD.end.x):
			var cell := Vector2i(x, y)
			var depth := mini(mini(x - WOOD.position.x, WOOD.end.x - 1 - x), mini(y - WOOD.position.y, WOOD.end.y - 1 - y))
			if depth < ForestView.EDGE_DEPTH:
				assert_has(cells, cell, str(cell))


func test_deep_in_a_wood_every_other_cell_gets_a_tree() -> void:
	var cells := ForestView.tree_cells(_field())

	assert_has(cells, DEEP_EVEN)
	assert_does_not_have(cells, DEEP_ODD)


func test_groves_stand_as_trees_not_blocks() -> void:
	var view := _view_of(_field())

	assert_true(view.has_tree(EDGE))
	assert_eq(view.tree_count(), ForestView.tree_cells(_field()).size())


func test_a_tree_in_sight_is_lit_and_one_never_seen_is_hidden() -> void:
	var view := _view_of(_field())
	var exploration := Exploration.new()
	exploration.look_from(EDGE + Vector2i.LEFT * 2, func(cell: Vector2i) -> bool: return not WOOD.has_point(cell))

	view.show_exploration(exploration)

	assert_eq(view.shown_brightness(EDGE), MapView3D.LIT)
	assert_eq(view.shown_brightness(DEEP_EVEN), MapView3D.HIDDEN)


func test_a_wood_known_from_the_start_shows_dimmed_until_in_sight() -> void:
	var map := _field()
	var view := _view_of(map)
	var exploration := Exploration.new()
	exploration.restore(map.cells_with_blocker(DungeonMap.Blocker.GROVE))

	view.show_exploration(exploration)

	assert_almost_eq(view.shown_brightness(DEEP_EVEN), MapView3D.REMEMBERED_BRIGHTNESS, 0.001)


func test_a_tree_between_the_camera_and_the_hero_is_cut_down() -> void:
	var view := _view_of(_field())
	var exploration := Exploration.new()
	exploration.look_from(Vector2i(10, 4), func(cell: Vector2i) -> bool: return not WOOD.has_point(cell))
	view.show_exploration(exploration)

	view.show_hero_at(Vector2i(10, 5))

	assert_true(view.is_cut_away(Vector2i(10, 6)), "the tree just below the hero, toward the camera")
	assert_false(view.is_cut_away(EDGE), "a tree off to the side")
