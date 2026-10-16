extends GutTest
## Blink hops past enemies but not through walls; Frost Nova hurts and slows the enemies around you.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const WALL_LAYER_BIT := 1


func _player_with(utility: Utility) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	add_child_autofree(player)
	player.equip_utility(utility)
	return player


func _enemy_at(position: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = position
	add_child_autofree(enemy)
	return enemy


func _wall_at(position: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = WALL_LAYER_BIT
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = position
	add_child_autofree(wall)


## Carries out the player's attacks (the nova) like the game does.
func _carry_out_attacks(player: Player) -> void:
	player.attack_fired.connect(func(attacks: Array) -> void:
		for attack: Variant in attacks:
			if attack is Nova:
				add_child_autofree(NovaEffect.new(attack)))


func _blink(distance: float) -> Blink:
	var blink := Blink.new()
	blink.distance = distance
	return blink


func test_a_blink_moves_the_player_at_once() -> void:
	var player := _player_with(_blink(120.0))

	player.use_utility(Vector2.RIGHT)

	assert_almost_eq(player.position.x, 120.0, 0.5)


func test_a_blink_passes_enemies() -> void:
	var player := _player_with(_blink(120.0))
	_enemy_at(Vector2(60, 0))
	await wait_physics_frames(1)

	player.use_utility(Vector2.RIGHT)

	assert_almost_eq(player.position.x, 120.0, 0.5)


func test_a_wall_stops_a_blink_short() -> void:
	var player := _player_with(_blink(200.0))
	_wall_at(Vector2(100, 0), Vector2(20, 200))
	await wait_physics_frames(1)

	player.use_utility(Vector2.RIGHT)

	assert_lt(player.position.x, 90.0 - Player.RADIUS + 1.0)
	assert_gt(player.position.x, 50.0)


func test_a_frost_nova_hurts_and_slows_enemies_around_you() -> void:
	var player := _player_with(FrostNova.new())
	_carry_out_attacks(player)
	var near := _enemy_at(Vector2(60, 0))
	var far := _enemy_at(Vector2(400, 0))

	player.use_utility(Vector2.RIGHT)
	await wait_process_frames(1)

	assert_lt(near.health.current, near.health.maximum)
	assert_true(near.is_slowed())
	assert_eq(far.health.current, far.health.maximum)
	assert_false(far.is_slowed())


func test_a_slowed_enemy_moves_slower_and_recovers() -> void:
	var player := _player_with(Shield.new())
	player.position = Vector2(600, 0)
	var enemy := _enemy_at(Vector2.ZERO)
	enemy.move_speed = 100.0
	enemy.chase(player)
	enemy.slow(0.5, 0.3)
	await wait_physics_frames(2)

	assert_almost_eq(enemy.velocity.length(), 50.0, 1.0)
	await wait_seconds(0.4)
	assert_false(enemy.is_slowed())
	assert_almost_eq(enemy.velocity.length(), 100.0, 1.0)
