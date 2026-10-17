class_name Knob
extends RefCounted
## A field of an item (weapon, utility) that the Tune screen may change, and the values it accepts.
## The field's current value on a fresh item is its default.

var field: String
var label: String
var min_value: float
var max_value: float
var step: float
## Health points (damage, healing): these moved to a finer scale once, and old saves get scaled with them.
var is_points: bool


func _init(
		field_name: String, knob_label: String, minimum: float, maximum: float, step_size: float,
		counts_points := false) -> void:
	field = field_name
	label = knob_label
	min_value = minimum
	max_value = maximum
	step = step_size
	is_points = counts_points
