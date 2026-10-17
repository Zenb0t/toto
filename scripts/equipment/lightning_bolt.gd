class_name LightningBolt
extends Weapon
## Dungeon Crawl's Lightning Bolt, shot like Jessie's in Brawl Stars: a fast bolt that, when it hits an enemy,
## jumps on to the nearest other enemy close by, and again from there (up to MAX_CHAINS times), so it rewards
## fighting packs. The first enemy takes the most; each jump keeps only a share of the damage (see ChainFalloff).

## Most jumps it can ever make, so tuning can't turn it into a screen-wide killer: 4 enemies in all.
const MAX_CHAINS := 3

var shot_speed := 620.0
var shot_range := 480.0
## What the first enemy hit takes.
var damage := 180
## How many times it jumps on from an enemy it hit, and how far it can jump.
var chains := MAX_CHAINS
var chain_range := 160.0
## The share of damage kept at each jump: 180, 117, 76, 49 at 0.65.
var chain_falloff := 0.65


func _init() -> void:
	id = "lightning_bolt"
	display_name = "Lightning Bolt"
	description = "Jumps from the enemy it hits to the next one nearby, up to three times, weaker each jump."
	button_label = "LIGHTNING"
	color = Color(0.75, 0.85, 1.0)
	reload = 1.65
	windup = 0.15


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("shot_speed", "Shot speed", 200, 1500, 10),
		Knob.new("shot_range", "Range", 100, 1200, 10),
		Knob.new("damage", "First hit damage", 10, 500, 10, true),
		Knob.new("chain_falloff", "Damage kept per jump", 0.3, 1.0, 0.05),
		Knob.new("chains", "Jumps", 0, MAX_CHAINS, 1),
		Knob.new("chain_range", "Jump range", 40, 400, 10),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	var shot := Shot.new(Weapon.muzzle(origin, direction), direction, shot_speed, damage, shot_range)
	shot.chains = mini(chains, MAX_CHAINS)
	shot.chain_falloff = chain_falloff
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
