extends GutTest
## Lightning bolts jump from enemy to enemy, shots bounce off walls, poison clouds and burning ground linger, and beckoning pulls.

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
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


func _is_hurt(enemy: Enemy) -> bool:
	return enemy.health.current < enemy.health.maximum


## Enemies that stand still, so a test controls where everyone is.
func _still_enemy_at(position: Vector2) -> Enemy:
	var enemy := _enemy_at(position)
	enemy.set_physics_process(false)
	return enemy


func test_a_lightning_bolt_jumps_from_the_enemy_it_hits_to_one_nearby() -> void:
	var first := _still_enemy_at(Vector2(100, 0))
	var off_the_line := _still_enemy_at(Vector2(100, 120))
	await wait_physics_frames(1)

	_fire(_bolt(Vector2.ZERO, Vector2.RIGHT))
	await wait_seconds(0.5)

	assert_true(_is_hurt(first))
	assert_true(_is_hurt(off_the_line))


func test_a_lightning_bolt_does_not_jump_beyond_its_range() -> void:
	var first := _still_enemy_at(Vector2(100, 0))
	var far := _still_enemy_at(Vector2(100, LightningBolt.new().chain_range + 100))
	await wait_physics_frames(1)

	_fire(_bolt(Vector2.ZERO, Vector2.RIGHT))
	await wait_seconds(0.5)

	assert_true(_is_hurt(first))
	assert_false(_is_hurt(far))


func test_a_lightning_bolt_stops_after_its_last_jump_and_hits_each_enemy_once() -> void:
	var pack: Array[Enemy] = []
	for index in 4:
		pack.append(_still_enemy_at(Vector2(100, index * 60)))
	await wait_physics_frames(1)

	_fire(_bolt(Vector2.ZERO, Vector2.RIGHT))
	await wait_seconds(1.0)

	var hurt := pack.filter(_is_hurt)
	assert_eq(hurt.size(), 1 + LightningBolt.new().chains)
	for enemy in hurt:
		assert_eq(enemy.health.current, enemy.health.maximum - LightningBolt.new().damage)


func test_a_shot_bounces_off_a_wall_and_comes_back() -> void:
	_wall_at(Vector2(150, 0), Vector2(20, 300))
	var behind := _enemy_at(Vector2(-80, 0))
	await wait_physics_frames(1)
	var shot := _bolt(Vector2.ZERO, Vector2.RIGHT)
	shot.bounces = 1

	_fire(shot)
	await wait_seconds(0.5)

	assert_true(_is_hurt(behind))


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


func test_burning_ground_hurts_whoever_stays_in_it_every_half_second_then_dies_out() -> void:
	var inside := _enemy_at(Vector2(20, 0))
	inside.set_physics_process(false)
	var outside := _enemy_at(Vector2(300, 0))
	var fire := BurningGround.new(60.0, 34, 1.5)
	add_child(fire)

	await wait_seconds(0.35)
	assert_eq(inside.health.current, inside.health.maximum, "the first tick comes after half a second")
	await wait_seconds(0.3)
	assert_eq(inside.health.current, inside.health.maximum - 34)
	await wait_seconds(1.2)

	assert_eq(inside.health.current, inside.health.maximum - 3 * 34, "three ticks over the burn time")
	assert_eq(outside.health.current, outside.health.maximum)
	assert_false(is_instance_valid(fire))


func test_burning_ground_hurts_the_player_standing_in_it_too() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	add_child_autofree(player)
	var fire := BurningGround.new(60.0, 34, 1.5)
	fire.source = "your own Fireball"
	add_child(fire)

	await wait_seconds(0.7)

	assert_eq(player.health.current, Player.MAX_HEALTH - 34)


func test_a_fireball_hits_for_its_damage_then_burns_a_target_that_stays_in_the_blast() -> void:
	var fireball := Fireball.new()
	var target := _enemy_at(Vector2(100, 0))
	target.set_physics_process(false)
	target.set_max_health(1000)
	var aside := _enemy_at(Vector2(100, 400))
	aside.set_physics_process(false)
	var shot: Shot = fireball.attacks(Vector2.ZERO, Vector2.RIGHT, 100.0)[0]
	shot.hurts_player = false

	_fire(shot)
	await wait_seconds(0.4)
	assert_eq(target.health.current, 1000 - fireball.damage, "the impact")
	await wait_seconds(1.8)

	var expected := 1000 - fireball.damage - 3 * fireball.burn_damage
	assert_eq(target.health.current, expected)
	assert_between(fireball.damage + 3 * fireball.burn_damage, 290, 310, "a fireball is about 300 in all")
	assert_eq(aside.health.current, aside.health.maximum)


func test_beckoning_pulls_an_enemy_to_the_caster() -> void:
	var enemy := _enemy_at(Vector2(250, 0))
	await wait_physics_frames(1)
	var shot: Shot = Beckoning.new().activate(Vector2.RIGHT).attacks[0]
	shot.origin = Vector2.ZERO

	_fire(shot)
	await wait_seconds(0.8)

	assert_lt(enemy.position.x, 60.0)
	assert_eq(enemy.health.current, enemy.health.maximum, "pulled, not hurt")


func test_a_fully_charged_arrow_pierces_every_enemy_on_its_line() -> void:
	var bow := Bow.new()
	var first := _still_enemy_at(Vector2(100, 0))
	var second := _still_enemy_at(Vector2(200, 0))
	await wait_physics_frames(1)

	_fire(bow.charged_attacks(Vector2.ZERO, Vector2.RIGHT, 0.0, bow.full_charge_seconds)[0])
	await wait_seconds(0.6)

	assert_eq(first.health.current, first.health.maximum - bow.max_damage)
	assert_eq(second.health.current, second.health.maximum - bow.max_damage)


func test_a_tapped_arrow_stops_at_the_first_enemy() -> void:
	var bow := Bow.new()
	var first := _still_enemy_at(Vector2(100, 0))
	var second := _still_enemy_at(Vector2(200, 0))
	await wait_physics_frames(1)

	_fire(bow.charged_attacks(Vector2.ZERO, Vector2.RIGHT, 0.0, 0.0)[0])
	await wait_seconds(0.6)

	assert_true(_is_hurt(first))
	assert_false(_is_hurt(second))


func _mephitic_cloud(foe_hurt_player := false) -> PoisonCloud:
	var shot: Shot = MephiticCloud.new().attacks(Vector2.ZERO, Vector2.RIGHT, 100.0)[0]
	return PoisonCloud.new(shot.cloud_radius, shot.damage, shot.cloud_seconds, foe_hurt_player, shot.first_tick_delay)


func _tough_enemy_in_cloud() -> Enemy:
	var enemy := _enemy_at(Vector2(20, 0))
	enemy.set_physics_process(false)
	enemy.set_max_health(5000)
	return enemy


func test_an_enemy_staying_in_a_mephitic_cloud_takes_500_spread_over_six_seconds() -> void:
	var enemy := _tough_enemy_in_cloud()
	var cloud := _mephitic_cloud()

	add_child(cloud)
	await wait_seconds(3.0)
	assert_true(is_instance_valid(cloud), "still there after 3 s")
	assert_between(5000 - enemy.health.current, 200, 250, "about half the damage by the half way point")

	await wait_seconds(3.5)
	assert_false(is_instance_valid(cloud), "gone after 6 s")
	assert_eq(5000 - enemy.health.current, 500, "ticks at 0.6 ... 6.0 s: the last one counted once")


func test_a_mephitic_cloud_does_no_damage_during_its_first_tick_delay() -> void:
	var enemy := _tough_enemy_in_cloud()

	add_child_autofree(_mephitic_cloud())
	await wait_seconds(0.5)

	assert_eq(enemy.health.current, 5000)


func test_an_enemy_that_leaves_a_mephitic_cloud_within_the_grace_window_takes_nothing() -> void:
	var enemy := _tough_enemy_in_cloud()
	add_child_autofree(_mephitic_cloud())

	await wait_seconds(0.4)
	enemy.position = Vector2(400, 0)
	await wait_seconds(6.5)

	assert_eq(enemy.health.current, 5000)


func test_a_cloud_deals_each_tick_once_including_the_one_when_it_ends() -> void:
	var enemy := _enemy_at(Vector2(20, 0))
	enemy.set_physics_process(false)
	enemy.set_max_health(100)
	var cloud := PoisonCloud.new(60.0, 1, 3.0, false, 0.6)

	add_child(cloud)
	await wait_seconds(3.5)

	assert_false(is_instance_valid(cloud))
	assert_eq(100 - enemy.health.current, 5, "ticks at 0.6, 1.2, 1.8, 2.4 and 3.0 s")
