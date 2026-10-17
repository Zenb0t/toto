extends GutTest
## Opens and closes the credits screen the way a player would.


func _panel() -> CreditsPanel:
	var panel := CreditsPanel.new()
	add_child_autofree(panel)
	return panel


func _press_escape() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)


func _texts_of(node: Node) -> PackedStringArray:
	var texts := PackedStringArray()
	for child in node.get_children():
		if child is Label or child is BaseButton:
			texts.append(child.text)
		texts.append_array(_texts_of(child))
	return texts


func test_it_is_hidden_until_opened() -> void:
	assert_false(_panel().visible)


func test_opening_shows_every_credited_work_with_its_author() -> void:
	var panel := _panel()
	panel.open()
	var texts := " | ".join(_texts_of(panel))
	for entry in Credits.entries():
		assert_string_contains(texts, entry.name)
		assert_string_contains(texts, entry.author)


func test_pressing_back_closes_it_and_says_so() -> void:
	var panel := _panel()
	watch_signals(panel)
	panel.open()
	panel.close()
	assert_false(panel.visible)
	assert_signal_emitted(panel, "finished")


func test_escape_closes_it() -> void:
	var panel := _panel()
	watch_signals(panel)
	panel.open()
	_press_escape()
	await wait_process_frames(2)
	assert_false(panel.visible)
	assert_signal_emitted(panel, "finished")
