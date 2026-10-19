extends GutTest
## The floor texture follows the camera: a camera farther back sees more of the floor, so the floor reaches farther.


func test_a_camera_farther_back_gets_a_floor_that_reaches_farther() -> void:
	var ground: GroundView = autofree(GroundView.new())
	var near := ground.reach_cells()

	ground.set_reach(1.5)

	assert_almost_eq(ground.reach_cells(), near * 1.5, Vector2.ONE)


func test_a_camera_closer_than_the_default_keeps_the_default_floor() -> void:
	var ground: GroundView = autofree(GroundView.new())
	var default_reach := ground.reach_cells()

	ground.set_reach(0.5)

	assert_eq(ground.reach_cells(), default_reach)
