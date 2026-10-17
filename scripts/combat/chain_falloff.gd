class_name ChainFalloff
extends RefCounted
## How hard a chaining shot (Lightning Bolt) hits at each stop: the first foe takes the full damage and every jump
## keeps only a share of what the one before did, so 180 at 0.65 per jump goes 180, 117, 76, 49.


## Damage dealt to the foe hit after `jumps` jumps (0 = the first foe). `kept` is the share kept per jump (0..1).
static func damage_after(first_hit: int, kept: float, jumps: int) -> int:
	return roundi(first_hit * pow(kept, maxi(jumps, 0)))
