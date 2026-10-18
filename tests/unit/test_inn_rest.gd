extends GutTest
## Resting at the inn: a short wait that heals to full, cancelled by moving or a hit, usable again at once.

const MAX_HEALTH := 1000
const STEP := 0.1

var _rest := InnRest.new()


## Runs the rest for seconds in STEP steps; returns how it ended (NONE if it did not).
func _run(seconds: float, moving := false) -> InnRest.Step:
	for i in roundi(seconds / STEP):
		var step := _rest.tick(STEP, moving)
		if step != InnRest.Step.NONE:
			return step
	return InnRest.Step.NONE


func test_the_rest_completes_after_three_seconds_and_heals_to_full() -> void:
	_rest.begin()

	assert_eq(_run(2.5), InnRest.Step.NONE)
	assert_true(_rest.is_resting())
	assert_eq(_run(0.6), InnRest.Step.COMPLETED)
	assert_false(_rest.is_resting())
	assert_eq(_rest.heal_for(100, MAX_HEALTH), MAX_HEALTH - 100)


func test_a_hero_already_at_full_health_is_healed_nothing() -> void:
	assert_eq(_rest.heal_for(MAX_HEALTH, MAX_HEALTH), 0)


func test_moving_cancels_the_rest() -> void:
	_rest.begin()
	_run(1.0)

	assert_eq(_run(0.2, true), InnRest.Step.CANCELLED)
	assert_false(_rest.is_resting())


func test_a_hit_cancels_the_rest() -> void:
	_rest.begin()
	_run(1.0)

	assert_true(_rest.interrupt())
	assert_false(_rest.is_resting())
	assert_eq(_run(5.0), InnRest.Step.NONE, "a cancelled rest never completes")


func test_a_cancelled_rest_starts_over_at_once() -> void:
	_rest.begin()
	_run(2.0)
	_rest.interrupt()

	assert_true(_rest.begin())
	assert_eq(_run(2.5), InnRest.Step.NONE, "the interrupted time does not count")
	assert_eq(_run(0.6), InnRest.Step.COMPLETED)


func test_a_finished_rest_can_be_taken_again_at_once_without_limit() -> void:
	for i in 3:
		assert_true(_rest.begin())
		assert_eq(_run(3.1), InnRest.Step.COMPLETED)


func test_sitting_down_while_already_resting_changes_nothing() -> void:
	_rest.begin()
	_run(2.0)

	assert_false(_rest.begin())
	assert_eq(_run(1.1), InnRest.Step.COMPLETED)


func test_progress_grows_from_nothing_to_done() -> void:
	assert_eq(_rest.progress(), 0.0)
	_rest.begin()
	_run(1.5)

	assert_almost_eq(_rest.progress(), 0.5, 0.05)


func test_the_rest_time_is_the_profiles() -> void:
	var profile := RestProfile.inn()
	profile.rest_seconds = 1.0
	_rest = InnRest.new(profile)
	_rest.begin()

	assert_eq(_run(1.1), InnRest.Step.COMPLETED)


func test_a_profile_that_does_not_cancel_on_move_lets_the_hero_walk() -> void:
	var profile := RestProfile.inn()
	profile.cancels_on_move = false
	_rest = InnRest.new(profile)
	_rest.begin()

	assert_eq(_run(3.1, true), InnRest.Step.COMPLETED)


func test_nothing_ticks_when_not_resting() -> void:
	assert_eq(_rest.tick(5.0, true), InnRest.Step.NONE)


func test_the_inn_is_a_three_second_full_heal_with_no_embers() -> void:
	var inn := RestProfile.inn()

	assert_eq(inn.rest_seconds, 3.0)
	assert_eq(inn.heal_ceiling(MAX_HEALTH), MAX_HEALTH)
	assert_eq(inn.embers_seconds, 0.0)
	assert_true(inn.cancels_on_move)


func test_the_inns_rest_time_is_a_tunable_knob() -> void:
	var fields: Array[String] = []
	for knob in RestProfile.inn().knobs():
		fields.append(knob.field)
	assert_has(fields, "rest_seconds")

	var tuning := GameTuning.create()
	tuning.set_value(GameTuning.key("inn", "rest_seconds"), 5.0)
	assert_eq(GameTuning.inn_profile(tuning).rest_seconds, 5.0)
