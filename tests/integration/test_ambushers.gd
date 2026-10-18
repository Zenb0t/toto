extends GutTest
## Ambushers in the world: they arrive already hunting the hero, with no noticing pause, and can give up like any
## hunter.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const CELL := DungeonView.TILE_SIZE


func _hero_at(position: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = position
	add_child_autofree(player)
	return player


func _ambusher(player: Player, at: Vector2, home: Vector2) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.arm(Sword.new())
	enemy.position = at
	enemy.ambush(player, home)
	add_child_autofree(enemy)
	return enemy


func test_an_ambusher_is_hunting_the_hero_from_the_moment_it_arrives() -> void:
	var player := _hero_at(Vector2.ZERO)
	var enemy := _ambusher(player, Vector2(4 * CELL, 0), Vector2.ZERO)

	assert_true(enemy.is_hunting())
	assert_false(enemy.is_asleep())
	assert_eq(enemy.mark(), "", "it does not stop to notice the hero first")


func test_an_ambusher_closes_in_on_the_hero() -> void:
	var player := _hero_at(Vector2.ZERO)
	var enemy := _ambusher(player, Vector2(6 * CELL, 0), Vector2.ZERO)
	var before := enemy.global_position.distance_to(player.global_position)

	await wait_seconds(1.0)

	assert_lt(enemy.global_position.distance_to(player.global_position), before - CELL)


func test_an_ambusher_gives_up_when_the_hero_gets_far_from_its_home() -> void:
	var player := _hero_at(Vector2(60 * CELL, 0))
	var enemy := _ambusher(player, Vector2(58 * CELL, 0), Vector2.ZERO)

	await wait_physics_frames(3)

	assert_false(enemy.is_hunting(), "ordinary hunters give up (#36)")
