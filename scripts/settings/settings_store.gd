class_name SettingsStore
extends RefCounted
## Saves player settings to disk. Missing or unreadable files never break the game: they load as defaults.

const DEFAULT_PATH := "user://settings.cfg"
const _SECTION := "touch_controls"
const _KEY := "layout"

var _path: String


func _init(path := DEFAULT_PATH) -> void:
	_path = path


func load_layout() -> ControlLayout:
	var config := ConfigFile.new()
	if config.load(_path) != OK:
		return ControlLayout.new()
	var data: Variant = config.get_value(_SECTION, _KEY, {})
	return ControlLayout.from_dict(data) if data is Dictionary else ControlLayout.new()


func save_layout(layout: ControlLayout) -> Error:
	var config := ConfigFile.new()
	config.load(_path)  # Keep any other sections; a missing file is fine.
	config.set_value(_SECTION, _KEY, layout.to_dict())
	return config.save(_path)
