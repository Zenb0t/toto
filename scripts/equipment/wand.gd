class_name Wand
extends Weapon
## The starter weapon: a single magic bolt.

var shot_speed := 360.0
var shot_range := 420.0
var shot_damage := 1


func _init() -> void:
	id = "wand"
	display_name = "Wand"
	description = "One magic bolt."
	button_label = "WAND"
	color = Color(1, 0.8, 0.3)
	cooldown = 0.8
	windup = 0.1


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("shot_speed", "Shot speed", 100, 1200, 10),
		Knob.new("shot_range", "Range", 100, 1000, 10),
		Knob.new("shot_damage", "Damage", 1, 5, 1),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	return [Shot.new(Weapon.muzzle(origin, direction), direction, shot_speed, shot_damage, shot_range)]


func aim_range() -> float:
	return shot_range


func aim_shape() -> AimShape:
	return AimShape.line(shot_range)
