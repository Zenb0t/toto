extends GutTest

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const ENEMY_DISTANCE := 200.0
const SHOT_SPEED := 400.0
const SHOT_RANGE := 600.0
const FLIGHT_TIME := ENEMY_DISTANCE / SHOT_SPEED + 0.2


func _spawn_enemy_at(position: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = position
	add_child_autofree(enemy)
	return enemy


func _fire_projectile(from: Vector2, direction: Vector2, damage := 1, shot_range := SHOT_RANGE) -> Projectile:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(Shot.new(from, direction, SHOT_SPEED, damage, shot_range))
	add_child_autofree(projectile)
	return projectile


func test_projectile_hurts_an_enemy_in_its_path() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))

	_fire_projectile(Vector2.ZERO, Vector2.RIGHT)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(enemy.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)


func test_a_stronger_shot_does_more_damage() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))

	_fire_projectile(Vector2.ZERO, Vector2.RIGHT, 2)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(enemy.health.current, Enemy.DEFAULT_MAX_HEALTH - 2)


func test_a_shot_fades_before_reaching_an_enemy_beyond_its_range() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))

	_fire_projectile(Vector2.ZERO, Vector2.RIGHT, 1, ENEMY_DISTANCE / 2.0)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(enemy.health.current, Enemy.DEFAULT_MAX_HEALTH)


func test_projectile_aimed_away_leaves_the_enemy_unharmed() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))

	_fire_projectile(Vector2.ZERO, Vector2.LEFT)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(enemy.health.current, Enemy.DEFAULT_MAX_HEALTH)


func test_projectile_disappears_after_hitting_something() -> void:
	_spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))
	var projectile := _fire_projectile(Vector2.ZERO, Vector2.RIGHT)

	await wait_seconds(FLIGHT_TIME)

	assert_false(is_instance_valid(projectile))


func test_enemy_that_runs_out_of_health_announces_it_was_defeated() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))
	watch_signals(enemy)

	enemy.take_damage(Enemy.DEFAULT_MAX_HEALTH)

	assert_signal_emitted(enemy, "defeated")


func test_an_enemy_given_more_health_survives_more_hits() -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.set_max_health(Enemy.DEFAULT_MAX_HEALTH + 2)
	add_child_autofree(enemy)
	watch_signals(enemy)

	enemy.take_damage(Enemy.DEFAULT_MAX_HEALTH)

	assert_signal_not_emitted(enemy, "defeated")


func _fire_fireball(from: Vector2, direction: Vector2, blast_radius: float, shot_range := SHOT_RANGE) -> void:
	var shot := Shot.new(from, direction, SHOT_SPEED, 1, shot_range)
	shot.blast_radius = blast_radius
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(shot)
	add_child_autofree(projectile)


func test_a_fireball_blast_hurts_every_enemy_near_the_impact() -> void:
	var hit := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))
	var bystander := _spawn_enemy_at(Vector2(ENEMY_DISTANCE + 10, 40))

	_fire_fireball(Vector2.ZERO, Vector2.RIGHT, 60.0)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(hit.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)
	assert_eq(bystander.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)


func test_a_fireball_blast_spares_enemies_outside_its_radius() -> void:
	_spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))
	var far_away := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 200))

	_fire_fireball(Vector2.ZERO, Vector2.RIGHT, 60.0)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(far_away.health.current, Enemy.DEFAULT_MAX_HEALTH)


func test_a_fireball_that_runs_out_of_range_still_explodes() -> void:
	var enemy := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))

	_fire_fireball(Vector2.ZERO, Vector2.RIGHT, 60.0, ENEMY_DISTANCE - 40.0)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(enemy.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)


func _swing(arc_degrees: float, sweep_seconds: float) -> SlashEffect:
	var slash := Slash.new(Vector2.ZERO, Vector2.RIGHT, 60.0, arc_degrees, 1, Color.WHITE)
	slash.sweep_seconds = sweep_seconds
	var effect := SlashEffect.new(slash)
	add_child_autofree(effect)
	return effect


func test_a_sword_slash_hits_enemies_in_front_but_not_behind() -> void:
	var in_front := _spawn_enemy_at(Vector2(50, 0))
	var behind := _spawn_enemy_at(Vector2(-50, 0))

	_swing(90.0, 0.0)
	await wait_physics_frames(3)

	assert_eq(in_front.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)
	assert_eq(behind.health.current, Enemy.DEFAULT_MAX_HEALTH)


func test_a_sweep_reaches_the_far_edge_of_its_arc_only_at_the_end() -> void:
	var far_edge := _spawn_enemy_at(Vector2.RIGHT.rotated(deg_to_rad(40)) * 45)

	_swing(90.0, 0.4)
	await wait_seconds(0.1)
	var health_early := far_edge.health.current
	await wait_seconds(0.4)

	assert_eq(health_early, Enemy.DEFAULT_MAX_HEALTH)
	assert_eq(far_edge.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)


func test_a_sweep_hits_each_enemy_only_once() -> void:
	var enemy := _spawn_enemy_at(Vector2(45, 0))

	_swing(180.0, 0.3)
	await wait_seconds(0.5)

	assert_eq(enemy.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)


func _lob(to_distance: float, blast_radius: float) -> void:
	var shot := Shot.new(Vector2.ZERO, Vector2.RIGHT, SHOT_SPEED, 1, to_distance)
	shot.lobbed = true
	shot.blast_radius = blast_radius
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(shot)
	add_child_autofree(projectile)


func test_a_lob_flies_over_enemies_and_bursts_where_it_lands() -> void:
	var in_the_way := _spawn_enemy_at(Vector2(80, 0))
	var at_landing := _spawn_enemy_at(Vector2(ENEMY_DISTANCE, 0))

	_lob(ENEMY_DISTANCE, 40.0)
	await wait_seconds(FLIGHT_TIME)

	assert_eq(in_the_way.health.current, Enemy.DEFAULT_MAX_HEALTH)
	assert_eq(at_landing.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)
