class_name Knob
extends RefCounted
## A field of an item (weapon, utility) that the Tune screen may change, and the values it accepts.
## The field's current value on a fresh item is its default.

var field: String
var label: String
var min_value: float
var max_value: float
var step: float


func _init(field_name: String, knob_label: String, minimum: float, maximum: float, step_size: float) -> void:
	field = field_name
	label = knob_label
	min_value = minimum
	max_value = maximum
	step = step_size
