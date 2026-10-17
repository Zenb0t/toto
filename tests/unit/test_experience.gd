extends GutTest


func test_a_hero_starts_at_level_one() -> void:
	assert_eq(Experience.new().level(), 1)


func test_enough_points_bring_a_level() -> void:
	var experience := Experience.new()

	var gained := experience.gain(Experience.points_for(2))

	assert_eq(gained, 1)
	assert_eq(experience.level(), 2)


func test_a_big_kill_can_bring_several_levels_at_once() -> void:
	var experience := Experience.new()

	assert_eq(experience.gain(Experience.points_for(4)), 3)


func test_every_level_needs_more_points_than_the_one_before() -> void:
	for level in range(2, Experience.MAX_LEVEL):
		var this_step := Experience.points_for(level + 1) - Experience.points_for(level)
		var last_step := Experience.points_for(level) - Experience.points_for(level - 1)
		assert_gt(this_step, last_step, str(level))


func test_levels_stop_at_the_top() -> void:
	var experience := Experience.new()

	experience.gain(100000)

	assert_eq(experience.level(), Experience.MAX_LEVEL)
	assert_eq(experience.progress(), 1.0)


func test_progress_shows_how_close_the_next_level_is() -> void:
	var experience := Experience.new()
	var halfway := (Experience.points_for(2) + 1) / 2

	experience.gain(halfway)

	assert_almost_eq(experience.progress(), float(halfway) / Experience.points_for(2), 0.001)


func test_each_level_adds_health() -> void:
	assert_eq(Experience.bonus_health(1), 0)
	assert_eq(Experience.bonus_health(3), 2 * Experience.HEALTH_PER_LEVEL)
