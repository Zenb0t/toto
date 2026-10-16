extends GutTest


func test_untouched_tuning_builds_every_weapon_with_its_own_defaults() -> void:
	var tuning := GameTuning.create()

	for fresh in GameTuning.weapons():
		var built := GameTuning.weapon(tuning, fresh.id)
		for knob in fresh.knobs():
			assert_eq(built.get(knob.field), fresh.get(knob.field), "%s.%s" % [fresh.id, knob.field])


func test_untouched_tuning_builds_the_default_utility_and_values() -> void:
	var tuning := GameTuning.create()
	var dash := GameTuning.utility(tuning, "dash")

	assert_eq(dash.cooldown, Dash.new().cooldown)
	assert_eq(GameTuning.player_move_speed(tuning), Player.DEFAULT_MOVE_SPEED)
	assert_eq(GameTuning.enemy_move_speed(tuning), Enemy.DEFAULT_MOVE_SPEED)
	assert_eq(GameTuning.enemy_max_health(tuning), Enemy.DEFAULT_MAX_HEALTH)
	assert_eq(GameTuning.weapon_dead_zone(tuning), AimButton.DEFAULT_DEAD_ZONE)
	assert_eq(GameTuning.utility_dead_zone(tuning), AimButton.DEFAULT_DEAD_ZONE)


func test_each_weapon_keeps_its_own_settings() -> void:
	var tuning := GameTuning.create()

	tuning.set_value(GameTuning.key("sword", "windup"), 0.5)

	assert_eq(GameTuning.weapon(tuning, "sword").windup, 0.5)
	assert_eq(GameTuning.weapon(tuning, "wand").windup, Wand.new().windup)


func test_whole_number_settings_stay_whole() -> void:
	var tuning := GameTuning.create()

	tuning.set_value(GameTuning.key("crossbow", "bolts"), 5)

	var bolts: Variant = GameTuning.weapon(tuning, "crossbow").bolts
	assert_true(bolts is int)
	assert_eq(bolts, 5)


func test_an_unknown_weapon_falls_back_to_the_starter_wand() -> void:
	assert_eq(GameTuning.weapon(GameTuning.create(), "banana").id, "wand")


func test_the_quick_switch_visits_every_weapon_and_wraps_around() -> void:
	var visited: Array[String] = []
	var current := GameTuning.DEFAULT_WEAPON_ID
	for _step in GameTuning.weapon_ids().size():
		visited.append(current)
		current = GameTuning.next_weapon_id(current)

	assert_eq(visited, GameTuning.weapon_ids())
	assert_eq(current, GameTuning.DEFAULT_WEAPON_ID)


func test_the_tune_screen_shows_only_the_equipped_weapon_and_utility() -> void:
	var tuning := GameTuning.create()

	var groups := GameTuning.visible_groups(tuning, "fireball", "shield")

	assert_has(groups, GameTuning.weapon_group("fireball"))
	assert_does_not_have(groups, GameTuning.weapon_group("wand"))
	assert_has(groups, GameTuning.utility_group("shield"))
	assert_does_not_have(groups, GameTuning.utility_group("dash"))
	assert_has(groups, "Player")


func test_every_default_is_a_value_its_knob_accepts() -> void:
	var tuning := GameTuning.create()

	for param in tuning.params():
		assert_almost_eq(param.accept(param.default_value), param.default_value, 0.0001, param.key)


func test_untouched_tuning_builds_every_utility_with_its_own_defaults() -> void:
	var tuning := GameTuning.create()

	for fresh in GameTuning.utilities():
		var built := GameTuning.utility(tuning, fresh.id)
		for knob in fresh.knobs():
			assert_eq(built.get(knob.field), fresh.get(knob.field), "%s.%s" % [fresh.id, knob.field])


func test_enemies_wield_the_same_weapon_slower_and_with_a_longer_wind_up() -> void:
	var tuning := GameTuning.create()
	tuning.set_value(GameTuning.ENEMY_COOLDOWN_MULTIPLIER, 2.0)
	tuning.set_value(GameTuning.ENEMY_TELEGRAPH, 0.5)

	var players := GameTuning.weapon(tuning, "crossbow")
	var enemys := GameTuning.enemy_weapon(tuning, "crossbow")

	assert_eq(enemys.bolts, players.bolts)
	assert_almost_eq(enemys.cooldown, players.cooldown * 2.0, 0.001)
	assert_almost_eq(enemys.windup, players.windup + 0.5, 0.001)


func test_loot_ids_build_the_matching_kind_of_item() -> void:
	var tuning := GameTuning.create()

	assert_true(GameTuning.item(tuning, "sword") is Weapon)
	assert_true(GameTuning.item(tuning, "heal") is Utility)
