class_name Weapon
extends RefCounted
## What the attack button does. Weapons are plain data: the player decides *when* to attack
## (cooldown, wind-up, aim), the weapon decides *what* the attack is.
## Subclasses add their own fields and expose the ones worth tuning through knobs().

## Projectiles start just past the player's facing tick, in front of the body rather than inside it.
const MUZZLE_DISTANCE := 18.0

## Stable identifier: used in saved settings and tuning keys, so never rename one.
var id := ""
var display_name := ""
## One line shown when the weapon is found, so the player can compare it with what they hold.
var description := ""
var button_label := ""
var color := Color.WHITE
## Seconds between attacks.
var cooldown := 0.8
## Seconds between releasing the button and the attack happening, so attacks feel deliberate.
var windup := 0.1


## The fields the Tune screen may change.
func knobs() -> Array[Knob]:
	return [
		Knob.new("cooldown", "Cooldown (s)", 0.1, 3.0, 0.05),
		Knob.new("windup", "Wind-up (s)", 0.0, 1.0, 0.01),
	]


## The Shots and Slashes one attack produces, from the attacker's centre toward the aim.
## aim_distance is how far away the player aimed (weapons that target a spot use it; others ignore it).
func attacks(_origin: Vector2, _direction: Vector2, _aim_distance: float) -> Array:
	return []


## The farthest this weapon reaches: a full-strength drag aims this far.
func aim_range() -> float:
	return 0.0


## How far away a manual drag of the given strength (0..1) aims. Linear unless a weapon needs finer control.
func aim_distance(strength: float) -> float:
	return clampf(strength, 0.0, 1.0) * aim_range()


func aim_shape() -> AimShape:
	return AimShape.line(0.0)


static func muzzle(origin: Vector2, direction: Vector2) -> Vector2:
	return origin + direction.normalized() * MUZZLE_DISTANCE
