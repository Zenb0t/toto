class_name Sword
extends Weapon
## A melee sweep in front of the player: the blade crosses the arc over a short time and hits
## everything it passes.

var reach := 70.0
var arc_degrees := 110.0
var damage := 2
var sweep_seconds := 0.15


func _init() -> void:
	id = "sword"
	display_name = "Sword"
	button_label = "SWORD"
	color = Color(0.85, 0.88, 1.0)
	cooldown = 0.6
	windup = 0.12


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("reach", "Reach", 30, 200, 5),
		Knob.new("arc_degrees", "Arc (deg)", 20, 360, 5),
		Knob.new("sweep_seconds", "Sweep (s)", 0.0, 0.6, 0.01),
		Knob.new("damage", "Damage", 1, 5, 1),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	var slash := Slash.new(origin, direction, reach, arc_degrees, damage, color)
	slash.sweep_seconds = sweep_seconds
	return [slash]


func aim_range() -> float:
	return reach


func aim_shape() -> AimShape:
	return AimShape.cone(reach, arc_degrees)
