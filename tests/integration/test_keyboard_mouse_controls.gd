extends GutTest
## Drives keyboard and mouse play with real key and mouse events, the way a computer would.


## Real mouse events arrive in window pixels and Godot maps them into the stretched viewport.
func _to_window(viewport_position: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * viewport_position


func _controls(mode := InputMode.Kind.KEYBOARD_MOUSE) -> KeyboardMouseControls:
	var controls := KeyboardMouseControls.new()
	controls.mode = mode
	add_child_autofree(controls)
	return controls


func _mouse(button: MouseButton, pressed: bool, at := Vector2(600, 300)) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = _to_window(at)
	Input.parse_input_event(event)


func _key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)


func _touch(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	event.position = _to_window(at)
	Input.parse_input_event(event)


func test_holding_the_left_button_holds_the_attack_until_it_is_let_go() -> void:
	var controls := _controls()

	_mouse(MOUSE_BUTTON_LEFT, true)
	await wait_process_frames(1)
	assert_true(controls.is_attack_held())

	_mouse(MOUSE_BUTTON_LEFT, false)
	await wait_process_frames(1)
	assert_false(controls.is_attack_held())


func test_space_and_shift_use_the_movement() -> void:
	var controls := _controls()
	watch_signals(controls)

	_key(KEY_SPACE)
	_key(KEY_SHIFT)
	await wait_process_frames(1)

	assert_signal_emit_count(controls, "movement_requested", 2)
	assert_signal_not_emitted(controls, "skill_requested")


func test_the_right_button_uses_the_skill() -> void:
	var controls := _controls()
	watch_signals(controls)

	_mouse(MOUSE_BUTTON_RIGHT, true)
	_mouse(MOUSE_BUTTON_RIGHT, false)
	await wait_process_frames(1)

	assert_signal_emit_count(controls, "skill_requested", 1)
	assert_signal_not_emitted(controls, "movement_requested")


func test_number_keys_drink_the_potion_in_that_slot() -> void:
	var controls := _controls()
	watch_signals(controls)

	_key(KEY_2)
	await wait_process_frames(1)

	assert_signal_emitted_with_parameters(controls, "potion_requested", [1])


func test_e_takes_the_item_and_q_switches_weapon() -> void:
	var controls := _controls()
	watch_signals(controls)

	_key(KEY_E)
	_key(KEY_Q)
	await wait_process_frames(1)

	assert_signal_emitted(controls, "take_requested")
	assert_signal_emitted(controls, "weapon_switch_requested")


func test_m_asks_to_toggle_the_minimap() -> void:
	var controls := _controls()
	watch_signals(controls)

	_key(KEY_M)
	await wait_process_frames(1)

	assert_signal_emitted(controls, "minimap_toggle_requested")


func test_clicking_a_button_on_screen_does_not_attack() -> void:
	var controls := _controls()
	var button := Button.new()
	button.position = Vector2(500, 250)
	button.size = Vector2(200, 100)
	add_child_autofree(button)
	await wait_process_frames(1)

	_mouse(MOUSE_BUTTON_LEFT, true, Vector2(600, 300))
	await wait_process_frames(1)

	assert_false(controls.is_attack_held())
	_mouse(MOUSE_BUTTON_LEFT, false, Vector2(600, 300))


func test_using_the_mouse_switches_from_touch_to_keyboard_and_mouse() -> void:
	var controls := _controls(InputMode.Kind.TOUCH)
	watch_signals(controls)

	_mouse(MOUSE_BUTTON_RIGHT, true)
	_mouse(MOUSE_BUTTON_RIGHT, false)
	await wait_process_frames(1)

	assert_true(controls.is_keyboard_mouse())
	assert_signal_emitted_with_parameters(controls, "mode_changed", [InputMode.Kind.KEYBOARD_MOUSE])


func test_touching_the_screen_switches_to_touch_and_ends_a_held_attack() -> void:
	var controls := _controls()
	_mouse(MOUSE_BUTTON_LEFT, true)
	await wait_process_frames(1)

	_touch(Vector2(100, 100))
	await wait_process_frames(1)

	assert_false(controls.is_keyboard_mouse())
	assert_false(controls.is_attack_held())
	_mouse(MOUSE_BUTTON_LEFT, false)


func test_while_playing_by_touch_a_tap_does_not_attack() -> void:
	var controls := _controls(InputMode.Kind.TOUCH)

	_touch(Vector2(600, 300))
	await wait_process_frames(1)

	assert_false(controls.is_attack_held())
