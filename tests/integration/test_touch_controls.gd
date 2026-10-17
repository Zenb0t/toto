extends GutTest
## Drives the touch widgets with real screen-touch events, the same way a phone would.

const BUTTON_RECT := Rect2(400, 200, 100, 100)
const BUTTON_CENTER := Vector2(450, 250)
const TOUCH_CONTROLS_SCENE := preload("res://scenes/ui/touch_controls.tscn")


## Real touches arrive in window pixels and Godot maps them into the stretched viewport.
## The headless test window is tiny, so convert viewport positions back to window pixels first.
func _to_window(viewport_position: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * viewport_position


func _touch(position: Vector2, pressed: bool, index := 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = _to_window(position)
	event.pressed = pressed
	Input.parse_input_event(event)


func _drag(position: Vector2, index := 0) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = _to_window(position)
	Input.parse_input_event(event)


func _aim_button() -> AimButton:
	var button := AimButton.new()
	button.position = BUTTON_RECT.position
	button.size = BUTTON_RECT.size
	add_child_autofree(button)
	return button


func _stick() -> TouchStick:
	var stick := TouchStick.new()
	stick.size = Vector2(300, 300)
	add_child_autofree(stick)
	return stick


func _last_release(button: AimButton) -> AimGesture.Release:
	return get_signal_parameters(button, "aim_released")[0]


func test_tapping_the_attack_button_requests_auto_aim() -> void:
	var button := _aim_button()
	watch_signals(button)

	_touch(BUTTON_CENTER, true)
	_touch(BUTTON_CENTER, false)
	await wait_process_frames(2)

	assert_signal_emit_count(button, "aim_released", 1)
	assert_true(_last_release(button).is_auto)


func test_dragging_from_the_attack_button_fires_where_you_dragged() -> void:
	var button := _aim_button()
	watch_signals(button)

	_touch(BUTTON_CENTER, true)
	_drag(BUTTON_CENTER + Vector2(0, -120))
	_touch(BUTTON_CENTER + Vector2(0, -120), false)
	await wait_process_frames(2)

	var release := _last_release(button)
	assert_false(release.is_auto)
	assert_almost_eq(release.direction, Vector2.UP, Vector2(0.01, 0.01))


func test_touches_outside_the_button_are_ignored() -> void:
	var button := _aim_button()
	watch_signals(button)

	_touch(Vector2(10, 10), true)
	_touch(Vector2(10, 10), false)
	await wait_process_frames(2)

	assert_signal_not_emitted(button, "aim_released")


func test_stick_follows_the_thumb_from_wherever_it_landed() -> void:
	var stick := _stick()

	_touch(Vector2(100, 100), true)
	_drag(Vector2(100 + stick.radius, 100))
	await wait_process_frames(2)

	assert_almost_eq(stick.current_strength(), Vector2.RIGHT, Vector2(0.01, 0.01))


func test_releasing_the_stick_stops_movement() -> void:
	var stick := _stick()
	_touch(Vector2(100, 100), true)
	_drag(Vector2(150, 100))

	_touch(Vector2(150, 100), false)
	await wait_process_frames(2)

	assert_eq(stick.current_strength(), Vector2.ZERO)


func test_stick_and_button_work_at_the_same_time_with_two_fingers() -> void:
	var stick := _stick()
	var button := _aim_button()
	watch_signals(button)

	_touch(Vector2(100, 100), true, 0)
	_drag(Vector2(100, 100 + stick.radius), 0)
	_touch(BUTTON_CENTER, true, 1)
	_touch(BUTTON_CENTER, false, 1)
	await wait_process_frames(2)

	assert_almost_eq(stick.current_strength(), Vector2.DOWN, Vector2(0.01, 0.01))
	assert_signal_emit_count(button, "aim_released", 1)


func test_buttons_answer_touches_where_the_layout_puts_them() -> void:
	var controls: TouchControls = TOUCH_CONTROLS_SCENE.instantiate()
	add_child_autofree(controls)
	var layout := ControlLayout.new()
	layout.set_center(ControlLayout.ATTACK, Vector2(0.5, 0.3))
	controls.apply_layout(layout)
	watch_signals(controls.attack_button)
	var new_spot := layout.rect_in(ControlLayout.ATTACK, get_viewport().get_visible_rect().size).get_center()

	_touch(new_spot, true)
	_touch(new_spot, false)
	await wait_process_frames(2)

	assert_signal_emit_count(controls.attack_button, "aim_released", 1)


func test_a_bigger_stick_needs_a_longer_thumb_drag_for_full_speed() -> void:
	var controls: TouchControls = TOUCH_CONTROLS_SCENE.instantiate()
	add_child_autofree(controls)
	var layout := ControlLayout.new()
	layout.set_diameter(ControlLayout.STICK, 300.0)
	controls.apply_layout(layout)

	_touch(Vector2(200, 400), true)
	_drag(Vector2(275, 400))
	await wait_process_frames(2)

	assert_almost_eq(controls.move_stick.current_strength(), Vector2(0.5, 0), Vector2(0.01, 0.01))
	_touch(Vector2(275, 400), false)


func test_pausing_mid_aim_cancels_the_shot_instead_of_leaving_the_button_stuck() -> void:
	var button := _aim_button()
	watch_signals(button)
	_touch(BUTTON_CENTER, true)
	_drag(BUTTON_CENTER + Vector2(0, -120))
	await wait_process_frames(2)

	get_tree().paused = true
	get_tree().paused = false
	_touch(BUTTON_CENTER, true)
	_touch(BUTTON_CENTER, false)
	await wait_process_frames(2)

	assert_signal_emit_count(button, "aim_released", 1)
	assert_true(_last_release(button).is_auto)


func test_a_short_drag_inside_a_larger_dead_zone_still_counts_as_a_tap() -> void:
	var button := _aim_button()
	button.dead_zone = 60.0
	watch_signals(button)

	_touch(BUTTON_CENTER, true)
	_drag(BUTTON_CENTER + Vector2(40, 0))
	_touch(BUTTON_CENTER + Vector2(40, 0), false)
	await wait_process_frames(2)

	assert_true(_last_release(button).is_auto)


func test_a_drag_past_a_smaller_dead_zone_aims_manually() -> void:
	var button := _aim_button()
	button.dead_zone = 10.0
	watch_signals(button)

	_touch(BUTTON_CENTER, true)
	_drag(BUTTON_CENTER + Vector2(20, 0))
	_touch(BUTTON_CENTER + Vector2(20, 0), false)
	await wait_process_frames(2)

	var release := _last_release(button)
	assert_false(release.is_auto)
	assert_almost_eq(release.direction, Vector2.RIGHT, Vector2(0.01, 0.01))


func test_with_touch_off_the_attack_button_ignores_touches() -> void:
	var button := _aim_button()
	button.accepts_touch = false
	watch_signals(button)

	_touch(BUTTON_CENTER, true)
	_touch(BUTTON_CENTER, false)
	await wait_process_frames(2)

	assert_signal_not_emitted(button, "aim_released")


func test_turning_touch_off_mid_drag_lets_go_without_firing() -> void:
	var button := _aim_button()
	watch_signals(button)
	_touch(BUTTON_CENTER, true)
	_drag(BUTTON_CENTER + Vector2(0, -120))
	await wait_process_frames(1)

	button.accepts_touch = false
	_touch(BUTTON_CENTER + Vector2(0, -120), false)
	await wait_process_frames(1)

	assert_signal_not_emitted(button, "aim_released")
	assert_eq(get_signal_parameters(button, "aim_changed")[0], Vector2.ZERO)


func test_with_touch_off_the_stick_hides_and_stays_still() -> void:
	var stick := _stick()
	stick.accepts_touch = false

	_touch(Vector2(100, 100), true)
	_drag(Vector2(180, 100))
	await wait_process_frames(1)

	assert_false(stick.visible)
	assert_eq(stick.current_strength(), Vector2.ZERO)


func test_a_tap_just_outside_the_button_but_inside_its_catch_zone_still_counts() -> void:
	var button := _aim_button()
	watch_signals(button)
	var beside := BUTTON_CENTER + Vector2(70, 0)  # The button's radius is 50; its catch zone reaches 80.

	_touch(beside, true)
	_touch(beside, false)
	await wait_process_frames(2)

	assert_signal_emit_count(button, "aim_released", 1)
	assert_true(_last_release(button).is_auto)


func test_the_aim_is_measured_from_where_the_finger_landed_not_from_the_button() -> void:
	var button := _aim_button()
	watch_signals(button)
	var landed := BUTTON_CENTER + Vector2(40, 0)

	_touch(landed, true)
	_drag(landed + Vector2(0, -120))
	_touch(landed + Vector2(0, -120), false)
	await wait_process_frames(2)

	assert_almost_eq(_last_release(button).direction, Vector2.UP, Vector2(0.01, 0.01))


func test_where_two_catch_zones_overlap_the_nearer_button_takes_the_touch() -> void:
	var near := _aim_button()
	var far := _aim_button()
	far.position += Vector2(130, 0)
	watch_signals(near)
	watch_signals(far)
	var between_but_nearer_the_first := BUTTON_CENTER + Vector2(55, 0)

	_touch(between_but_nearer_the_first, true)
	_touch(between_but_nearer_the_first, false)
	await wait_process_frames(2)

	assert_signal_emit_count(near, "aim_released", 1)
	assert_signal_not_emitted(far, "aim_released")


func test_a_smaller_catch_zone_ignores_touches_beside_the_button() -> void:
	var button := _aim_button()
	button.catch_scale = 1.0
	watch_signals(button)

	_touch(BUTTON_CENTER + Vector2(70, 0), true)
	_touch(BUTTON_CENTER + Vector2(70, 0), false)
	await wait_process_frames(2)

	assert_signal_not_emitted(button, "aim_released")


func test_aiming_and_coming_back_into_the_dead_zone_is_reported_once() -> void:
	var button := _aim_button()
	watch_signals(button)

	_touch(BUTTON_CENTER, true)
	_drag(BUTTON_CENTER + Vector2(0, -120))
	await wait_process_frames(1)  # Drags in the same frame are merged into one.
	_drag(BUTTON_CENTER + Vector2(0, -5))
	await wait_process_frames(1)
	_drag(BUTTON_CENTER + Vector2(0, -3))
	await wait_process_frames(1)

	assert_signal_emit_count(button, "returned_to_dead_zone", 1)
	_touch(BUTTON_CENTER, false)


func test_wiggling_inside_the_dead_zone_reports_nothing() -> void:
	var button := _aim_button()
	watch_signals(button)

	_touch(BUTTON_CENTER, true)
	_drag(BUTTON_CENTER + Vector2(5, 5))
	await wait_process_frames(1)
	_drag(BUTTON_CENTER + Vector2(-5, 0))
	await wait_process_frames(2)

	assert_signal_not_emitted(button, "returned_to_dead_zone")
	_touch(BUTTON_CENTER, false)
