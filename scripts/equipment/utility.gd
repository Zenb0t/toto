class_name Utility
extends RefCounted
## What the second button does. A plain data object.
## The defaults describe the starter Dash: a short burst of speed in the aimed direction.

var display_name := "Dash"
var button_label := "DASH"
var color := Color(0.45, 0.85, 1)
## Seconds between uses.
var cooldown := 1.5
var dash_speed := 650.0
var dash_duration := 0.18


## How far the aim preview reaches: the distance one dash covers.
func aim_range() -> float:
	return dash_speed * dash_duration
