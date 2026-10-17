class_name LightningBolt
extends Weapon
## Dungeon Crawl's Lightning Bolt, shot like Jessie's in Brawl Stars: a fast bolt that, when it hits an enemy,
## jumps on to the nearest other enemy close by, and again from there, so it rewards fighting packs.

var shot_speed := 620.0
var shot_range := 480.0
var damage := 100
## How many times it jumps on from an enemy it hit, and how far it can jump.
var chains := 2
var chain_range := 160.0


func _init() -> void:
	id = "lightning_bolt"
	display_name = "Lightning Bolt"
	description = "Jumps from the enemy it hits to the next one nearby, twice."
	button_label = "LIGHTNING"
	color = Color(0.75, 0.85, 1.0)
	reload = 1.65
	windup = 0.15


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("shot_speed", "Shot speed", 200, 1500, 10),
		Knob.new("shot_range", "Range", 100, 1200, 10),
		Knob.new("damage", "Damage", 10, 500, 10, true),
		Knob.new("chains", "Jumps", 0, 5, 1),
		Knob.new("chain_range", "Jump range", 40, 400, 10),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	var shot := Shot.new(Weapon.muzzle(origin, direction), direction, shot_speed, damage, shot_range)
	shot.chains = chains
	shot.chain_range = chain_range
	shot.size = 4.0
	shot.color = color
	return [shot]


func travel_seconds(distance: float) -> float:
	return distance / shot_speed


func aim_range() -> float:
	return shot_range


func aim_shape() -> AimShape:
	return AimShape.line(shot_range)
