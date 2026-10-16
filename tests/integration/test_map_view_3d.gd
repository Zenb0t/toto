extends GutTest

const NEAR_WALL := Vector2i(2, 0)
const FAR_WALL := Vector2i(60, 0)
const DOOR := Vector2i(4, 0)


func _map_view() -> MapView3D:
	var view: MapView3D = autofree(MapView3D.new())
	var walls: Array[Vector2i] = [NEAR_WALL, FAR_WALL]
	var doors: Array[Vector2i] = [DOOR]
	view.show_map(walls, doors)
	return view


## Nothing blocks sight, so what is in view depends only on distance.
func _looking_from(origin: Vector2i, exploration := Exploration.new()) -> Exploration:
	exploration.look_from(origin, func(_cell: Vector2i) -> bool: return true)
	return exploration


func test_walls_in_sight_stand_lit() -> void:
	var view := _map_view()

	view.show_exploration(_looking_from(Vector2i(2, 3)))

	assert_true(view.is_standing(NEAR_WALL))
	assert_eq(view.brightness(NEAR_WALL), MapView3D.LIT)


func test_walls_never_seen_are_not_shown() -> void:
	var view := _map_view()

	view.show_exploration(_looking_from(Vector2i(2, 3)))

	assert_false(view.is_standing(FAR_WALL))


func test_walls_seen_before_but_out_of_sight_are_dimmed() -> void:
	var view := _map_view()
	var exploration := _looking_from(Vector2i(2, 3))

	view.show_exploration(_looking_from(Vector2i(60, 3), exploration))

	assert_true(view.is_standing(NEAR_WALL))
	assert_lt(view.brightness(NEAR_WALL), view.brightness(FAR_WALL))


func test_a_door_stands_only_while_it_is_closed() -> void:
	var view := _map_view()
	var doors: Array[Vector2i] = [DOOR]
	assert_false(view.is_standing(DOOR), "open at first")

	view.set_doors_closed(doors, true)
	assert_true(view.is_standing(DOOR), "closed")

	view.set_doors_closed(doors, false)
	assert_false(view.is_standing(DOOR), "open again")


func test_floor_cells_have_no_block() -> void:
	var view := _map_view()

	assert_false(view.is_standing(Vector2i(3, 3)))
