extends GutTest


func test_a_cell_centre_lands_in_the_middle_of_its_floor_square() -> void:
	var on_floor := WorldSpace.to_3d(DungeonView.cell_center(Vector2i(3, 5)))

	assert_eq(on_floor, Vector3(3.5, 0.0, 5.5))


func test_height_lifts_a_point_off_the_floor_without_moving_it_across() -> void:
	var lifted := WorldSpace.to_3d(Vector2(64, 32), 2.0)

	assert_eq(lifted, Vector3(2.0, 2.0, 1.0))


func test_lengths_on_the_plane_are_measured_in_cells() -> void:
	assert_eq(WorldSpace.length_to_3d(DungeonView.TILE_SIZE * 3), 3.0)


func test_a_model_turned_toward_a_direction_faces_along_it() -> void:
	for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2(1, 1).normalized()]:
		var front := Basis(Vector3.UP, WorldSpace.yaw_toward(direction)) * Vector3.FORWARD

		assert_almost_eq(front, WorldSpace.to_3d(direction).normalized(), Vector3.ONE * 0.001, str(direction))
