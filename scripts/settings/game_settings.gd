class_name GameSettings
extends RefCounted
## The game's saved settings and the shape they are saved in.
## Keep the section and key names stable: changing them forgets what players already saved.

const _LAYOUT_SECTION := "touch_controls"
const _LAYOUT_KEY := "layout"
const _TUNING_SECTION := "tuning"
const _TUNING_KEY := "values"
## How many health points one point of health was when the values were saved. Saves from before it
## existed were on the old scale, where a hero had 10 health instead of 1000.
const _TUNING_SCALE_KEY := "health_scale"
const OLD_HEALTH_SCALE := 1
const HEALTH_SCALE := 100

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
	var section := _store.load_section(_TUNING_SECTION)
	var data: Variant = section.get(_TUNING_KEY)
	if data is Dictionary:
		var factor := _points_factor(section.get(_TUNING_SCALE_KEY, OLD_HEALTH_SCALE))
		tuning.load_dict(GameTuning.rescaled_points(data, factor))
	return tuning


## What saved health points are multiplied by to reach today's scale. A broken scale leaves them as they are.
static func _points_factor(saved_scale: Variant) -> float:
	if (saved_scale is int or saved_scale is float) and saved_scale > 0:
		return float(HEALTH_SCALE) / saved_scale
	return 1.0


func save_tuning(tuning: Tuning) -> Error:
	return _store.save_section(_TUNING_SECTION, {_TUNING_KEY: tuning.to_dict(), _TUNING_SCALE_KEY: HEALTH_SCALE})



## The minimap shows unless the player hid it.
func load_minimap_shown() -> bool:
	return _store.load_section(_MINIMAP_SECTION).get(_MINIMAP_KEY, true) == true


func save_minimap_shown(shown: bool) -> Error:
	return _store.save_section(_MINIMAP_SECTION, {_MINIMAP_KEY: shown})
