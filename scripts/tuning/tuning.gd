class_name Tuning
extends RefCounted
## A set of named numeric knobs with limits and defaults, for tweaking the game's feel while playing.
## Knows nothing about the game itself: GameTuning defines the knobs and turns them into game objects.

const EXPORT_MARKER := "toto_tuning"
const EXPORT_VERSION := 1


## One knob: how it is shown and which values it accepts.
class Param:
	var key: String
	var label: String
	var group: String
	var min_value: float
	var max_value: float
	var step: float
	var default_value: float
	## Changes only show up on the next run (e.g. things decided when the dungeon spawns).
	var next_run_only: bool

	func _init(
			param_key: String, param_label: String, param_group: String, minimum: float, maximum: float,
			step_size: float, default: float, applies_next_run := false) -> void:
		key = param_key
		label = param_label
		group = param_group
		min_value = minimum
		max_value = maximum
		step = step_size
		default_value = default
		next_run_only = applies_next_run

	func accept(value: float) -> float:
		return clampf(snappedf(value, step), min_value, max_value)


var _params: Array[Param] = []
var _values := {}  # key -> float


func _init(params: Array[Param]) -> void:
	_params = params
	reset()


func params() -> Array[Param]:
	return _params


func param(key: String) -> Param:
	for candidate in _params:
		if candidate.key == key:
			return candidate
	return null


func value(key: String) -> float:
	return _values[key]


## Stores the closest value the knob accepts (snapped to its step, kept within its limits).
func set_value(key: String, new_value: float) -> void:
	_values[key] = param(key).accept(new_value)


func reset() -> void:
	for each in _params:
		_values[each.key] = each.default_value


func is_changed(key: String) -> bool:
	return not is_equal_approx(_values[key], param(key).default_value)


func changed_keys() -> Array[String]:
	var keys: Array[String] = []
	for each in _params:
		if is_changed(each.key):
			keys.append(each.key)
	return keys


func copy() -> Tuning:
	var duplicate := Tuning.new(_params)
	duplicate.load_dict(to_dict())
	return duplicate


func to_dict() -> Dictionary:
	return _values.duplicate()


## Takes every known key with a numeric value; ignores the rest, so old or hand-edited saves can't break it.
func load_dict(data: Dictionary) -> void:
	for each in _params:
		var saved: Variant = data.get(each.key)
		if saved is float or saved is int:
			set_value(each.key, saved)


## Readable JSON with every value, plus which ones differ from the defaults.
func export_text() -> String:
	var export := {EXPORT_MARKER: EXPORT_VERSION, "changed": changed_keys(), "values": to_dict()}
	return JSON.stringify(export, "  ", false)
