extends GutTest


func test_the_starter_wand_fires_one_shot_where_it_is_aimed() -> void:
	var shots := Weapon.new().shots(Vector2(10, 20), Vector2(0, -5))

	assert_eq(shots.size(), 1)
	assert_eq(shots[0].origin, Vector2(10, 20))
	assert_eq(shots[0].direction, Vector2.UP)


func test_a_shot_flies_for_as_long_as_its_range_allows() -> void:
	var weapon := Weapon.new()
	weapon.shot_speed = 200.0
	weapon.shot_range = 500.0

	assert_eq(weapon.shots(Vector2.ZERO, Vector2.RIGHT)[0].lifetime(), 2.5)


func test_the_dash_preview_shows_how_far_one_dash_goes() -> void:
	var utility := Utility.new()
	utility.dash_speed = 600.0
	utility.dash_duration = 0.2

	assert_eq(utility.aim_range(), 120.0)
