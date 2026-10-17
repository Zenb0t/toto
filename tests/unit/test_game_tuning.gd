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
	assert_eq(GameTuning.enemy_health_multiplier(tuning), Enemy.DEFAULT_HEALTH_MULTIPLIER)
	assert_eq(GameTuning.weapon_dead_zone(tuning), AimButton.ATTACK_DEAD_ZONE)
	assert_eq(GameTuning.utility_dead_zone(tuning), AimButton.DEFAULT_DEAD_ZONE)


func test_each_weapon_keeps_its_own_settings() -> void:
	var tuning := GameTuning.create()

	tuning.set_value(GameTuning.key("sword", "windup"), 0.5)

	assert_eq(GameTuning.weapon(tuning, "sword").windup, 0.5)
	assert_eq(GameTuning.weapon(tuning, "wand").windup, MagicMissile.new().windup)


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


func _section(title: String, sections: Array[TuningSection]) -> TuningSection:
	for section in sections:
		if section.title == title:
			return section
	return null


func test_every_knob_belongs_to_exactly_one_entry_of_the_tune_menu() -> void:
	var tuning := GameTuning.create()
	var listed: Array[String] = []
	for section in GameTuning.sections("wand", "dash"):
		listed.append_array(section.groups)

	for param in tuning.params():
		assert_eq(listed.count(param.group), 1, param.key)


func test_every_weapon_has_its_own_page_under_weapons_with_the_equipped_one_marked() -> void:
	var weapons := _section("Weapons", GameTuning.sections("fireball", "shield"))

	assert_true(weapons.has_submenu())
	assert_eq(weapons.groups.size(), GameTuning.weapon_ids().size())
	assert_string_contains(weapons.label_of(GameTuning.weapon_group("fireball")), "equipped")
	assert_eq(weapons.label_of(GameTuning.weapon_group("sword")), "Sword")


func test_enemies_open_straight_onto_their_knobs() -> void:
	var enemies := _section("Enemies", GameTuning.sections("wand", "dash"))

	assert_false(enemies.has_submenu())


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


func test_enemies_wield_the_same_weapon_with_one_slow_charge_and_a_longer_wind_up() -> void:
	var tuning := GameTuning.create()
	tuning.set_value(GameTuning.ENEMY_COOLDOWN_MULTIPLIER, 2.0)
	tuning.set_value(GameTuning.ENEMY_TELEGRAPH, 0.5)

	var players := GameTuning.weapon(tuning, "crossbow")
	var enemys := GameTuning.enemy_weapon(tuning, "crossbow")

	assert_eq(enemys.bolts, players.bolts)
	assert_eq(enemys.ammo, 1)
	assert_almost_eq(enemys.reload, players.reload * 2.0, 0.001)
	assert_almost_eq(enemys.windup, players.windup + 0.5, 0.001)


func test_loot_ids_build_the_matching_kind_of_item() -> void:
	var tuning := GameTuning.create()

	assert_true(GameTuning.item(tuning, "sword") is Weapon)
	assert_true(GameTuning.item(tuning, "shield") is Utility)


func test_camera_knobs_shape_the_framing() -> void:
	var tuning := GameTuning.create()

	tuning.set_value(GameTuning.CAMERA_PITCH, 70)
	tuning.set_value(GameTuning.CAMERA_DISTANCE, 12)
	var framing := GameTuning.camera_framing(tuning)

	assert_eq(framing.pitch_degrees, 70.0)
	assert_eq(framing.distance, 12.0)
	assert_eq(framing.field_of_view, CameraFraming.DEFAULT_FIELD_OF_VIEW)
	assert_eq(GameTuning.wall_height(tuning), MapView3D.DEFAULT_WALL_HEIGHT)


func test_heal_is_no_longer_a_utility_it_is_a_potion() -> void:
	assert_does_not_have(GameTuning.utility_ids(), "heal")
	assert_has(GameTuning.potion_ids(), "healing")


func test_each_potion_keeps_its_own_settings() -> void:
	var tuning := GameTuning.create()

	tuning.set_value(GameTuning.key("healing", "amount"), 700)

	assert_eq((GameTuning.potion(tuning, "healing") as HealingPotion).amount, 700)
	assert_eq(GameTuning.potion(tuning, "haste").id, "haste")


func test_healing_potions_turn_up_more_often_than_the_others() -> void:
	var weights := GameTuning.potion_weights()

	assert_gt(weights["healing"], weights["haste"])
	assert_gt(weights["healing"], weights["might"])


func test_damage_and_healing_knobs_count_health_points() -> void:
	var keys := GameTuning.points_keys()

	assert_has(keys, GameTuning.key("sword", "damage"))
	assert_has(keys, GameTuning.key("healing", "amount"))
	assert_does_not_have(keys, GameTuning.key("sword", "windup"))


func test_two_punches_do_what_one_magic_missile_does() -> void:
	assert_eq(Knuckles.new().damage * 2, MagicMissile.new().shot_damage)


func test_the_bow_is_among_the_weapons_the_player_can_find() -> void:
	assert_has(GameTuning.weapon_ids(), "bow")
	assert_eq(GameTuning.weapon(GameTuning.create(), "bow").id, "bow")
