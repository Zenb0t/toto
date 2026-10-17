class_name Sword
extends ArcWeapon
## A blade that sweeps a wide arc in front of the player.


func _init() -> void:
	id = "sword"
	display_name = "Sword"
	description = "The blade sweeps an arc in front of you."
	button_label = "SWORD"
	color = Color(0.85, 0.88, 1.0)
	reload = 0.9
	windup = 0.12
	reach = 70.0
	arc_degrees = 110.0
	damage = 200
	sweep_seconds = 0.15
