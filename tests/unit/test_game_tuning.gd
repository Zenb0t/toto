extends GutTest


func test_untouched_tuning_builds_the_starter_gear() -> void:
	var tuning := GameTuning.create()
	var starter_weapon := Weapon.new()
	var starter_utility := Utility.new()

	var weapon := GameTuning.weapon(tuning)
	var utility := GameTuning.utility(tuning)

	assert_eq(weapon.cooldown, starter_weapon.cooldown)
	assert_eq(weapon.windup, starter_weapon.windup)
	assert_eq(weapon.shot_speed, starter_weapon.shot_speed)
	assert_eq(weapon.shot_range, starter_weapon.shot_range)
	assert_eq(weapon.shot_damage, starter_weapon.shot_damage)
	assert_eq(utility.dash_speed, starter_utility.dash_speed)
	assert_eq(utility.dash_duration, starter_utility.dash_duration)
	assert_eq(utility.cooldown, starter_utility.cooldown)


func test_untouched_tuning_keeps_the_default_speeds_and_health() -> void:
	var tuning := GameTuning.create()

	assert_eq(GameTuning.player_move_speed(tuning), Player.DEFAULT_MOVE_SPEED)
	assert_eq(GameTuning.enemy_move_speed(tuning), Enemy.DEFAULT_MOVE_SPEED)
	assert_eq(GameTuning.enemy_max_health(tuning), Enemy.DEFAULT_MAX_HEALTH)
	assert_eq(GameTuning.weapon_dead_zone(tuning), AimButton.DEFAULT_DEAD_ZONE)
	assert_eq(GameTuning.utility_dead_zone(tuning), AimButton.DEFAULT_DEAD_ZONE)


func test_tweaked_values_reach_the_gear() -> void:
	var tuning := GameTuning.create()
	tuning.set_value(GameTuning.WEAPON_WINDUP, 0.5)
	tuning.set_value(GameTuning.UTILITY_DASH_SPEED, 900)

	assert_eq(GameTuning.weapon(tuning).windup, 0.5)
	assert_eq(GameTuning.utility(tuning).dash_speed, 900.0)


func test_every_default_is_a_value_its_knob_accepts() -> void:
	var tuning := GameTuning.create()

	for param in tuning.params():
		assert_eq(param.accept(param.default_value), param.default_value, param.key)
