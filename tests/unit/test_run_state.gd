extends GutTest


func after_each() -> void:
	RunState.take_carried()  # Never leak a carried run into other tests.


func test_a_run_starts_on_the_top_floor_with_the_starting_kit() -> void:
	var run := RunState.new()

	assert_eq(run.floor_number, 1)
	assert_eq(run.weapon_id, GameTuning.DEFAULT_WEAPON_ID)
	assert_eq(run.utility_id, GameTuning.DEFAULT_UTILITY_ID)
	assert_eq(run.health, run.max_health)
	assert_eq(run.potions, RunState.STARTING_POTIONS)


func test_the_stairs_lead_one_floor_down_with_what_the_player_holds() -> void:
	var run := RunState.new()

	var next := run.next_floor("sword", "blink", Health.restored(14, 4), {"haste": 2}, 30)

	assert_eq(next.floor_number, 2)
	assert_eq(next.weapon_id, "sword")
	assert_eq(next.utility_id, "blink")
	assert_eq(next.health, 4)
	assert_eq(next.max_health, 14)
	assert_eq(next.potions, {"haste": 2})
	assert_eq(next.experience, 30)


func test_only_the_bottom_floor_leads_out() -> void:
	var run := RunState.new()
	for _i in RunState.FLOOR_COUNT - 1:
		assert_false(run.is_last_floor(), str(run.floor_number))
		run = run.next_floor("wand", "dash", Health.new(10), {}, 0)

	assert_true(run.is_last_floor())


func test_a_carried_run_is_picked_up_on_the_next_floor() -> void:
	var next := RunState.new().next_floor("sword", "dash", Health.new(10), {}, 0)

	RunState.carry(next)

	assert_eq(RunState.take_carried(), next)


func test_with_nothing_carried_a_new_run_starts() -> void:
	RunState.carry(RunState.new().next_floor("sword", "dash", Health.new(10), {}, 0))
	RunState.take_carried()

	assert_eq(RunState.take_carried().floor_number, 1, "dying or restarting starts over")
