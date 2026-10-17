class_name MephiticCloud
extends Weapon
## Dungeon Crawl's Mephitic Cloud, thrown like Emz's spray zones: lobbed over walls like the fireball, it
## leaves a poison cloud that keeps hurting enemies inside it for a while. Doesn't hurt the thrower.
## An enemy that stays in the cloud takes damage per tick x ticks (first at first_tick_delay, then one every
## PoisonCloud.TICK_SECONDS until the cloud ends): ticks at 0.6, 1.2 ... 6.0 s = 10 x 50 = 500. Change a knob and the
## total changes with it. Damage only comes from standing in the cloud; leaving it leaves nothing behind.

var shot_speed := 320.0
var shot_range := 380.0
var damage := 50
var cloud_radius := 75.0
var cloud_seconds := 6.0
## Grace window after landing before the first tick; also applies to the clouds enemy casters throw at the player.
var first_tick_delay := 0.6


func _init() -> void:
	id = "mephitic_cloud"
	display_name = "Mephitic Cloud"
	description = "Lobbed; leaves a poison cloud that hurts enemies inside it."
	button_label = "CLOUD"
	color = Color(0.55, 0.85, 0.3)
	reload = 2.7
	windup = 0.2


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("shot_range", "Max range", 100, 1000, 10),
		Knob.new("damage", "Damage per tick", 10, 300, 10, true),
		Knob.new("cloud_radius", "Cloud radius", 20, 200, 5),
		Knob.new("cloud_seconds", "Cloud time (s)", 0.5, 8.0, 0.1),
		Knob.new("first_tick_delay", "First tick delay (s)", 0.0, 3.0, 0.1),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, aim_distance: float) -> Array:
	var shot := Shot.new(origin, direction, shot_speed, damage, clampf(aim_distance, 0.0, shot_range))
	shot.lobbed = true
	shot.cloud_seconds = cloud_seconds
	shot.cloud_radius = cloud_radius
	shot.first_tick_delay = first_tick_delay
	shot.size = 8.0
	shot.color = color
	return [shot]


func travel_seconds(distance: float) -> float:
	return distance / shot_speed


func aim_range() -> float:
	return shot_range


func needs_line_of_sight() -> bool:
	return false


func ideal_distance() -> float:
	return aim_range() * 0.7


func aim_shape() -> AimShape:
	return AimShape.lob(shot_range, cloud_radius)
