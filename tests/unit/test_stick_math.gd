extends GutTest

const ORIGIN := Vector2(100, 100)
const RADIUS := 50.0


func test_finger_on_the_origin_means_no_movement() -> void:
	assert_eq(StickMath.strength(ORIGIN, ORIGIN, RADIUS), Vector2.ZERO)


func test_strength_grows_with_distance_from_the_origin() -> void:
	var halfway := StickMath.strength(ORIGIN, ORIGIN + Vector2(25, 0), RADIUS)

	assert_almost_eq(halfway, Vector2(0.5, 0), Vector2(0.001, 0.001))


func test_strength_is_capped_at_full_beyond_the_radius() -> void:
	var far_up := StickMath.strength(ORIGIN, ORIGIN + Vector2(0, -400), RADIUS)

	assert_almost_eq(far_up, Vector2(0, -1), Vector2(0.001, 0.001))
