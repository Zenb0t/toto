extends GutTest
## Enemies fight with the same weapons as the player, telegraph their attacks, and hurt only the player.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const MARGIN := 0.15


func _spawn_player_at(position: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = position
	add_child_autofree(player)
	return player


## An enemy with the weapon, whose attacks are carried out like the game does.
func _spawn_enemy_at(position: Vector2, weapon: Weapon) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = position
	enemy.arm(weapon)
	enemy.attack_fired.connect(_carry_out.bind(enemy))
	add_child_autofree(enemy)
	return enemy


func _carry_out(attacks: Array, attacker: Node2D) -> void:
	for attack: Variant in attacks:
		if attack is Shot:
			var projectile: Projectile = PROJECTILE_SCENE.instantiate()
			projectile.launch(attack)
			add_child_autofree(projectile)
		elif attack is Slash:
			add_child_autofree(SlashEffect.new(attack, attacker))


func _wand(windup: float) -> MagicMissile:
	var wand := MagicMissile.new()
	wand.windup = windup
	wand.shot_speed = 1000.0
	return wand


func test_an_armed_enemy_shoots_the_player_it_chases() -> void:
	var player := _spawn_player_at(Vector2(150, 0))
	var enemy := _spawn_enemy_at(Vector2.ZERO, _wand(0.1))

	enemy.chase(player)
	await wait_seconds(0.5)

	assert_lt(player.health.current, Player.MAX_HEALTH)


func test_an_enemy_shows_its_attack_coming_before_it_hurts() -> void:
	var player := _spawn_player_at(Vector2(150, 0))
	var enemy := _spawn_enemy_at(Vector2.ZERO, _wand(0.6))

	enemy.chase(player)
	await wait_seconds(0.3)

	assert_eq(player.health.current, Player.MAX_HEALTH)


func test_stepping_aside_during_the_telegraph_dodges_the_shot() -> void:
	var player := _spawn_player_at(Vector2(150, 0))
	var enemy := _spawn_enemy_at(Vector2.ZERO, _wand(0.4))

	enemy.chase(player)
	await wait_physics_frames(3)
	player.position = Vector2(150, 120)
	await wait_seconds(0.6)

	assert_eq(player.health.current, Player.MAX_HEALTH)


func test_an_enemys_shot_flies_through_other_enemies() -> void:
	var player := _spawn_player_at(Vector2(200, 0))
	var bystander := _spawn_enemy_at(Vector2(100, 0), MagicMissile.new())
	var shooter := _spawn_enemy_at(Vector2.ZERO, _wand(0.1))

	shooter.chase(player)
	await wait_seconds(0.5)

	assert_eq(bystander.health.current, Enemy.DEFAULT_MAX_HEALTH)
	assert_lt(player.health.current, Player.MAX_HEALTH)


func test_an_enemys_sword_hurts_the_player_but_not_its_allies() -> void:
	var player := _spawn_player_at(Vector2(30, 0))
	var ally := _spawn_enemy_at(Vector2(25, 25), Sword.new())
	var sword := Sword.new()
	sword.windup = 0.05
	sword.sweep_seconds = 0.0
	var swinger := _spawn_enemy_at(Vector2.ZERO, sword)

	swinger.chase(player)
	await wait_seconds(0.3)

	assert_lt(player.health.current, Player.MAX_HEALTH)
	assert_eq(ally.health.current, Enemy.DEFAULT_MAX_HEALTH)


func test_a_fireball_thrower_backs_away_from_a_player_who_gets_close() -> void:
	var player := _spawn_player_at(Vector2(40, 0))
	var thrower := _spawn_enemy_at(Vector2.ZERO, Fireball.new())

	thrower.chase(player)
	await wait_seconds(0.4)

	assert_lt(thrower.position.x, 0.0)


func test_a_sword_fighter_rushes_a_distant_player() -> void:
	var player := _spawn_player_at(Vector2(300, 0))
	var fighter := _spawn_enemy_at(Vector2.ZERO, Sword.new())

	fighter.chase(player)
	await wait_seconds(0.4)

	assert_gt(fighter.position.x, 20.0)


func test_a_player_shield_blocks_an_enemy_shot() -> void:
	var player := _spawn_player_at(Vector2(150, 0))
	player.equip_utility(Shield.new())
	var enemy := _spawn_enemy_at(Vector2.ZERO, _wand(0.1))

	player.use_utility(Vector2.RIGHT)
	enemy.chase(player)
	await wait_seconds(0.5)

	assert_eq(player.health.current, Player.MAX_HEALTH)


## A wall splits the room, with a gap at the bottom. The enemy starts on the left, the player on the right.
const WALLED := """
###########
#P...#....#
#....#....#
#....#....#
#.........#
###########
"""


func _walled_room() -> Pathfinder:
	var map := DungeonMapParser.new().parse(WALLED)
	var view := DungeonView.new()
	add_child_autofree(view)
	view.show_map(map)
	return Pathfinder.new(map)


func test_an_enemy_that_cannot_see_the_player_walks_around_the_wall() -> void:
	var navigation := _walled_room()
	var player := _spawn_player_at(DungeonView.cell_center(Vector2i(8, 1)))
	var fighter := _spawn_enemy_at(DungeonView.cell_center(Vector2i(2, 2)), Sword.new())
	fighter.navigation = navigation

	fighter.chase(player)
	await wait_seconds(3.0)

	assert_gt(fighter.position.x, DungeonView.cell_center(Vector2i(5, 0)).x)


func test_a_shooter_holds_fire_while_a_wall_is_in_the_way() -> void:
	var navigation := _walled_room()
	var player := _spawn_player_at(DungeonView.cell_center(Vector2i(8, 1)))
	var shooter := _spawn_enemy_at(DungeonView.cell_center(Vector2i(2, 1)), _wand(0.1))
	shooter.navigation = navigation
	shooter.move_speed = 0.0
	watch_signals(shooter)

	shooter.chase(player)
	await wait_seconds(0.6)

	assert_signal_not_emitted(shooter, "attack_fired")


func test_a_fireball_thrower_lobs_over_the_wall() -> void:
	var navigation := _walled_room()
	var player := _spawn_player_at(DungeonView.cell_center(Vector2i(8, 1)))
	var fireball := Fireball.new()
	fireball.windup = 0.1
	fireball.shot_speed = 800.0
	var thrower := _spawn_enemy_at(DungeonView.cell_center(Vector2i(2, 1)), fireball)
	thrower.navigation = navigation
	thrower.move_speed = 0.0

	thrower.chase(player)
	await wait_seconds(0.8)

	assert_lt(player.health.current, Player.MAX_HEALTH)
