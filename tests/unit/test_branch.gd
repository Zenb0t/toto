extends GutTest


func test_each_floor_of_the_descent_is_a_different_branch() -> void:
	var seen := {}
	for floor_number in range(1, WorldLayout.FLOOR_COUNT + 1):
		seen[Branch.for_floor(floor_number).id] = true

	assert_eq(seen.size(), WorldLayout.FLOOR_COUNT)


func test_the_descent_starts_in_the_mostly_built_dungeon() -> void:
	assert_eq(Branch.for_floor(1).id, "dungeon")
	assert_lt(Branch.for_floor(1).cave_share, 0.5)
	assert_true(Branch.for_floor(1).look.flagstones)


func test_every_branch_greets_the_player() -> void:
	for branch in Branch.all():
		assert_ne(branch.greeting, "", branch.id)


func test_anything_deeper_than_the_last_branch_stays_in_it() -> void:
	assert_eq(Branch.for_floor(99).id, Branch.all()[-1].id)


func test_every_branch_uses_vaults_and_monsters_that_exist() -> void:
	for branch in Branch.all():
		assert_false(branch.vaults.is_empty(), branch.id)
		for vault_name in branch.vaults:
			assert_has(Vaults.DESIGNS, vault_name, branch.id)
		for letter in branch.favoured:
			assert_has(Bestiary.letters(), letter, branch.id)


func test_the_crypt_is_full_of_the_undead_and_the_mines_of_orcs() -> void:
	for letter in Branch.for_floor(4).favoured:
		assert_eq(Bestiary.by_letter(letter).race, "undead")
	assert_has(Branch.all()[2].favoured, "o")


func test_caves_have_no_flagstones() -> void:
	for branch in Branch.all():
		if branch.cave_share > 0.5:
			assert_false(branch.look.flagstones, branch.id)


func test_every_kind_of_clutter_can_be_made() -> void:
	for branch in Branch.all():
		for kind in branch.look.clutter:
			var thing := DecorModel.make(kind, 0.5)
			assert_not_null(thing, "%s: %s" % [branch.id, kind])
			thing.free()


func test_the_plains_are_an_outdoor_place_of_grass_and_trees_with_no_torches() -> void:
	var plains := Branch.plains()

	assert_true(plains.outdoors)
	assert_eq(plains.display_name, "plains")
	assert_ne(plains.greeting, "")
	assert_false(plains.look.torches)
	assert_false(plains.look.flagstones)
	assert_gt(plains.look.floor_color.g, plains.look.floor_color.r, "green ground")


func test_the_plains_are_not_a_floor_of_the_descent() -> void:
	for branch in Branch.all():
		assert_ne(branch.id, Branch.plains().id)
		assert_false(branch.outdoors, branch.id)
