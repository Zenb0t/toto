extends GutTest

const DEAD_ZONE := 20.0
const BUTTON := Vector2(500, 300)


func _pressed_gesture() -> AimGesture:
	var gesture := AimGesture.new(DEAD_ZONE)
	gesture.begin(BUTTON)
	return gesture


func test_a_tap_requests_auto_aim() -> void:
	var gesture := _pressed_gesture()

	var release := gesture.release()

	assert_true(release.is_auto)


func test_a_small_wiggle_inside_the_dead_zone_is_still_a_tap() -> void:
	var gesture := _pressed_gesture()
	gesture.move_to(BUTTON + Vector2(10, 5))

	assert_false(gesture.is_manual())
	assert_true(gesture.release().is_auto)


func test_dragging_past_the_dead_zone_aims_manually() -> void:
	var gesture := _pressed_gesture()

	gesture.move_to(BUTTON + Vector2(0, 80))

	assert_true(gesture.is_manual())
	assert_almost_eq(gesture.direction(), Vector2.DOWN, Vector2(0.001, 0.001))


func test_releasing_after_a_drag_fires_in_the_dragged_direction() -> void:
	var gesture := _pressed_gesture()
	gesture.move_to(BUTTON + Vector2(-60, 0))

	var release := gesture.release()

	assert_false(release.is_auto)
	assert_almost_eq(release.direction, Vector2.LEFT, Vector2(0.001, 0.001))


func test_gesture_ends_on_release() -> void:
	var gesture := _pressed_gesture()

	gesture.release()

	assert_false(gesture.is_active())


func test_dragging_to_the_buttons_edge_is_half_strength() -> void:
	var gesture := AimGesture.new(DEAD_ZONE)
	gesture.begin(BUTTON, 120.0, 300.0)

	gesture.move_to(BUTTON + Vector2(70, 0))
	var halfway_to_the_edge := gesture.strength()
	gesture.move_to(BUTTON + Vector2(120, 0))
	var at_the_edge := gesture.strength()

	assert_almost_eq(halfway_to_the_edge, 0.25, 0.001)
	assert_almost_eq(at_the_edge, 0.5, 0.001)


func test_dragging_past_the_button_keeps_adding_strength_up_to_the_full_reach() -> void:
	var gesture := AimGesture.new(DEAD_ZONE)
	gesture.begin(BUTTON, 120.0, 300.0)

	gesture.move_to(BUTTON + Vector2(210, 0))
	var past_the_edge := gesture.strength()
	gesture.move_to(BUTTON + Vector2(500, 0))
	var beyond_the_reach := gesture.strength()

	assert_almost_eq(past_the_edge, 0.75, 0.001)
	assert_eq(beyond_the_reach, 1.0)


func test_a_tap_has_no_strength() -> void:
	var gesture := AimGesture.new(DEAD_ZONE)
	gesture.begin(BUTTON, 120.0)
	gesture.move_to(BUTTON + Vector2(5, 0))

	assert_eq(gesture.strength(), 0.0)


func test_releasing_reports_the_strength_of_the_drag() -> void:
	var gesture := AimGesture.new(DEAD_ZONE)
	gesture.begin(BUTTON, 120.0, 300.0)
	gesture.move_to(BUTTON + Vector2(0, -300))

	assert_eq(gesture.release().strength, 1.0)


func test_aiming_then_coming_back_to_the_middle_cancels_instead_of_auto_aiming() -> void:
	var gesture := _pressed_gesture()
	gesture.move_to(BUTTON + Vector2(0, -80))
	gesture.move_to(BUTTON + Vector2(3, 2))

	var release := gesture.release()

	assert_true(release.is_cancelled)
	assert_false(release.is_auto)


func test_aiming_out_again_after_coming_back_fires_normally() -> void:
	var gesture := _pressed_gesture()
	gesture.move_to(BUTTON + Vector2(0, -80))
	gesture.move_to(BUTTON)
	gesture.move_to(BUTTON + Vector2(80, 0))

	var release := gesture.release()

	assert_false(release.is_cancelled)
	assert_almost_eq(release.direction, Vector2.RIGHT, Vector2.ONE * 0.001)


func test_a_plain_tap_is_never_a_cancel() -> void:
	var release := _pressed_gesture().release()

	assert_false(release.is_cancelled)
	assert_true(release.is_auto)


func test_a_new_press_forgets_that_the_last_one_aimed() -> void:
	var gesture := _pressed_gesture()
	gesture.move_to(BUTTON + Vector2(0, -80))
	gesture.release()

	gesture.begin(BUTTON)

	assert_true(gesture.release().is_auto)
