extends GutTest


func test_every_monster_has_its_own_id_and_map_letter() -> void:
	var ids := {}
	var letters := {}
	for monster in Bestiary.all():
		assert_false(ids.has(monster.id), monster.id)
		assert_false(letters.has(monster.letter), monster.letter)
		ids[monster.id] = true
		letters[monster.letter] = true


func test_every_monster_carries_a_weapon_the_player_can_find() -> void:
	for monster in Bestiary.all():
		assert_has(GameTuning.weapon_ids(), monster.weapon_id, monster.id)


func test_map_letters_never_clash_with_the_map_symbols() -> void:
	var symbols := [DungeonMapParser.WALL, DungeonMapParser.FLOOR, DungeonMapParser.DOOR, DungeonMapParser.PLAYER,
		DungeonMapParser.EXIT, DungeonMapParser.STAIRS_UP, DungeonMapParser.LOOT, DungeonMapParser.WATER, DungeonMapParser.LAVA]
	for letter in Bestiary.letters():
		assert_does_not_have(symbols, letter)


func test_dwarves_are_slow_and_sturdy() -> void:
	var dwarf := Bestiary.by_id("dwarf")
	var bandit := Bestiary.by_id("bandit")

	assert_lt(dwarf.speed_multiplier, bandit.speed_multiplier)
	assert_gt(dwarf.max_health, bandit.max_health * 2)


func test_kobolds_are_quick_and_frail() -> void:
	var kobold := Bestiary.by_id("kobold")
	var bandit := Bestiary.by_id("bandit")

	assert_gt(kobold.speed_multiplier, bandit.speed_multiplier)
	assert_lt(kobold.max_health, bandit.max_health)


func test_ogres_are_huge_and_hit_hard() -> void:
	var ogre := Bestiary.by_id("ogre")
	var tuning := GameTuning.create()
	var bandit_hit: int = GameTuning.weapon(tuning, Bestiary.by_id("bandit").weapon_id).damage

	var ogre_hit: int = GameTuning.weapon(tuning, ogre.weapon_id).damage + ogre.damage_bonus

	assert_gt(ogre.size, 1.4)
	assert_gt(ogre_hit, bandit_hit)


func test_unknown_ids_fall_back_to_a_bandit() -> void:
	assert_eq(Bestiary.by_id("dragon").id, "bandit")
