extends GutTest
## Monsters settled at home sleep or wander until they notice the hero, then show it and come for them.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const CELL := DungeonView.TILE_SIZE


func _spawn_player_at(position: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = position
	add_child_autofree(player)
	return player


## A sword-carrying monster living at its spot, starting asleep or wandering, with the player as its foe.
func _settled_enemy(start: Band.Start, player: Player) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.arm(Sword.new())
	enemy.settle(Vector2.ZERO, start)
	enemy.chase(player)
	add_child_autofree(enemy)
	return enemy


func test_a_sleeping_monster_shows_a_z_and_wakes_when_hit() -> void:
	var player := _spawn_player_at(Vector2(20 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.ASLEEP, player)
	await wait_physics_frames(3)
	var asleep_mark := enemy.mark()

	enemy.take_damage(10)
	await wait_physics_frames(2)

	assert_eq(asleep_mark, Enemy.ASLEEP_MARK)
	assert_eq(enemy.mark(), Enemy.NOTICING_MARK)


func test_a_woken_monster_pauses_then_comes_for_the_hero() -> void:
	var player := _spawn_player_at(Vector2(20 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.ASLEEP, player)
	enemy.noticing_seconds = 0.3
	enemy.take_damage(10)
	await wait_seconds(0.2)
	var while_noticing := enemy.position

	await wait_seconds(0.5)

	assert_eq(while_noticing, Vector2.ZERO, "it stands still while it notices")
	assert_eq(enemy.mark(), "")
	assert_gt(enemy.position.x, 10.0)


func test_a_sleeping_monster_sleeps_on_while_the_hero_is_far() -> void:
	var player := _spawn_player_at(Vector2(6 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.ASLEEP, player)

	await wait_seconds(0.5)

	assert_eq(enemy.mark(), Enemy.ASLEEP_MARK)
	assert_eq(enemy.position, Vector2.ZERO)


func test_a_sleeping_monster_notices_a_hero_who_comes_close() -> void:
	var player := _spawn_player_at(Vector2(6 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.ASLEEP, player)
	watch_signals(enemy)
	await wait_physics_frames(3)

	player.position = Vector2(3 * CELL, 0)
	await wait_physics_frames(3)

	assert_eq(enemy.mark(), Enemy.NOTICING_MARK)
	assert_signal_emitted(enemy, "noticed")


func test_a_sleeping_monster_that_hears_a_noise_or_shout_notices_the_hero() -> void:
	var player := _spawn_player_at(Vector2(20 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.ASLEEP, player)
	await wait_physics_frames(2)

	enemy.alert()
	await wait_physics_frames(2)

	assert_eq(enemy.mark(), Enemy.NOTICING_MARK)


func test_a_monster_already_noticing_the_hero_does_not_shout_again_when_it_hears_a_shout() -> void:
	var player := _spawn_player_at(Vector2(20 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.ASLEEP, player)
	watch_signals(enemy)
	enemy.alert()
	await wait_physics_frames(2)

	enemy.alert()
	await wait_physics_frames(2)

	assert_signal_emit_count(enemy, "noticed", 1)


func test_a_wandering_monster_strolls_about_its_home_without_a_mark() -> void:
	var player := _spawn_player_at(Vector2(30 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.WANDERING, player)
	enemy.wander_radius = 3 * CELL

	var farthest := 0.0
	for _step in 20:
		await wait_seconds(0.1)
		farthest = maxf(farthest, enemy.position.length())

	assert_eq(enemy.mark(), "")
	assert_gt(farthest, 0.0, "it moves")
	assert_lte(farthest, 3 * CELL + Enemy.WAYPOINT_REACHED)


func test_a_wandering_monster_strolls_slower_than_it_hunts() -> void:
	var player := _spawn_player_at(Vector2(30 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.WANDERING, player)
	await wait_physics_frames(5)

	assert_almost_eq(enemy.velocity.length(), enemy.move_speed * enemy.wander_speed_share, 1.0)


func test_a_hunter_that_loses_the_hero_walks_back_home_and_wanders_again() -> void:
	var player := _spawn_player_at(Vector2(4 * CELL, 0))
	var enemy := _settled_enemy(Band.Start.WANDERING, player)
	enemy.wander_radius = 0.5 * CELL
	enemy.noticing_seconds = 0.05
	enemy.position = Vector2(3 * CELL, 0)
	await wait_physics_frames(3)
	assert_eq(enemy.mark(), Enemy.NOTICING_MARK)
	# The hero escapes far from its home: the monster gives up, checks where it saw them and walks home.
	player.position = Vector2(60 * CELL, 0)
	await wait_seconds(0.5)

	await wait_seconds(12.0)

	assert_lt(enemy.position.length(), 1.5 * CELL, "back near home")
	assert_eq(enemy.mark(), "")
