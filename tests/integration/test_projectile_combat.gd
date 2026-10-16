extends GutTest

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const ENEMY_DISTANCE := 200.0
## Long enough for a shot to cross ENEMY_DISTANCE at whatever speed projectiles are tuned to.
const FLIGHT_TIME := ENEMY_DISTANCE / Projectile.SPEED + 0.2


func _spawn_enemy_at(position: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = position
	add_child_autofree(enemy)
	return enemy


func _fire_projectile(from: Vector2, direction: Vector2) -> Projectile:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(from, direction)
	add_child_autofree(projectile)
	return projectile


func test_projectile_hurts_an_enemy_in_its_path() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))

	_fire_projectile(Vector2.ZERO, Vector2.RIGHT)
	await wait_seconds(FLIGHT_TIME)

	assert_lt(enemy.health.current, Enemy.MAX_HEALTH)


func test_projectile_aimed_away_leaves_the_enemy_unharmed() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))

	_fire_projectile(Vector2.ZERO, Vector2.LEFT)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(enemy.health.current, Enemy.MAX_HEALTH)


func test_projectile_disappears_after_hitting_something() -> void:
	_spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))
	var projectile := _fire_projectile(Vector2.ZERO, Vector2.RIGHT)

	await wait_seconds(FLIGHT_TIME)

	assert_false(is_instance_valid(projectile))


func test_enemy_that_runs_out_of_health_announces_it_was_defeated() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))
	watch_signals(enemy)

	enemy.take_damage(Enemy.MAX_HEALTH)

	assert_signal_emitted(enemy, "defeated")
