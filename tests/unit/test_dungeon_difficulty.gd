extends GutTest


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_deeper_rooms_never_hold_fewer_enemies() -> void:
	for depth in range(1, 10):
		assert_true(DungeonDifficulty.enemy_count(depth + 1) >= DungeonDifficulty.enemy_count(depth), str(depth))
	assert_eq(DungeonDifficulty.enemy_count(50), DungeonDifficulty.MAX_ENEMIES)


func _monsters_seen_at(depth: int) -> Dictionary:
	var seen := {}
	for seed_value in 40:
		for letter in DungeonDifficulty.enemy_letters(depth, _rng(seed_value)):
			seen[Bestiary.by_letter(letter).id] = true
	return seen


func test_the_first_rooms_have_no_crossbows_or_fireballs() -> void:
	for seed_value in 30:
		for letter in DungeonDifficulty.enemy_letters(1, _rng(seed_value)):
			assert_does_not_have(["crossbow", "fireball"], Bestiary.by_letter(letter).weapon_id)


func test_the_first_rooms_hold_weak_kobolds_and_goblins() -> void:
	var seen := _monsters_seen_at(1)

	assert_has(seen, "kobold")
	assert_has(seen, "goblin")
	assert_does_not_have(seen, "orc")


func test_fireballs_show_up_deeper_in() -> void:
	var weapons := {}
	for id: String in _monsters_seen_at(4):
		weapons[Bestiary.by_id(id).weapon_id] = true

	assert_has(weapons, "fireball")


func test_tough_monsters_wait_far_from_the_start() -> void:
	assert_does_not_have(_monsters_seen_at(3), "ogre")
	assert_does_not_have(_monsters_seen_at(4), "dwarf")
	assert_has(_monsters_seen_at(6), "dwarf")
	assert_has(_monsters_seen_at(8), "ogre")


func test_monsters_get_tougher_with_depth() -> void:
	var toughness_at := func(depth: int) -> float:
		var pool: Array = DungeonDifficulty.POOLS_BY_DEPTH[depth - 1]
		var total := 0.0
		for letter: String in pool:
			total += Bestiary.by_letter(letter).max_health
		return total / pool.size()

	for depth in range(1, DungeonDifficulty.POOLS_BY_DEPTH.size()):
		assert_true(toughness_at.call(depth + 1) >= toughness_at.call(depth), str(depth))


func test_every_letter_is_a_monster_the_map_parser_knows() -> void:
	for pool: Array in DungeonDifficulty.POOLS_BY_DEPTH:
		for letter: String in pool:
			assert_has(Bestiary.letters(), letter)


func test_now_and_then_a_room_holds_enemies_from_deeper_in() -> void:
	var rolls := {}
	for seed_value in 60:
		rolls[DungeonDifficulty.rolled_depth(2, _rng(seed_value))] = true

	assert_eq(rolls.keys().size(), 2)
	assert_has(rolls, 2)
	assert_has(rolls, 2 + DungeonDifficulty.OUT_OF_DEPTH_EXTRA)
