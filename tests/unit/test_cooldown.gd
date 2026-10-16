extends GutTest


func test_is_ready_before_first_use() -> void:
	var cooldown := Cooldown.new(1.0)

	assert_true(cooldown.is_ready())


func test_triggering_makes_it_unavailable() -> void:
	var cooldown := Cooldown.new(1.0)

	var triggered := cooldown.try_trigger()

	assert_true(triggered)
	assert_false(cooldown.is_ready())


func test_cannot_trigger_again_while_cooling_down() -> void:
	var cooldown := Cooldown.new(1.0)
	cooldown.try_trigger()

	assert_false(cooldown.try_trigger())


func test_becomes_ready_once_enough_time_has_passed() -> void:
	var cooldown := Cooldown.new(1.0)
	cooldown.try_trigger()

	cooldown.tick(0.6)
	assert_false(cooldown.is_ready())

	cooldown.tick(0.6)
	assert_true(cooldown.is_ready())


func test_can_be_triggered_again_after_recovering() -> void:
	var cooldown := Cooldown.new(0.5)
	cooldown.try_trigger()
	cooldown.tick(0.5)

	assert_true(cooldown.try_trigger())


func test_reports_how_much_of_the_cooldown_is_left() -> void:
	var cooldown := Cooldown.new(2.0)
	assert_eq(cooldown.remaining_ratio(), 0.0)

	cooldown.try_trigger()
	assert_eq(cooldown.remaining_ratio(), 1.0)

	cooldown.tick(0.5)
	assert_almost_eq(cooldown.remaining_ratio(), 0.75, 0.001)
