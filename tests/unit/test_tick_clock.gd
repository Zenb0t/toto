extends GutTest
## A tick clock says how many ticks of a lingering effect came due as time passes.


func _ticks_over(clock: TickClock, seconds: float, step := 1.0 / 60.0) -> int:
	var total := 0
	for i in roundi(seconds / step):
		total += clock.advance(step)
	return total


func test_the_first_tick_can_come_at_once() -> void:
	assert_eq(TickClock.new(0.0, 0.6, 5).advance(0.016), 1)


func test_the_first_tick_can_wait_for_the_first_interval() -> void:
	var clock := TickClock.new(0.5, 0.5, 3)

	assert_eq(clock.advance(0.4), 0)
	assert_eq(clock.advance(0.1), 1, "due exactly at half a second")


func test_it_never_ticks_more_than_its_count() -> void:
	assert_eq(_ticks_over(TickClock.new(0.5, 0.5, 3), 5.0), 3)


func test_a_long_frame_brings_every_tick_that_fell_inside_it() -> void:
	assert_eq(TickClock.new(0.5, 0.5, 3).advance(1.2), 2)


func test_a_patch_ticks_after_each_interval_up_to_its_end() -> void:
	assert_eq(TickClock.count_after_each_interval(1.5, 0.5), 3)
	assert_eq(TickClock.count_after_each_interval(0.4, 0.5), 0, "gone before the first tick")


func test_a_cloud_ticks_from_its_first_tick_through_its_end() -> void:
	assert_eq(TickClock.count_from(0.6, 6.0, 0.6), 10, "0.6, 1.2 ... 6.0")
	assert_eq(TickClock.count_from(0.0, 3.0, 0.6), 6, "0, 0.6 ... 3.0")
	assert_eq(TickClock.count_from(1.0, 0.5, 0.6), 0, "gone before the first tick")
