extends GutTest


func test_the_map_grows_to_the_biggest_whole_scale_that_fits() -> void:
	assert_eq(MapOverlay.scale_for(Vector2i(100, 60), Vector2(1200, 640)), 10)


func test_the_tighter_side_decides_the_scale() -> void:
	assert_eq(MapOverlay.scale_for(Vector2i(100, 60), Vector2(1200, 400)), 6, "height is the limit")
	assert_eq(MapOverlay.scale_for(Vector2i(100, 60), Vector2(450, 1000)), 4, "width is the limit")


func test_a_map_bigger_than_the_screen_is_still_drawn_at_one_pixel_per_cell() -> void:
	assert_eq(MapOverlay.scale_for(Vector2i(500, 300), Vector2(400, 300)), 1)


func test_a_tiny_map_is_not_blown_up_past_the_cap() -> void:
	assert_eq(MapOverlay.scale_for(Vector2i(10, 6), Vector2(1200, 640)), MapOverlay.MAX_CELL_PIXELS)
