extends GutTest

const PATH := "user://test_settings.cfg"


func before_each() -> void:
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func test_a_saved_layout_is_there_next_time_the_game_starts() -> void:
	var layout := ControlLayout.new()
	layout.set_center(ControlLayout.ATTACK, Vector2(0.5, 0.5))
	layout.set_diameter(ControlLayout.ATTACK, 260.0)

	assert_eq(SettingsStore.new(PATH).save_layout(layout), OK)
	var loaded := SettingsStore.new(PATH).load_layout()

	assert_eq(loaded.center_of(ControlLayout.ATTACK), Vector2(0.5, 0.5))
	assert_eq(loaded.diameter_of(ControlLayout.ATTACK), 260.0)


func test_first_launch_uses_the_default_layout() -> void:
	var loaded := SettingsStore.new(PATH).load_layout()

	assert_eq(loaded.to_dict(), ControlLayout.new().to_dict())


func test_a_corrupt_settings_file_uses_the_default_layout() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("this is [not a config file")
	file.close()

	var loaded := SettingsStore.new(PATH).load_layout()

	assert_eq(loaded.to_dict(), ControlLayout.new().to_dict())
