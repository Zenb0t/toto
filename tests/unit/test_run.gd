extends GutTest
## The run-level owner: one world seed, the hero carried from map to map, and which map is current.


func _hero_holding(weapon_id: String, kills: int) -> HeroState:
	return HeroState.carrying(weapon_id, "blink", Health.restored(1400, 400), {"haste": 2}, 3000, kills)


func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_a_run_starts_on_the_plains_with_the_starting_kit() -> void:
	var run := Run.new(42)

	assert_eq(run.current_map_id, WorldLayout.PLAINS_ID)
	assert_eq(run.current_map().recipe, MapSpec.Recipe.QUADRANT)
	assert_eq(run.arrival_spot, WorldLayout.Spot.START)
	assert_eq(run.hero.weapon_id, GameTuning.DEFAULT_WEAPON_ID)
	assert_eq(run.hero.utility_id, GameTuning.DEFAULT_UTILITY_ID)
	assert_eq(run.hero.health, run.hero.max_health)
	assert_eq(run.hero.potions, HeroState.STARTING_POTIONS)
	assert_eq(run.hero.kills, 0)


func test_the_same_world_seed_gives_the_same_maps() -> void:
	var first := Run.new(1234)
	var again := Run.new(1234)

	for _map in WorldLayout.map_ids().size():
		assert_eq(first.current_map().ascii(), again.current_map().ascii(), first.current_map_id)
		first.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
		again.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())


func test_another_world_seed_gives_other_floors() -> void:
	assert_ne(Run.new(1).current_map().ascii(), Run.new(2).current_map().ascii())


func test_the_crypt_entrance_leads_down_to_the_first_floor_with_everything_the_hero_carries() -> void:
	var run := Run.new(7)

	var destination := run.travel(WorldLayout.Exit.STAIRS_DOWN, _hero_holding("sword", 9))

	assert_false(destination.leaves_world())
	assert_eq(run.current_map().floor_number, 1)
	assert_eq(run.arrival_spot, WorldLayout.Spot.STAIRS_UP)
	assert_eq(run.hero.weapon_id, "sword")
	assert_eq(run.hero.utility_id, "blink")
	assert_eq(run.hero.health, 400)
	assert_eq(run.hero.max_health, 1400)
	assert_eq(run.hero.potions, {"haste": 2})
	assert_eq(run.hero.experience, 3000)
	assert_eq(run.hero.kills, 9)


func test_the_last_floors_stairs_lead_out_of_the_world() -> void:
	var run := Run.new(7)
	for _floor in WorldLayout.FLOOR_COUNT:
		assert_false(run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new()).leaves_world())

	var destination := run.travel(WorldLayout.Exit.STAIRS_DOWN, _hero_holding("bow", 30))

	assert_true(destination.leaves_world())
	assert_eq(run.current_map().floor_number, WorldLayout.FLOOR_COUNT, "the hero stays where they won")
	assert_eq(run.hero.kills, 30, "the summary counts every kill")


func test_the_next_world_has_a_different_seed_and_a_fresh_hero_on_the_plains() -> void:
	var rng := _seeded_rng(5)
	var run := Run.random(rng)
	run.travel(WorldLayout.Exit.STAIRS_DOWN, _hero_holding("sword", 9))

	for _death in 50:
		var next := run.next_world(rng)
		assert_ne(next.world_seed, run.world_seed)
		assert_eq(next.current_map_id, WorldLayout.PLAINS_ID)
		assert_eq(next.hero.weapon_id, GameTuning.DEFAULT_WEAPON_ID)
		assert_eq(next.hero.kills, 0)
		run = next


func test_the_first_floors_stairs_up_lead_back_out_to_the_crypt_entrance() -> void:
	var run := Run.new(7)
	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
	assert_eq(run.arrival_spot, WorldLayout.Spot.STAIRS_UP)

	var destination := run.travel(WorldLayout.Exit.STAIRS_UP, _hero_holding("sword", 4))

	assert_false(destination.leaves_world())
	assert_eq(run.current_map_id, WorldLayout.PLAINS_ID)
	assert_eq(run.arrival_spot, WorldLayout.Spot.STAIRS_DOWN)
	assert_eq(run.hero.weapon_id, "sword")


func test_the_stairs_up_of_a_deeper_floor_lead_back_to_the_stairs_down_of_the_floor_above() -> void:
	var run := Run.new(7)
	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())

	run.travel(WorldLayout.Exit.STAIRS_UP, _hero_holding("sword", 4))

	assert_eq(run.current_map_id, WorldLayout.floor_id(1))
	assert_eq(run.arrival_spot, WorldLayout.Spot.STAIRS_DOWN)


func test_on_every_generated_map_each_set_of_stairs_leads_onto_the_matching_stairs() -> void:
	var parser := DungeonMapParser.new()
	for world_seed in 5:
		var run := Run.new(world_seed)
		for _floor in WorldLayout.FLOOR_COUNT:
			var above := parser.parse(run.current_map().ascii())
			run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
			var below := parser.parse(run.current_map().ascii())
			var arrived_below := WorldLayout.arrival_cell(below, run.arrival_spot)
			assert_eq(WorldLayout.exit_at(below, arrived_below), WorldLayout.Exit.STAIRS_UP, run.current_map_id)

			run.travel(WorldLayout.Exit.STAIRS_UP, HeroState.new())
			var arrived_above := WorldLayout.arrival_cell(above, run.arrival_spot)
			assert_eq(WorldLayout.exit_at(above, arrived_above), WorldLayout.Exit.STAIRS_DOWN, run.current_map_id)
			run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())


## Goes down the stairs from the first floor and back up again.
func _down_and_back(run: Run) -> void:
	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
	run.travel(WorldLayout.Exit.STAIRS_UP, HeroState.new())


func test_a_monster_killed_before_leaving_is_still_dead_on_return() -> void:
	var run := Run.new(3)
	run.record_of(run.current_map_id).kill(Vector2i(10, 4))

	_down_and_back(run)

	assert_true(run.record_of(run.current_map_id).is_killed(Vector2i(10, 4)))
	assert_false(run.record_of(run.current_map_id).is_killed(Vector2i(11, 4)), "only that one")


func test_a_chest_opened_before_leaving_is_still_open_on_return() -> void:
	var run := Run.new(3)
	run.record_of(run.current_map_id).open_chest(2)

	_down_and_back(run)

	assert_true(run.record_of(run.current_map_id).is_chest_opened(2))
	assert_false(run.record_of(run.current_map_id).is_chest_opened(3))


func test_a_floor_item_taken_before_leaving_is_still_gone_on_return() -> void:
	var run := Run.new(3)
	run.record_of(run.current_map_id).take_loot(Vector2i(30, 12))

	_down_and_back(run)

	assert_true(run.record_of(run.current_map_id).is_loot_taken(Vector2i(30, 12)))
	assert_false(run.record_of(run.current_map_id).is_loot_taken(Vector2i(31, 12)))


func test_items_dropped_before_leaving_lie_where_they_were_on_return() -> void:
	var run := Run.new(3)
	var dropped: Array[MapRecord.DroppedItem] = [
		MapRecord.DroppedItem.new("sword", false, Vector2(100, 60)),
		MapRecord.DroppedItem.new("haste", true, Vector2(130.5, 64)),
	]
	run.record_of(run.current_map_id).remember_dropped(dropped)

	_down_and_back(run)

	var found := run.record_of(run.current_map_id).dropped_items()
	assert_eq(found.size(), 2)
	assert_eq([found[0].item_id, found[0].is_potion, found[0].position], ["sword", false, Vector2(100, 60)])
	assert_eq([found[1].item_id, found[1].is_potion, found[1].position], ["haste", true, Vector2(130.5, 64)])


func test_cells_explored_before_leaving_are_still_explored_on_return() -> void:
	var run := Run.new(3)
	var explored: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
	run.record_of(run.current_map_id).remember_explored(explored)

	_down_and_back(run)

	assert_eq(run.record_of(run.current_map_id).explored_cells(), explored)


func test_each_map_keeps_its_own_record() -> void:
	var run := Run.new(3)
	run.record_of(run.current_map_id).kill(Vector2i(10, 4))

	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())

	assert_false(run.record_of(run.current_map_id).is_killed(Vector2i(10, 4)))


func test_a_hurt_monster_left_long_enough_is_back_to_full_health_on_return() -> void:
	var run := Run.new(3)
	run.advance(20.0)
	run.record_of(run.current_map_id).remember_hurt({Vector2i(10, 4): 100}, run.seconds_played)

	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
	run.advance(600.0)
	run.travel(WorldLayout.Exit.STAIRS_UP, HeroState.new())

	var health := run.record_of(run.current_map_id).health_on_return(Vector2i(10, 4), 900, run.seconds_played, 10.0)
	assert_eq(health, 900)


func test_a_hurt_monster_left_briefly_has_healed_only_part_of_the_way() -> void:
	var run := Run.new(3)
	run.record_of(run.current_map_id).remember_hurt({Vector2i(10, 4): 100}, run.seconds_played)

	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
	run.advance(30.0)
	run.travel(WorldLayout.Exit.STAIRS_UP, HeroState.new())

	var health := run.record_of(run.current_map_id).health_on_return(Vector2i(10, 4), 900, run.seconds_played, 10.0)
	assert_eq(health, 400, "100 plus 30 seconds at 10 a second")


func test_a_monster_never_hurt_comes_back_at_full_health() -> void:
	var run := Run.new(3)
	var record := run.record_of(run.current_map_id)
	record.remember_hurt({Vector2i(10, 4): 100}, 0.0)

	assert_eq(record.health_on_return(Vector2i(20, 8), 900, 1.0, 10.0), 900)


func test_a_record_knows_which_generator_made_its_map() -> void:
	var run := Run.new(3)

	assert_eq(run.record_of(run.current_map_id).generator_version, QuadrantRecipe.VERSION)
	assert_eq(run.record_of(WorldLayout.floor_id(1)).generator_version, DungeonGenerator.VERSION)


func test_the_next_world_remembers_nothing_of_this_one() -> void:
	var rng := _seeded_rng(9)
	var run := Run.random(rng)
	run.record_of(run.current_map_id).kill(Vector2i(10, 4))
	run.advance(50.0)

	var next := run.next_world(rng)

	assert_false(next.record_of(next.current_map_id).is_killed(Vector2i(10, 4)))
	assert_eq(next.seconds_played, 0.0)


func test_same_seed_again_makes_the_same_world_from_the_start() -> void:
	var run := Run.new(77)
	run.travel(WorldLayout.Exit.STAIRS_DOWN, _hero_holding("sword", 9))
	run.record_of(WorldLayout.PLAINS_ID).kill(Vector2i(10, 4))

	var again := run.same_world_again()

	assert_eq(again.world_seed, 77)
	assert_eq(again.current_map_id, WorldLayout.PLAINS_ID)
	assert_eq(again.current_map().ascii(), Run.new(77).current_map().ascii())
	assert_eq(again.hero.weapon_id, GameTuning.DEFAULT_WEAPON_ID, "a fresh hero")
	assert_false(again.record_of(WorldLayout.PLAINS_ID).is_killed(Vector2i(10, 4)), "a fresh world")


func test_a_new_world_is_made_with_the_recipe_it_is_given() -> void:
	var run := Run.new(5)
	var small := QuadrantRecipe.new()
	small.width = 100
	small.height = 60

	var next := run.next_world(_seeded_rng(1), small)
	var map := DungeonMapParser.new().parse(next.current_map().ascii())

	assert_eq(map.size, Vector2i(100, 60))
	assert_eq(DungeonMapParser.new().parse(run.same_world_again(small).current_map().ascii()).size, Vector2i(100, 60))


func test_a_campfires_cooldown_does_not_run_while_the_hero_is_on_another_map() -> void:
	var run := Run.new(3)
	var profile := RestProfile.campfire()
	var plains := run.record_of(run.current_map_id)
	plains.remember_campfire(Vector2i(30, 30), Campfire.new(profile, Campfire.State.EMBERS, 60.0))

	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
	run.advance(10_000.0)
	run.travel(WorldLayout.Exit.STAIRS_UP, HeroState.new())

	var fire := run.record_of(run.current_map_id).campfire_at(Vector2i(30, 30), profile)
	assert_eq(fire.state, Campfire.State.EMBERS)
	assert_eq(fire.seconds_left(), 60.0)


func test_the_hero_walks_from_the_plains_through_all_three_crypt_levels_and_back_up_onto_the_matching_stairs() -> void:
	var parser := DungeonMapParser.new()
	var run := Run.new(21)
	var visited: Array[String] = [run.current_map_id]

	for _level in WorldLayout.FLOOR_COUNT:
		run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())
		visited.append(run.current_map_id)
		var map := parser.parse(run.current_map().ascii())
		assert_eq(WorldLayout.arrival_cell(map, run.arrival_spot), map.stairs_up_cell, run.current_map_id)
	assert_eq(visited, [WorldLayout.PLAINS_ID, "crypt_1", "crypt_2", "crypt_3"])

	for level in range(WorldLayout.FLOOR_COUNT, 0, -1):
		run.travel(WorldLayout.Exit.STAIRS_UP, HeroState.new())
		var map := parser.parse(run.current_map().ascii())
		assert_eq(run.current_map_id, visited[level - 1])
		assert_eq(WorldLayout.arrival_cell(map, run.arrival_spot), map.exit_cell, run.current_map_id)


func test_the_crypt_recipe_of_a_world_is_kept_for_its_levels_and_for_the_next_worlds() -> void:
	var crypt := CryptRecipe.new()
	crypt.campfire_rooms_from_stairs = 5
	var run := Run.new(1, QuadrantRecipe.plains(), crypt)
	run.travel(WorldLayout.Exit.STAIRS_DOWN, HeroState.new())

	assert_eq(run.current_map().crypt, crypt)
	assert_eq(run.same_world_again().crypt, crypt)
	assert_eq(run.next_world(_seeded_rng(3)).crypt, crypt)
