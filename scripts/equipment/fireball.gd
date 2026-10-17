class_name Fireball
extends Weapon
## Lobbed like Barley's bottles in Brawl Stars: drag distance picks the landing spot, the fireball arcs over
## walls and enemies, and it explodes where it lands, hurting everything in the blast (the thrower included).

var shot_speed := 300.0
var shot_range := 280.0
var damage := 2
var blast_radius := 70.0


func _init() -> void:
	id = "fireball"
	display_name = "Fireball"
	description = "Lobbed over walls; explodes where it lands. Mind the blast."
	button_label = "FIREBALL"
	color = Color(1, 0.45, 0.2)
	cooldown = 1.4
	windup = 0.25


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("shot_speed", "Throw speed", 60, 800, 10),
		Knob.new("shot_range", "Max range", 100, 1000, 10),
		Knob.new("damage", "Damage", 1, 5, 1),
		Knob.new("blast_radius", "Blast radius", 20, 200, 5),
	])
	return result


## Lands exactly where aimed, never farther than the max range.
func attacks(origin: Vector2, direction: Vector2, aim_distance: float) -> Array:
	var shot := Shot.new(origin, direction, shot_speed, damage, clampf(aim_distance, 0.0, shot_range))
	shot.lobbed = true
	shot.blast_radius = blast_radius
	shot.size = 9.0
	shot.color = color
	return [shot]


func aim_range() -> float:
	return shot_range


## Lobbed over walls and pillars, so it doesn't need to see its target.
func needs_line_of_sight() -> bool:
	return false


## Lobs from afar, out of reach of its own blast.
func ideal_distance() -> float:
	return aim_range() * 0.75


func aim_shape() -> AimShape:
	return AimShape.lob(shot_range, blast_radius)
