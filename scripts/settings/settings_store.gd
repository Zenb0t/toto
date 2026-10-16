class_name SettingsStore
extends RefCounted
## Saves player settings to disk as named sections of key/value pairs.
## Missing or unreadable files never break the game: they read as empty, and callers fall back to defaults.

const DEFAULT_PATH := "user://settings.cfg"

var _path: String


func _init(path := DEFAULT_PATH) -> void:
	_path = path


func load_section(section: String) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(_path) != OK or not config.has_section(section):
		return {}
	var data := {}
	for key in config.get_section_keys(section):
		data[key] = config.get_value(section, key)
	return data


## Replaces one section and keeps the others.
func save_section(section: String, data: Dictionary) -> Error:
	var config := ConfigFile.new()
	config.load(_path)  # A missing file is fine: it is created on save.
	if config.has_section(section):
		config.erase_section(section)
	for key: String in data:
		config.set_value(section, key, data[key])
	return config.save(_path)
