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


func _floor_find(map_seed: int, cell: Vector2i) -> Array:
	var find := LootTable.floor_find(map_seed, cell, ITEMS, {"healing": 3, "haste": 1})
	return [find.item_id, find.is_potion]


func test_floor_loot_is_the_same_for_the_same_map_seed() -> void:
	for x in 30:
		var cell := Vector2i(x, 7)
		assert_eq(_floor_find(1234, cell), _floor_find(1234, cell), "cell %s" % cell)


func test_floor_loot_differs_from_map_to_map() -> void:
	var differs := false
	for x in 30:
		differs = differs or _floor_find(1, Vector2i(x, 7)) != _floor_find(2, Vector2i(x, 7))

	assert_true(differs)


func test_floor_loot_is_potions_and_gear() -> void:
	var potions := 0
	for x in 200:
		if _floor_find(5, Vector2i(x, 3))[1]:
			potions += 1

	assert_between(potions, 60, 140, "about half are potions")


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


func test_by_default_about_one_enemy_in_fifty_drops_gear() -> void:
	var rng := _seeded(33)
	var drops := 0

	for _i in 20000:
		if LootTable.rolls_enemy_drop(LootTable.DEFAULT_ENEMY_DROP_CHANCE, rng):
			drops += 1

	assert_almost_eq(drops / 20000.0, 0.02, 0.004)


func test_potions_turn_up_as_often_as_their_weights_say() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var counts := {"common": 0, "rare": 0}

	for _i in 4000:
		counts[LootTable.pick_potion_id({"common": 3, "rare": 1}, rng)] += 1

	assert_almost_eq(float(counts["common"]) / counts["rare"], 3.0, 0.4)


func test_a_potion_with_no_competition_is_always_picked() -> void:
	var rng := RandomNumberGenerator.new()

	assert_eq(LootTable.pick_potion_id({"healing": 2}, rng), "healing")
