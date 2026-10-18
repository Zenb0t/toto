extends GutTest


func _run_on_floor(floor_number: int, kills: int) -> Run:
	var run := Run.new(1)
	while run.current_map().floor_number < floor_number:
		run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
	run.hero.kills = kills
	return run


func test_a_death_names_the_killer_and_the_crypt_level() -> void:
	var lines := RunSummary.lines(_run_on_floor(3, 12), 4, RunSummary.Ending.DIED, "an orc wizard")

	assert_eq(lines[0], "Killed by an orc wizard on crypt level 3 of %d." % WorldLayout.FLOOR_COUNT)
	assert_eq(lines[1], "Reached level 4.")
	assert_eq(lines[2], "12 monsters slain.")


func test_one_kill_is_counted_in_the_singular() -> void:
	var lines := RunSummary.lines(_run_on_floor(1, 1), 1, RunSummary.Ending.DIED, "lava")

	assert_eq(lines[2], "1 monster slain.")


func test_killing_the_lich_is_celebrated_with_the_run_so_far() -> void:
	var lines := RunSummary.lines(_run_on_floor(WorldLayout.FLOOR_COUNT, 40), 9, RunSummary.Ending.WON, "")

	assert_eq(RunSummary.title(RunSummary.Ending.WON), "You killed the Lich")
	assert_has(lines, "Reached level 9.")
	assert_has(lines, "40 monsters slain.")


func test_monsters_are_named_with_the_right_article() -> void:
	assert_eq(Monster.with_article("Orc wizard"), "an orc wizard")
	assert_eq(Monster.with_article("Kobold"), "a kobold")


func test_a_death_on_the_plains_names_the_killer_and_the_place() -> void:
	var lines := RunSummary.lines(Run.new(1), 1, RunSummary.Ending.DIED, "a goblin")

	assert_eq(lines[0], "Killed by a goblin on the plains.")
