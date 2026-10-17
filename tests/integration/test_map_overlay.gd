extends GutTest
## Opens and closes the big map the way a player would: by tapping, clicking or pressing keys.

const LAYOUT := """
#######
#P....>
#######
"""


func _overlay() -> MapOverlay:
	var overlay := MapOverlay.new()
	add_child_autofree(overlay)
	var map := DungeonMapParser.new().parse(LAYOUT)
	var exploration := Exploration.new()
	exploration.look_from(map.player_spawn, func(_cell: Vector2i) -> bool: return true)
	overlay.open(map, exploration, map.player_spawn)
	await wait_process_frames(1)  # Lets the overlay settle on the screen's size.
	return overlay


func _click_at(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = get_viewport().get_final_transform() * position
	Input.parse_input_event(event)


func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)


func test_it_is_hidden_until_opened() -> void:
	var overlay: MapOverlay = autofree(MapOverlay.new())
	add_child(overlay)

	assert_false(overlay.visible)


func test_opening_shows_the_map() -> void:
	var overlay := await _overlay()

	assert_true(overlay.visible)


func test_a_tap_anywhere_closes_it() -> void:
	var overlay := await _overlay()
	watch_signals(overlay)

	_click_at(Vector2(30, 30))
	await wait_process_frames(2)

	assert_false(overlay.visible)
	assert_signal_emitted(overlay, "closed")


func test_escape_closes_it() -> void:
	var overlay := await _overlay()
	watch_signals(overlay)

	_press(KEY_ESCAPE)
	await wait_process_frames(2)

	assert_false(overlay.visible)
	assert_signal_emitted(overlay, "closed")


func test_m_closes_it() -> void:
	var overlay := await _overlay()

	_press(KEY_M)
	await wait_process_frames(2)

	assert_false(overlay.visible)


func test_tapping_the_minimap_asks_to_see_the_whole_map() -> void:
	var minimap := MinimapView.new()
	add_child_autofree(minimap)
	minimap.size = Vector2(200, 100)
	watch_signals(minimap)

	_click_at(minimap.position + Vector2(50, 50))
	await wait_process_frames(2)

	assert_signal_emitted(minimap, "pressed")
