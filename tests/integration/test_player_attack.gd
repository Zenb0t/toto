extends GutTest

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MARGIN := 0.1


func _player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	add_child_autofree(player)
	return player


func _wand_with_windup(windup: float) -> Wand:
	var weapon := Wand.new()
	weapon.windup = windup
	return weapon


func _fired_shot(player: Player) -> Shot:
	var attacks: Array = get_signal_parameters(player, "attack_fired")[0]
	return attacks[0]


func test_attack_does_not_fire_the_instant_the_button_is_released() -> void:
	var player := _player()
	watch_signals(player)

	player.attack(Vector2.RIGHT)

	assert_signal_not_emitted(player, "attack_fired")


func test_attack_fires_after_the_weapons_wind_up() -> void:
	var player := _player()
	watch_signals(player)

	player.attack(Vector2.RIGHT)
	await wait_seconds(player.weapon.windup + MARGIN)

	assert_signal_emitted(player, "attack_fired")
	assert_almost_eq(_fired_shot(player).direction, Vector2.RIGHT, Vector2(0.001, 0.001))


func test_a_weapon_with_a_longer_wind_up_fires_later() -> void:
	var player := _player()
	player.equip_weapon(_wand_with_windup(0.6))
	watch_signals(player)

	player.attack(Vector2.RIGHT)
	await wait_seconds(0.4)
	assert_signal_not_emitted(player, "attack_fired")

	await wait_seconds(0.2 + MARGIN)
	assert_signal_emitted(player, "attack_fired")


func test_a_weapon_without_wind_up_fires_immediately() -> void:
	var player := _player()
	player.equip_weapon(_wand_with_windup(0.0))
	watch_signals(player)

	player.attack(Vector2.RIGHT)

	assert_signal_emitted(player, "attack_fired")


func test_spamming_attack_fires_only_once_per_cooldown() -> void:
	var player := _player()
	watch_signals(player)

	for _tap in 5:
		player.attack(Vector2.UP)
	await wait_seconds(player.weapon.windup + MARGIN)

	assert_signal_emit_count(player, "attack_fired", 1)


func test_shots_carry_the_equipped_weapons_stats() -> void:
	var player := _player()
	var weapon := _wand_with_windup(0.0)
	weapon.shot_damage = 4
	weapon.shot_speed = 900.0
	player.equip_weapon(weapon)
	watch_signals(player)

	player.attack(Vector2.RIGHT)

	var shot := _fired_shot(player)
	assert_eq(shot.damage, 4)
	assert_eq(shot.speed, 900.0)


func test_auto_aimed_attack_tracks_its_target_during_the_wind_up() -> void:
	var player := _player()
	var target := Node2D.new()
	target.position = Vector2(200, 0)
	add_child_autofree(target)
	watch_signals(player)

	player.attack(Vector2.RIGHT, target)
	target.position = Vector2(0, 200)
	await wait_seconds(player.weapon.windup + MARGIN)

	assert_almost_eq(_fired_shot(player).direction, Vector2.DOWN, Vector2(0.01, 0.01))


func test_shot_starts_in_front_of_the_player_not_inside_it() -> void:
	var player := _player()
	watch_signals(player)

	player.attack(Vector2.RIGHT)
	await wait_seconds(player.weapon.windup + MARGIN)

	assert_gt(_fired_shot(player).origin.x - player.global_position.x, Player.RADIUS)


func test_dash_covers_the_equipped_utilitys_distance() -> void:
	var player := _player()
	var start := player.global_position

	player.use_utility(Vector2.RIGHT)
	await wait_seconds(player.utility.dash_duration + MARGIN)

	var expected := player.utility.aim_range()
	assert_almost_eq(player.global_position.x - start.x, expected, expected * 0.15)


func test_a_sword_swings_from_the_player_instead_of_shooting() -> void:
	var player := _player()
	var sword := Sword.new()
	sword.windup = 0.0
	player.equip_weapon(sword)
	watch_signals(player)

	player.attack(Vector2.UP)

	var swing: Slash = get_signal_parameters(player, "attack_fired")[0][0]
	assert_eq(swing.origin, player.global_position)
	assert_eq(swing.direction, Vector2.UP)
