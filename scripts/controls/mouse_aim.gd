class_name MouseAim
extends RefCounted
## Aiming with a mouse: the attack goes toward the cursor, and items that target a spot (like a lobbed
## fireball or a blink) land on it, as far as they reach. Gives the same Release a touch drag does.


## from: the attacker; cursor: where the mouse points, on the game plane. fallback: the direction to use when
## the cursor is right on the attacker.
static func toward(from: Vector2, cursor: Vector2, item: Item, fallback: Vector2) -> AimGesture.Release:
	var strength := item.strength_for_distance(from.distance_to(cursor))
	return AimGesture.Release.new(false, direction(from, cursor, fallback), strength)


## Which way the cursor is from the attacker, for things that only need a direction (a dash, a blink).
static func direction(from: Vector2, cursor: Vector2, fallback: Vector2) -> Vector2:
	var offset := cursor - from
	return offset.normalized() if not offset.is_zero_approx() else fallback.normalized()
