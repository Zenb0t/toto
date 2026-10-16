extends GutTest
## Which kind of play (touch, or keyboard and mouse) the game follows.

const TOUCH := InputMode.Kind.TOUCH
const KEYBOARD_MOUSE := InputMode.Kind.KEYBOARD_MOUSE


func _touch(device := 0) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	event.device = device
	return event


func _click(device := 0) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.device = device
	return event


func _key() -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = true
	return event


func test_phones_start_with_touch_and_computers_with_keyboard_and_mouse() -> void:
	assert_eq(InputMode.initial(true), TOUCH)
	assert_eq(InputMode.initial(false), KEYBOARD_MOUSE)


func test_pressing_a_key_switches_to_keyboard_and_mouse() -> void:
	assert_eq(InputMode.after(_key(), TOUCH), KEYBOARD_MOUSE)


func test_clicking_the_mouse_switches_to_keyboard_and_mouse() -> void:
	assert_eq(InputMode.after(_click(), TOUCH), KEYBOARD_MOUSE)


func test_touching_the_screen_switches_to_touch() -> void:
	assert_eq(InputMode.after(_touch(), KEYBOARD_MOUSE), TOUCH)


func test_a_click_made_up_from_a_touch_does_not_switch_away_from_touch() -> void:
	assert_eq(InputMode.after(_click(InputEvent.DEVICE_ID_EMULATION), TOUCH), TOUCH)


func test_a_touch_made_up_from_a_click_does_not_switch_away_from_keyboard_and_mouse() -> void:
	assert_eq(InputMode.after(_touch(InputEvent.DEVICE_ID_EMULATION), KEYBOARD_MOUSE), KEYBOARD_MOUSE)


func test_letting_go_changes_nothing() -> void:
	var lift := _touch()
	lift.pressed = false

	assert_eq(InputMode.after(lift, KEYBOARD_MOUSE), KEYBOARD_MOUSE)
