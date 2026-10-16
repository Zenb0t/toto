extends GutTest
## The tuning screen as the player uses it from the pause menu.

const PANEL_SCENE := preload("res://scenes/ui/tuning_panel.tscn")
const WINDUP_ROW := "wand_windup"
const WAND_WINDUP := "wand.windup"


func _open_panel(tuning := GameTuning.create()) -> TuningPanel:
	var panel: TuningPanel = PANEL_SCENE.instantiate()
	add_child_autofree(panel)
	panel.open(tuning)
	return panel


func _last_tuning(panel: TuningPanel, signal_name: String) -> Tuning:
	return get_signal_parameters(panel, signal_name)[0]


func _press(button: Button) -> void:
	button.pressed.emit()


func test_shows_one_row_per_knob() -> void:
	var panel := _open_panel()

	for param in GameTuning.create().params():
		assert_not_null(panel.find_child(param.key.replace(".", "_"), true, false), param.key)


func test_plus_raises_a_value_by_one_step_and_reports_it() -> void:
	var panel := _open_panel()
	watch_signals(panel)
	var param := GameTuning.create().param(WAND_WINDUP)

	panel.nudge(WAND_WINDUP, 1)

	var tuned := _last_tuning(panel, "tuning_changed").value(WAND_WINDUP)
	assert_almost_eq(tuned, param.default_value + param.step, 0.0001)


func test_dragging_a_slider_changes_its_value() -> void:
	var panel := _open_panel()
	watch_signals(panel)
	var slider: HSlider = panel.find_child(WINDUP_ROW, true, false).get_node("Slider")

	slider.value = 0.7

	assert_almost_eq(_last_tuning(panel, "tuning_changed").value(WAND_WINDUP), 0.7, 0.0001)


func test_editing_does_not_change_the_tuning_it_was_opened_with() -> void:
	var original := GameTuning.create()
	var panel := _open_panel(original)

	panel.nudge(WAND_WINDUP, 3)

	assert_eq(original.changed_keys(), [] as Array[String])


func test_reset_brings_back_the_defaults() -> void:
	var tweaked := GameTuning.create()
	tweaked.set_value(WAND_WINDUP, 0.9)
	var panel := _open_panel(tweaked)
	watch_signals(panel)

	_press(panel.get_node("Bar/Reset"))

	assert_eq(_last_tuning(panel, "tuning_changed").changed_keys(), [] as Array[String])


func test_done_hands_back_the_tuned_values_and_closes() -> void:
	var panel := _open_panel()
	watch_signals(panel)
	panel.nudge(GameTuning.PLAYER_MOVE_SPEED, -2)

	_press(panel.get_node("Bar/Done"))

	assert_false(panel.visible)
	assert_eq(_last_tuning(panel, "finished").changed_keys(), [GameTuning.PLAYER_MOVE_SPEED] as Array[String])


func test_reopening_shows_the_latest_values() -> void:
	var panel := _open_panel()
	var tweaked := GameTuning.create()
	tweaked.set_value(WAND_WINDUP, 0.8)

	panel.open(tweaked)

	var slider: HSlider = panel.find_child(WINDUP_ROW, true, false).get_node("Slider")
	assert_almost_eq(slider.value, 0.8, 0.0001)


func test_shows_only_the_groups_it_was_asked_for() -> void:
	var tuning := GameTuning.create()
	var panel: TuningPanel = PANEL_SCENE.instantiate()
	add_child_autofree(panel)

	panel.open(tuning, GameTuning.visible_groups(tuning, "sword", GameTuning.DEFAULT_UTILITY_ID))

	assert_not_null(panel.find_child("sword_reach", true, false))
	assert_null(panel.find_child(WINDUP_ROW, true, false))
