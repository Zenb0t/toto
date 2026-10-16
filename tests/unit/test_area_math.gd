extends GutTest

const ORIGIN := Vector2(100, 100)


func test_an_arc_hits_what_is_in_front_and_within_reach() -> void:
	assert_true(HitShapes.in_arc(ORIGIN, Vector2.RIGHT, 50, 90, ORIGIN + Vector2(40, 10)))


func test_an_arc_misses_what_is_behind() -> void:
	assert_false(HitShapes.in_arc(ORIGIN, Vector2.RIGHT, 50, 90, ORIGIN + Vector2(-40, 0)))


func test_an_arc_misses_what_is_out_of_reach() -> void:
	assert_false(HitShapes.in_arc(ORIGIN, Vector2.RIGHT, 50, 90, ORIGIN + Vector2(60, 0)))


func test_an_arc_misses_what_is_just_outside_its_edge() -> void:
	var outside_edge := Vector2.RIGHT.rotated(deg_to_rad(50)) * 30

	assert_false(HitShapes.in_arc(ORIGIN, Vector2.RIGHT, 50, 90, ORIGIN + outside_edge))


func test_a_full_circle_arc_hits_all_around() -> void:
	assert_true(HitShapes.in_arc(ORIGIN, Vector2.RIGHT, 50, 360, ORIGIN + Vector2(-40, 0)))


func test_a_single_shot_flies_straight_whatever_the_spread() -> void:
	assert_eq(Spread.angles_degrees(1, 45.0), [0.0] as Array[float])


func test_a_spread_is_even_and_centred_on_the_aim() -> void:
	assert_eq(Spread.angles_degrees(5, 40.0), [-20.0, -10.0, 0.0, 10.0, 20.0] as Array[float])
