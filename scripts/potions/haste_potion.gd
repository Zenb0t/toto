class_name HastePotion
extends Potion
## Moves faster for a while: for getting out of trouble, or reaching a caster before it throws again.

var speed_multiplier := 1.5
var duration := 6.0


func _init() -> void:
	id = "haste"
	display_name = "Potion of Haste"
	description = "Move much faster for a while."
	button_label = "HASTE"
	color = Color(0.4, 0.9, 1.0)


func knobs() -> Array[Knob]:
	return [
		Knob.new("speed_multiplier", "Speed (x)", 1.1, 3.0, 0.05),
		Knob.new("duration", "Duration (s)", 1.0, 20.0, 0.5),
	]


func effect() -> UtilityEffect:
	return UtilityEffect.haste(speed_multiplier, duration)
