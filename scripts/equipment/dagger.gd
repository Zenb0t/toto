class_name Dagger
extends ArcWeapon
## The starter weapon: a quick jab. Shorter, narrower and weaker than the sword, but it reloads faster.
## Two stabs kill a goblin, so the first fights are winnable, and found weapons are still worth finding.


func _init() -> void:
	id = "dagger"
	display_name = "Dagger"
	description = "A quick, short stab in front of you."
	button_label = "DAGGER"
	color = Color(0.8, 0.85, 0.9)
	reload = 0.6
	windup = 0.08
	reach = 55.0
	arc_degrees = 70.0
	damage = 100
	sweep_seconds = 0.1
