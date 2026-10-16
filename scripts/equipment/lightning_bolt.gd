class_name LightningBolt
extends Weapon
## Dungeon Crawl's Lightning Bolt, shot like Rico's bullets in Brawl Stars: a fast bolt that passes
## through every enemy in its line and bounces off a wall, so it rewards lining foes up and banking shots.

var shot_speed := 620.0
var shot_range := 480.0
var damage := 1
var bounces := 1


func _init() -> void:
	id = "lightning_bolt"
	display_name = "Lightning Bolt"
	description = "Passes through every enemy in its line and bounces off walls."
	button_label = "LIGHTNING"
	color = Color(0.75, 0.85, 1.0)
	cooldown = 1.1
	windup = 0.15


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("shot_speed", "Shot speed", 200, 1500, 10),
		Knob.new("shot_range", "Range", 100, 1200, 10),
		Knob.new("damage", "Damage", 1, 5, 1),
		Knob.new("bounces", "Bounces", 0, 4, 1),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	var shot := Shot.new(Weapon.muzzle(origin, direction), direction, shot_speed, damage, shot_range)
	shot.pierces = true
	shot.bounces = bounces
	shot.size = 4.0
	shot.color = color
	return [shot]


func aim_range() -> float:
	return shot_range


func aim_shape() -> AimShape:
	return AimShape.line(shot_range)
