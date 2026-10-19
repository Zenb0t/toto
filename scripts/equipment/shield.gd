class_name Shield
extends Utility
## Blocks every hit (your own blasts included) for a moment. Aiming doesn't matter.

var duration := 1.2


func _init() -> void:
	id = "shield"
	display_name = "Shield"
	description = "Blocks all damage for a moment."
	button_label = "SHIELD"
	color = Color(0.7, 0.6, 1.0)
	cooldown = 5.0


func knobs() -> Array[Knob]:
	var result: Array[Knob] = [Knob.new("duration", "Shield time (s)", 0.2, 4.0, 0.1)]
	result.append_array(super.knobs())
	return result


func activate(_direction: Vector2, _strength := 1.0) -> UtilityEffect:
	return UtilityEffect.shield(duration)
