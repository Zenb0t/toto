extends GutTest


func _run_on_floor(floor_number: int, kills: int) -> Run:
	var run := Run.new(1)
	while run.current_map().floor_number < floor_number:
		run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
	run.hero.kills = kills
	return run


func test_a_death_names_the_killer_and_the_floor() -> void:
	var lines := RunSummary.lines(_run_on_floor(3, 12), 4, RunSummary.Ending.DIED, "an orc wizard")

	assert_eq(lines[0], "Killed by an orc wizard in the %s (floor 3 of %d)." % [
		Branch.for_floor(3).display_name, WorldLayout.FLOOR_COUNT])
	assert_eq(lines[1], "Reached level 4.")
	assert_eq(lines[2], "12 monsters slain.")


func test_one_kill_is_counted_in_the_singular() -> void:
	var lines := RunSummary.lines(_run_on_floor(1, 1), 1, RunSummary.Ending.DIED, "lava")

	assert_eq(lines[2], "1 monster slain.")


func test_an_escape_is_celebrated() -> void:
	assert_eq(RunSummary.title(RunSummary.Ending.ESCAPED), "You escaped the dungeon!")
	assert_string_starts_with(RunSummary.lines(_run_on_floor(5, 40), 9, RunSummary.Ending.ESCAPED, "")[0], "Escaped")


func test_monsters_are_named_with_the_right_article() -> void:
	assert_eq(Monster.with_article("Orc wizard"), "an orc wizard")
	assert_eq(Monster.with_article("Kobold"), "a kobold")
