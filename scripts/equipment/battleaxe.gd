class_name Battleaxe
extends ArcWeapon
## A heavy two-handed axe, swung like Frank's hammer in Brawl Stars: a long wind-up, then a wide, crushing
## sweep. Slow to use, so timing it is everything.


func _init() -> void:
	id = "battleaxe"
	display_name = "Battleaxe"
	description = "A slow, wide and crushing swing."
	button_label = "AXE"
	color = Color(0.85, 0.6, 0.45)
	reload = 1.95
	windup = 0.35
	reach = 85.0
	arc_degrees = 180.0
	damage = 400
	sweep_seconds = 0.25
