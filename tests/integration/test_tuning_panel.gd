extends GutTest
## The tuning screen as the player uses it from the pause menu: a menu of sections, a page per weapon,
## utility and potion, and rows of knobs.

const PANEL_SCENE := preload("res://scenes/ui/tuning_panel.tscn")
const WINDUP_ROW := "wand_windup"
const WAND_WINDUP := "wand.windup"


func _open_panel(tuning := GameTuning.create()) -> TuningPanel:
	var panel: TuningPanel = PANEL_SCENE.instantiate()
	add_child_autofree(panel)
	panel.open(tuning, GameTuning.sections(GameTuning.DEFAULT_WEAPON_ID, GameTuning.DEFAULT_UTILITY_ID))
	return panel


func _last_tuning(panel: TuningPanel, signal_name: String) -> Tuning:
	return get_signal_parameters(panel, signal_name)[0]


## Presses the menu entry or bar button with that name, as a finger or a click would.
func _press(panel: TuningPanel, button_name: String) -> void:
	var button: Button = panel.find_child(button_name.validate_node_name(), true, false)
	assert_not_null(button, "no %s button" % button_name)
	button.pressed.emit()
	await wait_process_frames(1)


func _open_weapon(panel: TuningPanel, weapon_id: String) -> void:
	await _press(panel, "Weapons")
	await _press(panel, GameTuning.weapon_group(weapon_id))


func _title(panel: TuningPanel) -> String:
	return (panel.get_node("Bar/Title") as Label).text


func _row(panel: TuningPanel, row_name: String) -> Node:
	return panel.find_child(row_name, true, false)


func test_opens_on_the_menu_of_sections() -> void:
	var panel := _open_panel()

	for section in GameTuning.sections("wand", "dash"):
		assert_not_null(_row(panel, section.title), section.title)
	assert_null(_row(panel, WINDUP_ROW))


func test_every_knob_can_be_reached_through_the_menus() -> void:
	var panel := _open_panel()

	for section in GameTuning.sections("wand", "dash"):
		for group in section.groups:
			await _press(panel, section.title)
			if section.has_submenu():
				await _press(panel, group)
			for param in GameTuning.create().params().filter(func(each: Tuning.Param) -> bool: return each.group == group):
				assert_not_null(_row(panel, param.key.replace(".", "_")), param.key)
			panel.back()
			if section.has_submenu():
				panel.back()
			await wait_process_frames(1)


func test_any_weapon_can_be_tuned_not_only_the_equipped_one() -> void:
	var panel := _open_panel()

	await _open_weapon(panel, "sword")

	assert_not_null(_row(panel, "sword_reach"))
	assert_null(_row(panel, WINDUP_ROW))
	assert_string_contains(_title(panel), "Sword")


func test_back_goes_up_one_page_at_a_time() -> void:
	var panel := _open_panel()
	await _open_weapon(panel, "sword")

	await _press(panel, "Back")
	assert_not_null(_row(panel, GameTuning.weapon_group("wand").validate_node_name()))

	await _press(panel, "Back")
	assert_not_null(_row(panel, "Enemies"))


func test_back_from_the_menu_finishes_like_done() -> void:
	var panel := _open_panel()
	watch_signals(panel)

	panel.back()

	assert_false(panel.visible)
	assert_signal_emitted(panel, "finished")


func test_plus_raises_a_value_by_one_step_and_reports_it() -> void:
	var panel := _open_panel()
	watch_signals(panel)
	var param := GameTuning.create().param(WAND_WINDUP)

	panel.nudge(WAND_WINDUP, 1)

	var tuned := _last_tuning(panel, "tuning_changed").value(WAND_WINDUP)
	assert_almost_eq(tuned, param.default_value + param.step, 0.0001)


func test_dragging_a_slider_changes_its_value() -> void:
	var panel := _open_panel()
	await _open_weapon(panel, "wand")
	watch_signals(panel)
	var slider: HSlider = _row(panel, WINDUP_ROW).get_node("Slider")

	slider.value = 0.7

	assert_almost_eq(_last_tuning(panel, "tuning_changed").value(WAND_WINDUP), 0.7, 0.0001)


func test_menu_entries_holding_changed_knobs_are_marked() -> void:
	var tweaked := GameTuning.create()
	tweaked.set_value(GameTuning.key("sword", "reach"), 80)
	var panel := _open_panel(tweaked)

	var weapons: Button = _row(panel, "Weapons")
	var enemies: Button = _row(panel, "Enemies")
	assert_string_contains(weapons.text, TuningPanel.CHANGED_MARK)
	assert_false(enemies.text.contains(TuningPanel.CHANGED_MARK))


func test_editing_does_not_change_the_tuning_it_was_opened_with() -> void:
	var original := GameTuning.create()
	var panel := _open_panel(original)

	panel.nudge(WAND_WINDUP, 3)

	assert_eq(original.changed_keys(), [] as Array[String])


func test_reset_on_a_page_brings_back_only_that_pages_defaults() -> void:
	var tweaked := GameTuning.create()
	tweaked.set_value(WAND_WINDUP, 0.9)
	tweaked.set_value(GameTuning.PLAYER_MOVE_SPEED, 200)
	var panel := _open_panel(tweaked)
	await _open_weapon(panel, "wand")
	watch_signals(panel)

	await _press(panel, "Reset")

	var changed := _last_tuning(panel, "tuning_changed").changed_keys()
	assert_eq(changed, [GameTuning.PLAYER_MOVE_SPEED] as Array[String])


func test_reset_on_the_menu_brings_back_every_default() -> void:
	var tweaked := GameTuning.create()
	tweaked.set_value(WAND_WINDUP, 0.9)
	tweaked.set_value(GameTuning.PLAYER_MOVE_SPEED, 200)
	var panel := _open_panel(tweaked)
	watch_signals(panel)

	await _press(panel, "Reset")

	assert_eq(_last_tuning(panel, "tuning_changed").changed_keys(), [] as Array[String])


func test_done_hands_back_the_tuned_values_and_closes() -> void:
	var panel := _open_panel()
	watch_signals(panel)
	panel.nudge(GameTuning.PLAYER_MOVE_SPEED, -2)

	await _press(panel, "Done")

	assert_false(panel.visible)
	assert_eq(_last_tuning(panel, "finished").changed_keys(), [GameTuning.PLAYER_MOVE_SPEED] as Array[String])


func test_reopening_shows_the_latest_values() -> void:
	var panel := _open_panel()
	var tweaked := GameTuning.create()
	tweaked.set_value(WAND_WINDUP, 0.8)

	panel.open(tweaked, GameTuning.sections("wand", "dash"))
	await _open_weapon(panel, "wand")

	var slider: HSlider = _row(panel, WINDUP_ROW).get_node("Slider")
	assert_almost_eq(slider.value, 0.8, 0.0001)
