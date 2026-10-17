class_name ArcWeapon
extends Weapon
## The archetype of weapons that sweep an arc in front of the player: the blade crosses the arc over a short
## time and hits everything it passes. Dagger, Sword and Battleaxe are arc weapons that differ only in their
## numbers (reach, arc, damage, speed), which each sets in its own _init.

var reach := 60.0
var arc_degrees := 90.0
var damage := 100
var sweep_seconds := 0.15


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("reach", "Reach", 30, 200, 5),
		Knob.new("arc_degrees", "Arc (deg)", 20, 360, 5),
		Knob.new("sweep_seconds", "Sweep (s)", 0.0, 0.6, 0.01),
		Knob.new("damage", "Damage", 10, 500, 10, true),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	var slash := Slash.new(origin, direction, reach, arc_degrees, damage, color)
	slash.sweep_seconds = sweep_seconds
	return [slash]


func aim_range() -> float:
	return reach


## Arc fighters rush in: they want to be well inside their reach.
func ideal_distance() -> float:
	return reach * 0.6


func aim_shape() -> AimShape:
	return AimShape.cone(reach, arc_degrees)
