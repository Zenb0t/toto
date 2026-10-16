class_name EnemyTactics
extends RefCounted
## How an armed enemy fights, as pure decisions: where to move and when to attack.
## Each weapon says how far from its target it likes to be (Weapon.ideal_distance), so a sword fighter
## rushes in, a crossbow gets close, a wand keeps to mid range and a fireball thrower hangs back.

## Inside the comfortable band around the ideal distance, enemies circle their target at this share of
## their speed instead of standing still, so they are harder to hit.
const STRAFE_SPEED := 0.5
## Attacks start a little inside the weapon's full range, so they don't fall just short.
const ATTACK_RANGE_SHARE := 0.9


## Unit-or-shorter direction to move in. to_target points from the enemy to its target.
## slack is how far from the ideal distance still counts as "right where I want to be".
## strafe_sign (+1 or -1) picks which way it circles.
static func move_direction(to_target: Vector2, ideal_distance: float, slack: float, strafe_sign: float) -> Vector2:
	var distance := to_target.length()
	if is_zero_approx(distance):
		return Vector2.ZERO
	var toward := to_target / distance
	if distance > ideal_distance + slack:
		return toward
	if distance < ideal_distance - slack:
		return -toward
	return toward.orthogonal() * signf(strafe_sign) * STRAFE_SPEED


## True when the target's edge is within the weapon's reach.
static func can_attack(distance: float, target_radius: float, attack_range: float) -> bool:
	return distance - target_radius <= attack_range * ATTACK_RANGE_SHARE
