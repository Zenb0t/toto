extends GutTest
## Monsters differ in toughness, build and strength, on top of the weapon they carry.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const MARGIN := 0.15


func _monster_at(position: Vector2, monster_id: String, health_multiplier := 1.0) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = position
	enemy.become(Bestiary.by_id(monster_id), health_multiplier)
	add_child_autofree(enemy)
	return enemy


func _quick_wand() -> Wand:
	var wand := Wand.new()
	wand.windup = 0.0
	wand.shot_speed = 1000.0
	return wand


func test_a_monster_has_the_health_of_its_kind() -> void:
	var ogre := _monster_at(Vector2.ZERO, "ogre")

	assert_eq(ogre.health.maximum, Bestiary.by_id("ogre").max_health)


func test_tuned_health_scales_every_kind_but_leaves_at_least_one() -> void:
	assert_eq(_monster_at(Vector2.ZERO, "orc", 2.0).health.maximum, Bestiary.by_id("orc").max_health * 2)
	assert_eq(_monster_at(Vector2(0, 100), "kobold", 0.1).health.maximum, 1)


func test_a_big_monster_is_hit_from_farther_away() -> void:
	var ogre := _monster_at(Vector2(75, 0), "ogre")
	var kobold := _monster_at(Vector2(0, 75), "kobold")
	var sword := Sword.new()
	sword.reach = 60.0
	sword.sweep_seconds = 0.0

	for slash: Slash in sword.attacks(Vector2.ZERO, Vector2.RIGHT, 0.0):
		add_child_autofree(SlashEffect.new(slash))
	for slash: Slash in sword.attacks(Vector2.ZERO, Vector2.DOWN, 0.0):
		add_child_autofree(SlashEffect.new(slash))
	await wait_physics_frames(3)

	assert_lt(ogre.health.current, ogre.health.maximum, "the ogre's body reaches into the swing")
	assert_eq(kobold.health.current, kobold.health.maximum, "the kobold's doesn't")


func test_a_strong_monster_hits_harder_with_the_same_weapon() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = Vector2(150, 0)
	add_child_autofree(player)
	var ogre := _monster_at(Vector2.ZERO, "ogre")
	ogre.arm(_quick_wand())
	watch_signals(ogre)

	ogre.chase(player)
	await wait_seconds(0.2)

	var attacks: Array = get_signal_parameters(ogre, "attack_fired")[0]
	assert_eq(attacks[0].damage, Wand.new().shot_damage + Bestiary.by_id("ogre").damage_bonus)
