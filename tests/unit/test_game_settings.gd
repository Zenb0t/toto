extends GutTest

const PATH := "user://test_game_settings.cfg"


func before_each() -> void:
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _settings() -> GameSettings:
	return GameSettings.new(SettingsStore.new(PATH))


func test_a_saved_layout_is_there_next_time_the_game_starts() -> void:
	var layout := ControlLayout.new()
	layout.set_diameter(ControlLayout.ATTACK, 260.0)

	assert_eq(_settings().save_layout(layout), OK)

	assert_eq(_settings().load_layout().diameter_of(ControlLayout.ATTACK), 260.0)


func test_saved_tuning_is_there_next_time_the_game_starts() -> void:
	var tuning := GameTuning.create()
	tuning.set_value(GameTuning.key("wand", "windup"), 0.5)

	assert_eq(_settings().save_tuning(tuning), OK)

	assert_eq(_settings().load_tuning().value(GameTuning.key("wand", "windup")), 0.5)


func test_saved_damage_is_there_next_time_the_game_starts() -> void:
	var tuning := GameTuning.create()
	tuning.set_value(GameTuning.key("sword", "damage"), 250)
	_settings().save_tuning(tuning)

	assert_eq(_settings().load_tuning().value(GameTuning.key("sword", "damage")), 250.0)


func test_damage_saved_before_health_went_up_a_hundredfold_is_scaled_with_it() -> void:
	var config := ConfigFile.new()
	config.set_value("tuning", "values", {"sword.damage": 3, "wand.windup": 0.4})
	config.save(PATH)

	var tuning := _settings().load_tuning()

	assert_eq(tuning.value(GameTuning.key("sword", "damage")), 300.0)
	assert_eq(tuning.value(GameTuning.key("wand", "windup")), 0.4)


func test_saving_tuning_keeps_the_saved_layout() -> void:
	var layout := ControlLayout.new()
	layout.set_diameter(ControlLayout.MOVEMENT, 222.0)
	_settings().save_layout(layout)

	_settings().save_tuning(GameTuning.create())

	assert_eq(_settings().load_layout().diameter_of(ControlLayout.MOVEMENT), 222.0)


func test_first_launch_uses_defaults() -> void:
	assert_eq(_settings().load_layout().to_dict(), ControlLayout.new().to_dict())
	assert_eq(_settings().load_tuning().changed_keys(), [] as Array[String])


func test_a_layout_saved_by_the_previous_build_still_loads() -> void:
	var old_layout := ControlLayout.new()
	old_layout.set_diameter(ControlLayout.ATTACK, 250.0)
	var config := ConfigFile.new()
	config.set_value("touch_controls", "layout", old_layout.to_dict())
	config.save(PATH)

	assert_eq(_settings().load_layout().diameter_of(ControlLayout.ATTACK), 250.0)


func test_the_minimap_shows_until_the_player_hides_it() -> void:
	assert_true(_settings().load_minimap_shown())


func test_a_hidden_minimap_stays_hidden_next_time_the_game_starts() -> void:
	assert_eq(_settings().save_minimap_shown(false), OK)

	assert_false(_settings().load_minimap_shown())
