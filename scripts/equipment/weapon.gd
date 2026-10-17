class_name Weapon
extends Item
## What the attack button does. Whoever wields it (the player or an enemy) decides *when* to attack
## (cooldown, wind-up, aim); the weapon decides *what* the attack is.

## Projectiles start just past the player's facing tick, in front of the body rather than inside it.
const MUZZLE_DISTANCE := 18.0

## Seconds between releasing the button and the attack happening, so attacks feel deliberate.
var windup := 0.1
## Brawl Stars style ammo: how many attacks in a row, and the seconds to reload each one.
var ammo := 3
var reload := 1.2
## The short wait between two attacks, even with ammo left.
var attack_interval := 0.3


## The fields the Tune screen may change.
func knobs() -> Array[Knob]:
	return [
		Knob.new("ammo", "Ammo", 1, 6, 1),
		Knob.new("reload", "Reload (s per ammo)", 0.2, 5.0, 0.05),
		Knob.new("attack_interval", "Between attacks (s)", 0.05, 2.0, 0.05),
		Knob.new("windup", "Wind-up (s)", 0.0, 1.0, 0.01),
	]


## The Shots and Slashes one attack produces, from the attacker's centre toward the aim.
## aim_distance is how far away the player aimed (weapons that target a spot use it; others ignore it).
func attacks(_origin: Vector2, _direction: Vector2, _aim_distance: float) -> Array:
	return []


## How far from its target an enemy wielding this weapon likes to stay. Most keep to the middle of
## their range; weapons that are best up close (or from afar) say so.
func ideal_distance() -> float:
	return aim_range() * 0.6


## Whether an attack needs a clear line to its target. Lobbed weapons fly over walls.
func needs_line_of_sight() -> bool:
	return true


## aim_range() is the farthest this weapon reaches: a full-strength drag aims this far.
## How far away a manual drag of the given strength (0..1) aims. Linear unless a weapon needs finer control.
func aim_distance(strength: float) -> float:
	return clampf(strength, 0.0, 1.0) * aim_range()


## The strength (0..1) that aims this far away: the reverse of aim_distance(), for aiming at a spot (a mouse
## cursor) rather than with a drag. Beyond the weapon's reach it is full strength.
func strength_for_distance(distance: float) -> float:
	return clampf(distance / aim_range(), 0.0, 1.0) if aim_range() > 0.0 else 1.0


static func muzzle(origin: Vector2, direction: Vector2) -> Vector2:
	return origin + direction.normalized() * MUZZLE_DISTANCE
