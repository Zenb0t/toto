extends GutTest


func test_each_floor_of_the_descent_is_a_different_branch() -> void:
	var seen := {}
	for floor_number in range(1, RunState.FLOOR_COUNT + 1):
		seen[Branch.for_floor(floor_number).id] = true

	assert_eq(seen.size(), RunState.FLOOR_COUNT)


func test_the_descent_starts_in_the_dungeon() -> void:
	assert_eq(Branch.for_floor(1).id, "dungeon")
	assert_eq(Branch.for_floor(1).cave_share, 0.0)


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
