extends GutTest

const PLAYER_SCENE := preload("res://scenes/player.tscn")


func _player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	add_child_autofree(player)
	return player


func test_attack_does_not_fire_the_instant_the_button_is_released() -> void:
	var player := _player()
	watch_signals(player)

	player.attack(Vector2.RIGHT)

	assert_signal_not_emitted(player, "attack_fired")


func test_attack_fires_after_a_short_wind_up() -> void:
	var player := _player()
	watch_signals(player)

	player.attack(Vector2.RIGHT)
	await wait_seconds(Player.ATTACK_WINDUP + 0.1)

	assert_signal_emitted(player, "attack_fired")
	var fired_direction: Vector2 = get_signal_parameters(player, "attack_fired")[1]
	assert_almost_eq(fired_direction, Vector2.RIGHT, Vector2(0.001, 0.001))


func test_spamming_attack_fires_only_once_per_cooldown() -> void:
	var player := _player()
	watch_signals(player)

	for _tap in 5:
		player.attack(Vector2.UP)
	await wait_seconds(Player.ATTACK_WINDUP + 0.1)

	assert_signal_emit_count(player, "attack_fired", 1)


func test_auto_aimed_attack_tracks_its_target_during_the_wind_up() -> void:
	var player := _player()
	var target := Node2D.new()
	target.position = Vector2(200, 0)
	add_child_autofree(target)
	watch_signals(player)

	player.attack(Vector2.RIGHT, target)
	target.position = Vector2(0, 200)
	await wait_seconds(Player.ATTACK_WINDUP + 0.1)

	var fired_direction: Vector2 = get_signal_parameters(player, "attack_fired")[1]
	assert_almost_eq(fired_direction, Vector2.DOWN, Vector2(0.01, 0.01))


func test_shot_starts_in_front_of_the_player_not_inside_it() -> void:
	var player := _player()
	watch_signals(player)

	player.attack(Vector2.RIGHT)
	await wait_seconds(Player.ATTACK_WINDUP + 0.1)

	var origin: Vector2 = get_signal_parameters(player, "attack_fired")[0]
	assert_gt(origin.x - player.global_position.x, Player.RADIUS)
