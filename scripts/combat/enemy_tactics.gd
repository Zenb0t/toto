class_name EnemyTactics
extends RefCounted
## How an armed enemy fights, as pure decisions: where to move, when to attack and where to aim.
## Each weapon says how far from its target it likes to be (Weapon.ideal_distance), so a sword fighter
## rushes in, a crossbow gets close, a wand keeps to mid range and a fireball thrower hangs back.

## Inside the comfortable band around the ideal distance, enemies circle their target at this share of
## their speed instead of standing still, so they are harder to hit.
const STRAFE_SPEED := 0.5
## Attacks start a little inside the weapon's full range, so they don't fall just short.
const ATTACK_RANGE_SHARE := 0.9
## How much of a moving target's travel enemies aim ahead of it (0 = where it is, 1 = where it will be).
const DEFAULT_LEAD_SHARE := 0.6


## Unit-or-shorter direction to move in. to_target points from the enemy to its target.
## slack is how far from the ideal distance (and from its flank spot) still counts as "right where I want
## to be". strafe_sign (+1 or -1) picks which way it circles.
## flank_gap is how far round the target its flank spot is, in radians: positive is the way a positive
## strafe_sign circles. Further than slack from it, the enemy circles toward it while keeping its distance.
static func move_direction(
		to_target: Vector2, ideal_distance: float, slack: float, strafe_sign: float, flank_gap := 0.0) -> Vector2:
	var distance := to_target.length()
	if is_zero_approx(distance):
		return Vector2.ZERO
	var toward := to_target / distance
	var circling := toward.orthogonal()
	var closing := 0.0
	if distance > ideal_distance + slack:
		closing = 1.0
	elif distance < ideal_distance - slack:
		closing = -1.0
	var arc_to_spot := flank_gap * distance
	var around := 0.0 if absf(arc_to_spot) <= slack else signf(arc_to_spot)
	if closing == 0.0 and around == 0.0:
		return circling * signf(strafe_sign) * STRAFE_SPEED
	return (toward * closing + circling * around).normalized()


## True when the target's edge is within the weapon's reach.
static func can_attack(distance: float, target_radius: float, attack_range: float) -> bool:
	return distance - target_radius <= attack_range * ATTACK_RANGE_SHARE


## Where to aim at a moving target: lead_share of the way to where it will be after `seconds` (the wind-up
## plus the shot's flight), if it keeps going. to_target points from the enemy to the target.
static func lead(to_target: Vector2, target_velocity: Vector2, seconds: float, lead_share: float) -> Vector2:
	return to_target + target_velocity * seconds * lead_share
