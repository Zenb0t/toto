class_name Fireball
extends Weapon
## A slow projectile that explodes on impact, or when it runs out of range, hurting everything in the blast.

var shot_speed := 220.0
var shot_range := 450.0
var damage := 2
var blast_radius := 70.0


func _init() -> void:
	id = "fireball"
	display_name = "Fireball"
	button_label = "FIREBALL"
	color = Color(1, 0.45, 0.2)
	cooldown = 1.4
	windup = 0.25


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("shot_speed", "Shot speed", 60, 800, 10),
		Knob.new("shot_range", "Range", 100, 1000, 10),
		Knob.new("damage", "Damage", 1, 5, 1),
		Knob.new("blast_radius", "Blast radius", 20, 200, 5),
	])
	return result


func attacks(origin: Vector2, direction: Vector2) -> Array:
	var shot := Shot.new(Weapon.muzzle(origin, direction), direction, shot_speed, damage, shot_range)
	shot.blast_radius = blast_radius
	shot.size = 9.0
	shot.color = color
	return [shot]


func aim_shape() -> AimShape:
	return AimShape.line(shot_range, blast_radius)
