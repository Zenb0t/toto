extends GutTest


func test_unexplored_cells_are_fully_fogged() -> void:
	var cells: Array[Vector2i] = [Vector2i(1, 1), Vector2i(40, 1)]
	var fog: FogView = autofree(FogView.new(Vector2i(50, 3), cells))
	var exploration := Exploration.new()
	exploration.look_from(Vector2i(1, 1), func(_cell: Vector2i) -> bool: return true)

	fog.show_exploration(exploration)

	assert_eq(fog.fog_at(Vector2i(40, 1)), 1.0)
	assert_eq(fog.fog_at(Vector2i(1, 1)), 0.0, "in view")


func test_remembered_cells_are_dimmed_not_hidden() -> void:
	var cells: Array[Vector2i] = [Vector2i(1, 1), Vector2i(40, 1)]
	var fog: FogView = autofree(FogView.new(Vector2i(50, 3), cells))
	var exploration := Exploration.new()
	var clear := func(_cell: Vector2i) -> bool: return true
	exploration.look_from(Vector2i(1, 1), clear)
	exploration.look_from(Vector2i(40, 1), clear)

	fog.show_exploration(exploration)

	assert_between(fog.fog_at(Vector2i(1, 1)), 0.1, 0.9)
