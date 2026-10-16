class_name Crossbow
extends Weapon
## Fires a fan of bolts at once: strong up close, where several bolts land on the same target.

var bolts := 3
var spread_degrees := 30.0
var shot_speed := 480.0
var shot_range := 380.0
var damage := 1


func _init() -> void:
	id = "crossbow"
	display_name = "Crossbow"
	description = "A fan of bolts, strongest up close."
	button_label = "CROSSBOW"
	color = Color(0.55, 0.85, 0.4)
	cooldown = 1.0
	windup = 0.15


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("bolts", "Bolts", 1, 9, 1),
		Knob.new("spread_degrees", "Spread (deg)", 0, 120, 5),
		Knob.new("shot_speed", "Shot speed", 100, 1200, 10),
		Knob.new("shot_range", "Range", 100, 1000, 10),
		Knob.new("damage", "Damage", 1, 5, 1),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	var shots: Array = []
	for angle in Spread.angles_degrees(bolts, spread_degrees):
		var bolt_direction := direction.normalized().rotated(deg_to_rad(angle))
		var shot := Shot.new(Weapon.muzzle(origin, bolt_direction), bolt_direction, shot_speed, damage, shot_range)
		shot.size = 4.0
		shot.color = color
		shots.append(shot)
	return shots


func aim_range() -> float:
	return shot_range


## Strongest up close, where several bolts land on the same target.
func ideal_distance() -> float:
	return aim_range() * 0.35


func aim_shape() -> AimShape:
	return AimShape.fan(shot_range, spread_degrees, bolts)
