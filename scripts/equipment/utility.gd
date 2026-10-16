class_name Utility
extends RefCounted
## What the second button does. A plain data object.
## The defaults describe the starter Dash: a short burst of speed in the aimed direction.

## Stable identifier: used in tuning keys, so never rename it.
var id := "dash"
var display_name := "Dash"
var button_label := "DASH"
var color := Color(0.45, 0.85, 1)
## Seconds between uses.
var cooldown := 0.7
var dash_speed := 650.0
var dash_duration := 0.18


## The fields the Tune screen may change.
func knobs() -> Array[Knob]:
	return [
		Knob.new("dash_speed", "Dash speed", 200, 1500, 25),
		Knob.new("dash_duration", "Dash time (s)", 0.05, 0.5, 0.01),
		Knob.new("cooldown", "Cooldown (s)", 0.2, 5.0, 0.1),
	]


## How far the aim preview reaches: the distance one dash covers.
func aim_range() -> float:
	return dash_speed * dash_duration


func aim_shape() -> AimShape:
	return AimShape.line(aim_range())
