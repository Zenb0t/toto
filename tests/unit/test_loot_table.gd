extends GutTest

const WEAPONS: Array[String] = ["wand", "sword", "fireball", "crossbow"]


func _seeded(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_a_found_weapon_is_never_the_one_already_held() -> void:
	var rng := _seeded(1)

	for i in 200:
		assert_ne(LootTable.pick_weapon_id(WEAPONS, "sword", rng), "sword")


func test_every_other_weapon_can_be_found() -> void:
	var rng := _seeded(2)
	var found := {}

	for i in 200:
		found[LootTable.pick_weapon_id(WEAPONS, "wand", rng)] = true

	assert_eq(found.size(), 3)
	assert_does_not_have(found, "wand")


func test_with_nothing_else_to_offer_the_held_weapon_is_found() -> void:
	var only_wand: Array[String] = ["wand"]

	assert_eq(LootTable.pick_weapon_id(only_wand, "wand", _seeded(3)), "wand")


func test_the_same_seed_finds_the_same_weapons() -> void:
	var first := _seeded(4)
	var second := _seeded(4)

	for i in 20:
		assert_eq(LootTable.pick_weapon_id(WEAPONS, "wand", first), LootTable.pick_weapon_id(WEAPONS, "wand", second))


func test_enemies_never_drop_loot_at_zero_chance() -> void:
	var rng := _seeded(5)

	for i in 200:
		assert_false(LootTable.rolls_enemy_drop(0.0, rng))


func test_enemies_always_drop_loot_at_full_chance() -> void:
	var rng := _seeded(6)

	for i in 200:
		assert_true(LootTable.rolls_enemy_drop(1.0, rng))
