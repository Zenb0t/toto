extends GutTest

const HERO := Vector3(10.0, 0.0, 20.0)


func test_the_camera_looks_down_at_the_hero_from_the_bottom_of_the_screen() -> void:
	var eye := CameraFraming.new().eye(HERO)

	assert_gt(eye.y, HERO.y, "above")
	assert_gt(eye.z, HERO.z, "toward the bottom of the screen")
	assert_eq(eye.x, HERO.x, "never turned sideways")


func test_the_camera_aims_ahead_of_the_hero() -> void:
	var framing := CameraFraming.new()
	framing.look_ahead = 2.0

	assert_eq(framing.target(HERO), HERO + Vector3(0.0, 0.0, -2.0))


func test_the_camera_keeps_its_distance_from_where_it_aims() -> void:
	var framing := CameraFraming.new()
	framing.distance = 12.0

	assert_almost_eq(framing.eye(HERO).distance_to(framing.target(HERO)), 12.0, 0.001)


func test_a_steeper_tilt_moves_the_camera_overhead() -> void:
	var shallow := CameraFraming.new()
	shallow.pitch_degrees = 40.0
	var steep := CameraFraming.new()
	steep.pitch_degrees = 80.0

	assert_lt(steep.eye(HERO).z, shallow.eye(HERO).z)
	assert_gt(steep.eye(HERO).y, shallow.eye(HERO).y)


func test_a_top_down_tilt_puts_the_camera_straight_above_its_aim() -> void:
	var framing := CameraFraming.new()
	framing.pitch_degrees = 90.0
	var eye := framing.eye(HERO)
	var target := framing.target(HERO)

	assert_almost_eq(Vector2(eye.x, eye.z), Vector2(target.x, target.z), Vector2.ONE * 0.001)
