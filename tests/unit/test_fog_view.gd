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


func test_covering_only_what_a_step_changed_matches_covering_everything() -> void:
	var cells: Array[Vector2i] = []
	for x in 50:
		cells.append(Vector2i(x, 1))
	var stepped: FogView = autofree(FogView.new(Vector2i(50, 3), cells))
	var whole: FogView = autofree(FogView.new(Vector2i(50, 3), cells))
	var exploration := Exploration.new()
	var clear := func(_cell: Vector2i) -> bool: return true
	exploration.look_from(Vector2i(1, 1), clear)
	stepped.show_exploration(exploration)

	for x in [5, 12, 30, 44]:
		exploration.look_from(Vector2i(x, 1), clear)
		stepped.show_changes(exploration)
	whole.show_exploration(exploration)

	for cell in cells:
		assert_eq(stepped.fog_at(cell), whole.fog_at(cell), str(cell))
