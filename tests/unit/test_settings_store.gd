extends GutTest

const PATH := "user://test_settings.cfg"


func before_each() -> void:
	DirAccess.remove_absolute(PATH)


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func test_a_saved_section_is_there_next_time_the_game_starts() -> void:
	assert_eq(SettingsStore.new(PATH).save_section("audio", {"volume": 0.5}), OK)

	assert_eq(SettingsStore.new(PATH).load_section("audio"), {"volume": 0.5})


func test_saving_one_section_keeps_the_others() -> void:
	var store := SettingsStore.new(PATH)
	store.save_section("audio", {"volume": 0.5})

	store.save_section("video", {"shake": true})

	assert_eq(store.load_section("audio"), {"volume": 0.5})


func test_saving_a_section_replaces_its_old_keys() -> void:
	var store := SettingsStore.new(PATH)
	store.save_section("audio", {"volume": 0.5, "old_key": 1})

	store.save_section("audio", {"volume": 0.8})

	assert_eq(store.load_section("audio"), {"volume": 0.8})


func test_first_launch_reads_as_empty() -> void:
	assert_eq(SettingsStore.new(PATH).load_section("audio"), {})


func test_a_corrupt_settings_file_reads_as_empty() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("this is [not a config file")
	file.close()

	assert_eq(SettingsStore.new(PATH).load_section("audio"), {})
