extends GutTest

const ITEMS: Array[String] = ["wand", "sword", "fireball", "crossbow", "dash", "shield", "heal"]
const HELD: Array[String] = ["wand", "dash"]


func _seeded(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_a_find_is_never_something_already_held() -> void:
	var rng := _seeded(1)

	for i in 200:
		assert_does_not_have(HELD, LootTable.pick_item_id(ITEMS, HELD, rng))


func test_every_item_not_held_can_be_found() -> void:
	var rng := _seeded(2)
	var found := {}

	for i in 300:
		found[LootTable.pick_item_id(ITEMS, HELD, rng)] = true

	assert_eq(found.size(), ITEMS.size() - HELD.size())


func test_holding_everything_still_finds_something() -> void:
	var only_wand: Array[String] = ["wand"]

	assert_eq(LootTable.pick_item_id(only_wand, only_wand, _seeded(3)), "wand")


func test_the_same_seed_finds_the_same_items() -> void:
	var first := _seeded(4)
	var second := _seeded(4)

	for i in 20:
		assert_eq(LootTable.pick_item_id(ITEMS, HELD, first), LootTable.pick_item_id(ITEMS, HELD, second))


func test_an_enemy_drops_the_weapon_it_fought_with() -> void:
	assert_eq(LootTable.enemy_drop_id("crossbow", ITEMS, HELD, _seeded(5)), "crossbow")


func test_an_enemy_carrying_the_players_weapon_drops_something_else() -> void:
	var drop := LootTable.enemy_drop_id("wand", ITEMS, HELD, _seeded(6))

	assert_does_not_have(HELD, drop)


func test_enemies_never_drop_loot_at_zero_chance() -> void:
	var rng := _seeded(7)

	for i in 200:
		assert_false(LootTable.rolls_enemy_drop(0.0, rng))


func test_enemies_always_drop_loot_at_full_chance() -> void:
	var rng := _seeded(8)

	for i in 200:
		assert_true(LootTable.rolls_enemy_drop(1.0, rng))
