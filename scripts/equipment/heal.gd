class_name Heal
extends Utility
## Restores some health on a long cooldown. Aiming doesn't matter.

var amount := 3


func _init() -> void:
	id = "heal"
	display_name = "Heal"
	description = "Restores some health. Slow to recharge."
	button_label = "HEAL"
	color = Color(0.5, 0.95, 0.55)
	cooldown = 10.0


func knobs() -> Array[Knob]:
	var result: Array[Knob] = [Knob.new("amount", "Health restored", 1, 10, 1)]
	result.append_array(super.knobs())
	return result


func activate(_direction: Vector2) -> UtilityEffect:
	return UtilityEffect.heal(amount)
