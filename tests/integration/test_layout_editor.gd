extends GutTest
## Drives the layout editor with real touches, as the player would from the pause menu.

const EDITOR_SCENE := preload("res://scenes/ui/layout_editor.tscn")


func _to_window(viewport_position: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * viewport_position


func _touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = _to_window(position)
	event.pressed = pressed
	Input.parse_input_event(event)


func _drag(position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position = _to_window(position)
	Input.parse_input_event(event)


func _open_editor(layout: ControlLayout) -> LayoutEditor:
	var editor: LayoutEditor = EDITOR_SCENE.instantiate()
	add_child_autofree(editor)
	editor.open(layout)
	return editor


func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size


func _last_layout(editor: LayoutEditor, signal_name: String) -> ControlLayout:
	return get_signal_parameters(editor, signal_name)[0]


func test_dragging_a_control_moves_it_by_the_same_amount() -> void:
	var editor := _open_editor(ControlLayout.new())
	watch_signals(editor)
	var start := ControlLayout.new().rect_in(ControlLayout.ATTACK, _screen()).get_center()
	var finish := start + Vector2(-200, -150)

	_touch(start, true)
	_drag(finish)
	_touch(finish, false)
	await wait_process_frames(2)

	var moved := _last_layout(editor, "layout_changed").rect_in(ControlLayout.ATTACK, _screen())
	assert_almost_eq(moved.get_center(), finish, Vector2(0.5, 0.5))


func test_the_size_slider_resizes_the_picked_control() -> void:
	var editor := _open_editor(ControlLayout.new())
	watch_signals(editor)
	var dash := ControlLayout.new().rect_in(ControlLayout.MOVEMENT, _screen()).get_center()
	_touch(dash, true)
	_touch(dash, false)
	await wait_process_frames(2)

	editor.get_node("Bar/Size").value = 250.0

	assert_eq(_last_layout(editor, "layout_changed").diameter_of(ControlLayout.MOVEMENT), 250.0)


func test_touching_empty_space_changes_nothing() -> void:
	var editor := _open_editor(ControlLayout.new())
	watch_signals(editor)

	_touch(Vector2(640, 300), true)
	_drag(Vector2(700, 350))
	_touch(Vector2(700, 350), false)
	await wait_process_frames(2)

	assert_signal_not_emitted(editor, "layout_changed")


func test_editing_does_not_change_the_layout_it_was_opened_with() -> void:
	var original := ControlLayout.new()
	var editor := _open_editor(original)
	var start := original.rect_in(ControlLayout.ATTACK, _screen()).get_center()

	_touch(start, true)
	_drag(start + Vector2(-300, 0))
	_touch(start + Vector2(-300, 0), false)
	await wait_process_frames(2)

	assert_eq(original.to_dict(), ControlLayout.new().to_dict())


func test_done_hands_back_the_edited_layout_and_closes() -> void:
	var editor := _open_editor(ControlLayout.new())
	watch_signals(editor)
	editor.get_node("Bar/Size").value = 120.0

	editor.get_node("Bar/Done").pressed.emit()

	assert_false(editor.visible)
	assert_eq(_last_layout(editor, "finished").diameter_of(ControlLayout.ATTACK), 120.0)


func test_reset_brings_back_the_default_layout() -> void:
	var edited := ControlLayout.new()
	edited.set_diameter(ControlLayout.ATTACK, 300.0)
	var editor := _open_editor(edited)
	watch_signals(editor)

	editor.get_node("Bar/Reset").pressed.emit()

	assert_eq(_last_layout(editor, "layout_changed").to_dict(), ControlLayout.new().to_dict())
