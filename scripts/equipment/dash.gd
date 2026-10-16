class_name Dash
extends Utility
## The starter utility: a short burst of speed in the aimed direction.

var dash_speed := 650.0
var dash_duration := 0.18


func _init() -> void:
	id = "dash"
	display_name = "Dash"
	description = "A quick burst of speed where you aim."
	button_label = "DASH"
	color = Color(0.45, 0.85, 1)
	cooldown = 0.7


func knobs() -> Array[Knob]:
	var result: Array[Knob] = [
		Knob.new("dash_speed", "Dash speed", 200, 1500, 25),
		Knob.new("dash_duration", "Dash time (s)", 0.05, 0.5, 0.01),
	]
	result.append_array(super.knobs())
	return result


func activate(direction: Vector2) -> UtilityEffect:
	return UtilityEffect.dash(direction, dash_speed, dash_duration)


## The distance one dash covers.
func aim_range() -> float:
	return dash_speed * dash_duration


func aim_shape() -> AimShape:
	return AimShape.line(aim_range())
