extends GutTest
## Deep water stops bodies but not shots.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const MOAT := """
###########
#P..~~~...#
#...~~~...#
#...~~~...#
###########
"""


func before_each() -> void:
	var view := DungeonView.new()
	add_child_autofree(view)
	view.show_map(DungeonMapParser.new().parse(MOAT))


func test_the_player_cannot_walk_into_deep_water() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = DungeonView.cell_center(Vector2i(2, 2))
	add_child_autofree(player)

	player.move(Vector2.RIGHT)
	await wait_seconds(1.5)

	assert_lt(player.position.x, DungeonView.cell_center(Vector2i(4, 2)).x)


func test_a_shot_flies_across_deep_water() -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = DungeonView.cell_center(Vector2i(8, 2))
	add_child_autofree(enemy)
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(Shot.new(DungeonView.cell_center(Vector2i(2, 2)), Vector2.RIGHT, 600.0, 1, 400.0))
	add_child_autofree(projectile)

	await wait_seconds(0.6)

	assert_eq(enemy.health.current, Enemy.DEFAULT_MAX_HEALTH - 1)


func test_wading_slows_the_player() -> void:
	var player: Player = preload("res://scenes/player.tscn").instantiate()
	add_child_autofree(player)

	player.ground_speed = DungeonMap.WADING_SPEED
	player.move(Vector2.RIGHT)
	await wait_physics_frames(2)

	assert_almost_eq(player.velocity.x, player.move_speed * DungeonMap.WADING_SPEED, 0.01)
