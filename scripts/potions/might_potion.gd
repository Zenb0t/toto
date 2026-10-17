class_name MightPotion
extends Potion
## Hits harder for a while: every attack does extra damage.

var bonus_damage := 1
var duration := 8.0


func _init() -> void:
	id = "might"
	display_name = "Potion of Might"
	description = "Your attacks hit harder for a while."
	button_label = "MIGHT"
	color = Color(1.0, 0.55, 0.2)


func knobs() -> Array[Knob]:
	return [
		Knob.new("bonus_damage", "Extra damage", 1, 5, 1),
		Knob.new("duration", "Duration (s)", 1.0, 20.0, 0.5),
	]


func effect() -> UtilityEffect:
	return UtilityEffect.might(bonus_damage, duration)
