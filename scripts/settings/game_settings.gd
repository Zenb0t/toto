class_name GameSettings
extends RefCounted
## The game's saved settings and the shape they are saved in.
## Keep the section and key names stable: changing them forgets what players already saved.

const _LAYOUT_SECTION := "touch_controls"
const _LAYOUT_KEY := "layout"
const _TUNING_SECTION := "tuning"
const _TUNING_KEY := "values"

const _MINIMAP_SECTION := "minimap"
const _MINIMAP_KEY := "shown"

var _store: SettingsStore


func _init(store := SettingsStore.new()) -> void:
	_store = store


func load_layout() -> ControlLayout:
	var data: Variant = _store.load_section(_LAYOUT_SECTION).get(_LAYOUT_KEY)
	return ControlLayout.from_dict(data) if data is Dictionary else ControlLayout.new()


func save_layout(layout: ControlLayout) -> Error:
	return _store.save_section(_LAYOUT_SECTION, {_LAYOUT_KEY: layout.to_dict()})


func load_tuning() -> Tuning:
	var tuning := GameTuning.create()
	var data: Variant = _store.load_section(_TUNING_SECTION).get(_TUNING_KEY)
	if data is Dictionary:
		tuning.load_dict(data)
	return tuning


func save_tuning(tuning: Tuning) -> Error:
	return _store.save_section(_TUNING_SECTION, {_TUNING_KEY: tuning.to_dict()})



## The minimap shows unless the player hid it.
func load_minimap_shown() -> bool:
	return _store.load_section(_MINIMAP_SECTION).get(_MINIMAP_KEY, true) == true


func save_minimap_shown(shown: bool) -> Error:
	return _store.save_section(_MINIMAP_SECTION, {_MINIMAP_KEY: shown})
