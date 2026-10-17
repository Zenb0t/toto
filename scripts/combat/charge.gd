class_name Charge
extends RefCounted
## The rule of a charged attack, like Angelo's bow in Brawl Stars: the longer the button is held, the stronger the
## attack, up to a full charge. Pure: the seconds held come from whoever watches the button.

## Held time of an attack that never charges (an enemy's): it counts as fully charged.
const FULL := INF


## How charged an attack is after held_seconds: 0 (a tap) to 1 (full). A weapon that needs no time to charge is
## always full.
static func ratio(held_seconds: float, full_seconds: float) -> float:
	if full_seconds <= 0.0:
		return 1.0
	return clampf(held_seconds / full_seconds, 0.0, 1.0)


static func is_full(held_seconds: float, full_seconds: float) -> bool:
	return ratio(held_seconds, full_seconds) >= 1.0


## Damage grows evenly from the minimum (a tap) to the maximum (a full charge), and never goes past it.
static func damage(held_seconds: float, full_seconds: float, min_damage: int, max_damage: int) -> int:
	return roundi(lerpf(min_damage, max_damage, ratio(held_seconds, full_seconds)))
