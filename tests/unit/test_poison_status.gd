extends GutTest
## Poison doesn't stack: at most one tick per interval gets through, whichever cloud it comes from.


func test_the_first_tick_goes_through() -> void:
	assert_true(PoisonStatus.new().try_tick(0.0))


func test_a_second_tick_inside_the_interval_is_blocked() -> void:
	var status := PoisonStatus.new()
	status.try_tick(10.0)

	assert_false(status.try_tick(10.0), "another cloud ticking the same moment")
	assert_false(status.try_tick(10.3), "a cloud with a different rhythm")


func test_a_tick_a_full_interval_later_goes_through() -> void:
	var status := PoisonStatus.new()
	status.try_tick(10.0)

	assert_true(status.try_tick(10.0 + PoisonStatus.TICK_SECONDS))


func test_a_single_clouds_ticks_a_frame_early_or_late_are_never_blocked() -> void:
	var status := PoisonStatus.new()
	status.try_tick(1.0)

	assert_true(status.try_tick(1.0 + PoisonStatus.TICK_SECONDS - 1.0 / 60.0))


func test_a_blocked_tick_does_not_push_the_next_one_back() -> void:
	var status := PoisonStatus.new()
	status.try_tick(0.0)
	status.try_tick(0.4)

	assert_true(status.try_tick(0.6))
