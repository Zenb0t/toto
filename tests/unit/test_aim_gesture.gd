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


func test_dragging_back_to_the_centre_turns_it_back_into_a_tap() -> void:
	var gesture := _pressed_gesture()
	gesture.move_to(BUTTON + Vector2(80, 0))
	gesture.move_to(BUTTON + Vector2(3, 0))

	assert_true(gesture.release().is_auto)


func test_gesture_ends_on_release() -> void:
	var gesture := _pressed_gesture()

	gesture.release()

	assert_false(gesture.is_active())
