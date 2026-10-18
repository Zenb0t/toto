extends GutTest
## A campfire's life: unlit, burning (healing a hero in its light), embers, unlit again.

const MAX_HEALTH := 1000
const STEP := 0.1

var _profile := RestProfile.campfire()


## Runs the fire for seconds in STEP steps with the hero standing in its light (or not); returns what it healed.
func _run(fire: Campfire, seconds: float, in_light := true, health := 100) -> int:
	var healed := 0
	for i in roundi(seconds / STEP):
		healed += fire.tick(STEP, in_light, health + healed, MAX_HEALTH)
	return healed


func _lit() -> Campfire:
	var fire := Campfire.new(_profile)
	fire.light()
	return fire


func test_a_fresh_campfire_is_unlit_and_can_be_lit() -> void:
	var fire := Campfire.new(_profile)

	assert_eq(fire.state, Campfire.State.UNLIT)
	assert_true(fire.can_light())
	assert_true(fire.light())
	assert_eq(fire.state, Campfire.State.BURNING)


func test_a_burning_campfire_cannot_be_lit_again() -> void:
	var fire := _lit()

	assert_false(fire.can_light())
	assert_false(fire.light())


func test_a_campfire_burns_for_its_time_then_turns_to_embers() -> void:
	var fire := _lit()

	_run(fire, _profile.burn_seconds - 1.0)
	assert_eq(fire.state, Campfire.State.BURNING)
	_run(fire, 1.0 + STEP)

	assert_eq(fire.state, Campfire.State.EMBERS)


func test_embers_count_down_and_block_lighting_until_the_cooldown_ends() -> void:
	var fire := _lit()
	_run(fire, _profile.burn_seconds + STEP)

	_run(fire, _profile.embers_seconds - 1.0)
	assert_false(fire.can_light(), "still cooling")
	assert_false(fire.light())
	assert_almost_eq(fire.seconds_left(), 1.0 - STEP, 0.2)
	_run(fire, 1.0 + STEP)

	assert_eq(fire.state, Campfire.State.UNLIT)
	assert_true(fire.light(), "it can be lit again")


func test_a_hero_in_the_light_heals_at_the_profiles_rate() -> void:
	var fire := _lit()

	var healed := _run(fire, 2.0)

	assert_eq(healed, roundi(2.0 * _profile.heal_per_second))


func test_resting_never_heals_past_half_the_maximum_health() -> void:
	var fire := _lit()

	var healed := _run(fire, _profile.burn_seconds, true, 100)

	assert_eq(100 + healed, MAX_HEALTH / 2)


func test_a_hero_already_above_the_ceiling_is_not_healed() -> void:
	var fire := _lit()

	assert_eq(_run(fire, 3.0, true, 800), 0)


func test_the_ceiling_follows_the_profile() -> void:
	var inn_like := RestProfile.new()
	inn_like.heal_share = 1.0
	inn_like.heal_per_second = 300.0
	var fire := Campfire.new(inn_like)
	fire.light()

	var healed := _run(fire, inn_like.burn_seconds, true, 100)

	assert_eq(100 + healed, MAX_HEALTH)


func test_healing_pauses_outside_the_light_and_resumes_inside_it() -> void:
	var fire := _lit()
	var before := _run(fire, 1.0)

	var outside := _run(fire, 2.0, false, 100 + before)
	var back_inside := _run(fire, 1.0, true, 100 + before)

	assert_eq(outside, 0)
	assert_gt(back_inside, 0)


func test_the_fire_burns_on_while_the_hero_is_out_of_the_light() -> void:
	var fire := _lit()

	_run(fire, _profile.burn_seconds + STEP, false)

	assert_eq(fire.state, Campfire.State.EMBERS)


func test_a_hit_or_an_attack_stops_the_healing_for_good() -> void:
	var fire := _lit()
	var before := _run(fire, 1.0)

	fire.interrupt()

	assert_eq(_run(fire, 2.0, true, 100 + before), 0)
	assert_eq(fire.state, Campfire.State.BURNING, "the fire itself burns on")


func test_lighting_it_again_after_the_embers_heals_again() -> void:
	var fire := _lit()
	fire.interrupt()
	_run(fire, _profile.burn_seconds + _profile.embers_seconds + 1.0)

	fire.light()

	assert_gt(_run(fire, 1.0), 0)


func test_the_last_burst_of_healing_is_cut_at_the_moment_the_fire_dies() -> void:
	var fire := _lit()

	var healed := fire.tick(_profile.burn_seconds + 50.0, true, 100, 100_000)

	assert_eq(healed, floori(_profile.burn_seconds * _profile.heal_per_second))


func test_a_campfire_restored_with_time_left_carries_on_from_there() -> void:
	var embers := Campfire.new(_profile, Campfire.State.EMBERS, 30.0)

	_run(embers, 29.0)
	assert_false(embers.can_light())
	_run(embers, 1.5)

	assert_true(embers.can_light())


func test_light_reaches_the_profiles_radius_and_no_further() -> void:
	assert_true(_profile.lights(_profile.light_radius_cells))
	assert_false(_profile.lights(_profile.light_radius_cells + 0.1))
