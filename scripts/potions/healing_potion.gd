class_name HealingPotion
extends Potion
## Restores some health at once. The only way to heal: the Heal utility it replaced was too strong.

var amount := 4


func _init() -> void:
	id = "healing"
	display_name = "Potion of Healing"
	description = "Restores some health."
	button_label = "HEAL"
	color = Color(0.95, 0.35, 0.45)
	frequency = 3


func knobs() -> Array[Knob]:
	return [Knob.new("amount", "Health restored", 1, 10, 1)]


func effect() -> UtilityEffect:
	return UtilityEffect.heal(amount)
