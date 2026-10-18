extends GutTest
## The run-level owner: one world seed, the hero carried from map to map, and which map is current.


func _hero_holding(weapon_id: String, kills: int) -> HeroState:
	return HeroState.carrying(weapon_id, "blink", Health.restored(1400, 400), {"haste": 2}, 3000, kills)


func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_a_run_starts_on_the_first_floor_with_the_starting_kit() -> void:
	var run := Run.new(42)

	assert_eq(run.current_map_id, WorldLayout.start_map_id())
	assert_eq(run.current_map().floor_number, 1)
	assert_eq(run.hero.weapon_id, GameTuning.DEFAULT_WEAPON_ID)
	assert_eq(run.hero.utility_id, GameTuning.DEFAULT_UTILITY_ID)
	assert_eq(run.hero.health, run.hero.max_health)
	assert_eq(run.hero.potions, HeroState.STARTING_POTIONS)
	assert_eq(run.hero.kills, 0)


func test_the_same_world_seed_gives_the_same_floors() -> void:
	var first := Run.new(1234)
	var again := Run.new(1234)

	for _floor in WorldLayout.FLOOR_COUNT:
		assert_eq(first.current_map().ascii(), again.current_map().ascii(), first.current_map_id)
		first.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
		again.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())


func test_another_world_seed_gives_other_floors() -> void:
	assert_ne(Run.new(1).current_map().ascii(), Run.new(2).current_map().ascii())


func test_the_stairs_lead_to_the_next_floor_with_everything_the_hero_carries() -> void:
	var run := Run.new(7)

	var destination := run.travel(WorldLayout.Exit.STAIRS_DOWN, _hero_holding("sword", 9))

	assert_false(destination.leaves_world())
	assert_eq(run.current_map().floor_number, 2)
	assert_eq(run.hero.weapon_id, "sword")
	assert_eq(run.hero.utility_id, "blink")
	assert_eq(run.hero.health, 400)
	assert_eq(run.hero.max_health, 1400)
	assert_eq(run.hero.potions, {"haste": 2})
	assert_eq(run.hero.experience, 3000)
	assert_eq(run.hero.kills, 9)


func test_the_last_floors_stairs_lead_out_of_the_world() -> void:
	var run := Run.new(7)
	for _floor in WorldLayout.FLOOR_COUNT - 1:
		assert_false(run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new()).leaves_world())

	var destination := run.travel(WorldLayout.Exit.STAIRS_DOWN, _hero_holding("bow", 30))

	assert_true(destination.leaves_world())
	assert_eq(run.current_map().floor_number, WorldLayout.FLOOR_COUNT, "the hero stays where they won")
	assert_eq(run.hero.kills, 30, "the summary counts every kill")


func test_the_next_world_has_a_different_seed_and_a_fresh_hero_on_the_first_floor() -> void:
	var rng := _seeded_rng(5)
	var run := Run.random(rng)
	run.travel(WorldLayout.Exit.STAIRS_DOWN, _hero_holding("sword", 9))

	for _death in 50:
		var next := run.next_world(rng)
		assert_ne(next.world_seed, run.world_seed)
		assert_eq(next.current_map().floor_number, 1)
		assert_eq(next.hero.weapon_id, GameTuning.DEFAULT_WEAPON_ID)
		assert_eq(next.hero.kills, 0)
		run = next
