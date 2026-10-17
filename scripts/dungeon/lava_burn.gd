class_name LavaBurn
extends RefCounted
## How much lava hurts whoever stands in it: a burn the moment they step in, then another every
## BURN_INTERVAL while they stay. Stepping out resets it. Knows no nodes: the caller says who is where.

const DAMAGE := 100
const BURN_INTERVAL := 0.5

var _time_in_lava := {}  # actor key -> seconds since the last burn


## Damage due this step for the actor identified by key (0 when nothing is due).
func damage_due(key: Variant, in_lava: bool, delta: float) -> int:
	if not in_lava:
		_time_in_lava.erase(key)
		return 0
	if not _time_in_lava.has(key):
		_time_in_lava[key] = 0.0
		return DAMAGE
	_time_in_lava[key] += delta
	if _time_in_lava[key] < BURN_INTERVAL:
		return 0
	_time_in_lava[key] -= BURN_INTERVAL
	return DAMAGE
