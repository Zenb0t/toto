class_name LootTable
extends RefCounted
## What loot drops. Pure: the caller passes the random number generator, so results can be reproduced.

const DEFAULT_ENEMY_DROP_CHANCE := 0.1


## A random weapon id from the candidates, never the one the player already holds (a duplicate
## offers no choice). Falls back to the held one only when there is nothing else to offer.
static func pick_weapon_id(candidates: Array[String], held_id: String, rng: RandomNumberGenerator) -> String:
	var others := candidates.filter(func(id: String) -> bool: return id != held_id)
	if others.is_empty():
		return held_id
	return others[rng.randi_range(0, others.size() - 1)]


## True when a defeated enemy should drop a weapon. chance is 0..1.
static func rolls_enemy_drop(chance: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < chance
