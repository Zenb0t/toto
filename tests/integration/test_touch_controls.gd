extends GutTest
## Drives the touch widgets with real screen-touch events, the same way a phone would.

const BUTTON_RECT := Rect2(400, 200, 100, 100)
const BUTTON_CENTER := Vector2(450, 250)


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
	_drag(Vector2(100 + TouchStick.RADIUS, 100))
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
	_drag(Vector2(100, 100 + TouchStick.RADIUS), 0)
	_touch(BUTTON_CENTER, true, 1)
	_touch(BUTTON_CENTER, false, 1)
	await wait_process_frames(2)

	assert_almost_eq(stick.current_strength(), Vector2.DOWN, Vector2(0.01, 0.01))
	assert_signal_emit_count(button, "aim_released", 1)
