extends GutTest

const TEXTURE_SIZE := Vector2i(400, 300)
const SCALE := 1.5


func test_the_followed_point_is_drawn_in_the_middle_of_the_texture() -> void:
	var window := GroundWindow.new(TEXTURE_SIZE, SCALE)

	window.center_on(Vector2(1234.3, 567.8))

	var drawn_at := window.canvas_transform() * Vector2(1234.3, 567.8)
	assert_almost_eq(drawn_at, Vector2(TEXTURE_SIZE) / 2.0, Vector2.ONE * 0.5)


func test_the_window_covers_exactly_what_the_texture_shows() -> void:
	var window := GroundWindow.new(TEXTURE_SIZE, SCALE)
	window.center_on(Vector2(500, 500))
	var area := window.area()

	assert_almost_eq(window.canvas_transform() * area.position, Vector2.ZERO, Vector2.ONE * 0.001)
	assert_almost_eq(window.canvas_transform() * area.end, Vector2(TEXTURE_SIZE), Vector2.ONE * 0.001)


func test_the_window_moves_in_whole_texture_pixels_so_the_floor_does_not_shimmer() -> void:
	var window := GroundWindow.new(TEXTURE_SIZE, SCALE)

	for point: Vector2 in [Vector2(10.1, 20.7), Vector2(333.33, 87.5), Vector2(-5.2, 0.4)]:
		window.center_on(point)
		var offset := window.canvas_transform().origin

		assert_almost_eq(offset, offset.round(), Vector2.ONE * 0.0001, str(point))
