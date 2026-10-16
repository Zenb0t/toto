extends GutTest


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_deeper_rooms_never_hold_fewer_enemies() -> void:
	for depth in range(1, 10):
		assert_true(DungeonDifficulty.enemy_count(depth + 1) >= DungeonDifficulty.enemy_count(depth), str(depth))
	assert_eq(DungeonDifficulty.enemy_count(50), DungeonDifficulty.MAX_ENEMIES)


func test_the_first_rooms_have_no_crossbows_or_fireballs() -> void:
	for seed_value in 30:
		var letters := DungeonDifficulty.enemy_letters(1, _rng(seed_value))
		assert_does_not_have(letters, "c")
		assert_does_not_have(letters, "f")


func test_fireballs_show_up_deeper_in() -> void:
	var seen := {}
	for seed_value in 30:
		for letter in DungeonDifficulty.enemy_letters(4, _rng(seed_value)):
			seen[letter] = true

	assert_has(seen, "f")


func test_every_letter_is_one_the_map_parser_knows() -> void:
	for pool: Array in DungeonDifficulty.POOLS_BY_DEPTH:
		for letter: String in pool:
			assert_has(DungeonMapParser.ENEMY_WEAPONS, letter)


func test_now_and_then_a_room_holds_enemies_from_deeper_in() -> void:
	var rolls := {}
	for seed_value in 60:
		rolls[DungeonDifficulty.rolled_depth(2, _rng(seed_value))] = true

	assert_eq(rolls.keys().size(), 2)
	assert_has(rolls, 2)
	assert_has(rolls, 2 + DungeonDifficulty.OUT_OF_DEPTH_EXTRA)
