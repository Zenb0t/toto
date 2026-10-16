extends GutTest
## Lightning bolts pierce and bounce, poison clouds linger, and beckoning pulls.

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const WALL_LAYER_BIT := 1


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


func _fire(shot: Shot) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(shot)
	add_child_autofree(projectile)


func _bolt(from: Vector2, direction: Vector2) -> Shot:
	var weapon := LightningBolt.new()
	weapon.shot_speed = 1000.0
	return weapon.attacks(from, direction, 0.0)[0]


func test_a_lightning_bolt_hurts_every_enemy_in_its_line() -> void:
	var first := _enemy_at(Vector2(100, 0))
	var second := _enemy_at(Vector2(200, 0))
	await wait_physics_frames(1)

	_fire(_bolt(Vector2.ZERO, Vector2.RIGHT))
	await wait_seconds(0.4)

	assert_lt(first.health.current, first.health.maximum)
	assert_lt(second.health.current, second.health.maximum)


func test_a_lightning_bolt_hits_each_enemy_only_once() -> void:
	var enemy := _enemy_at(Vector2(100, 0))
	await wait_physics_frames(1)

	_fire(_bolt(Vector2.ZERO, Vector2.RIGHT))
	await wait_seconds(0.6)

	assert_eq(enemy.health.current, enemy.health.maximum - LightningBolt.new().damage)


func test_a_lightning_bolt_bounces_off_a_wall_and_comes_back() -> void:
	_wall_at(Vector2(150, 0), Vector2(20, 300))
	var behind := _enemy_at(Vector2(-80, 0))
	await wait_physics_frames(1)

	_fire(_bolt(Vector2.ZERO, Vector2.RIGHT))
	await wait_seconds(0.5)

	assert_lt(behind.health.current, behind.health.maximum)


func test_a_poison_cloud_keeps_hurting_enemies_inside_it_then_dissipates() -> void:
	var inside := _enemy_at(Vector2(20, 0))
	inside.set_physics_process(false)
	var outside := _enemy_at(Vector2(300, 0))
	var cloud := PoisonCloud.new(60.0, 1, 1.0, false)
	add_child(cloud)

	await wait_seconds(PoisonCloud.TICK_SECONDS * 1.5)
	assert_eq(inside.health.current, inside.health.maximum - 2, "a tick at once, then another")
	assert_eq(outside.health.current, outside.health.maximum)
	await wait_seconds(1.0)
	assert_false(is_instance_valid(cloud))


func test_beckoning_pulls_an_enemy_to_the_caster() -> void:
	var enemy := _enemy_at(Vector2(250, 0))
	await wait_physics_frames(1)
	var shot: Shot = Beckoning.new().activate(Vector2.RIGHT).attacks[0]
	shot.origin = Vector2.ZERO

	_fire(shot)
	await wait_seconds(0.8)

	assert_lt(enemy.position.x, 60.0)
	assert_eq(enemy.health.current, enemy.health.maximum, "pulled, not hurt")
