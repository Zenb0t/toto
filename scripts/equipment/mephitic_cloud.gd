class_name MephiticCloud
extends Weapon
## Dungeon Crawl's Mephitic Cloud, thrown like Emz's spray zones: lobbed over walls like the fireball, it
## leaves a poison cloud that keeps hurting enemies inside it for a while. Doesn't hurt the thrower.

var shot_speed := 320.0
var shot_range := 380.0
var damage := 1
var cloud_radius := 75.0
var cloud_seconds := 3.0
## Above 1, short drags land closer to the player (see Fireball).
var aim_curve := 2.0


func _init() -> void:
	id = "mephitic_cloud"
	display_name = "Mephitic Cloud"
	description = "Lobbed; leaves a poison cloud that hurts enemies inside it."
	button_label = "CLOUD"
	color = Color(0.55, 0.85, 0.3)
	cooldown = 1.8
	windup = 0.2


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("shot_range", "Max range", 100, 1000, 10),
		Knob.new("damage", "Damage per tick", 1, 3, 1),
		Knob.new("cloud_radius", "Cloud radius", 20, 200, 5),
		Knob.new("cloud_seconds", "Cloud time (s)", 0.5, 8.0, 0.1),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, aim_distance: float) -> Array:
	var shot := Shot.new(origin, direction, shot_speed, damage, clampf(aim_distance, 0.0, shot_range))
	shot.lobbed = true
	shot.cloud_seconds = cloud_seconds
	shot.cloud_radius = cloud_radius
	shot.size = 8.0
	shot.color = color
	return [shot]


func aim_range() -> float:
	return shot_range


func aim_distance(strength: float) -> float:
	return shot_range * pow(clampf(strength, 0.0, 1.0), aim_curve)


func strength_for_distance(distance: float) -> float:
	return pow(clampf(distance / shot_range, 0.0, 1.0), 1.0 / aim_curve)


func needs_line_of_sight() -> bool:
	return false


func ideal_distance() -> float:
	return aim_range() * 0.7


func aim_shape() -> AimShape:
	return AimShape.lob(shot_range, cloud_radius)
