class_name LootTable
extends RefCounted
## What loot drops. Pure: the caller passes the random number generator, so results can be reproduced.

const DEFAULT_ENEMY_DROP_CHANCE := 0.05
## Chance a defeated enemy leaves a potion (rolled when it drops no item).
const DEFAULT_POTION_DROP_CHANCE := 0.1
## Chance a chest holds a potion as well as its item.
const DEFAULT_CHEST_POTION_CHANCE := 0.3
## Share of the items lying on the floor from the start that are potions.
const FLOOR_POTION_SHARE := 0.5


## A random item id from the candidates, never one the player already holds (a duplicate offers no
## choice). Falls back to any candidate only when the player holds them all.
static func pick_item_id(candidates: Array[String], held_ids: Array[String], rng: RandomNumberGenerator) -> String:
	var others := candidates.filter(func(id: String) -> bool: return id not in held_ids)
	var pool := others if not others.is_empty() else candidates
	return pool[rng.randi_range(0, pool.size() - 1)]


## A defeated enemy drops the weapon it fought with, so the player can see what they are getting, unless
## the player already holds it: then it is a random find.
static func enemy_drop_id(
		enemy_weapon_id: String, candidates: Array[String], held_ids: Array[String], rng: RandomNumberGenerator
) -> String:
	if enemy_weapon_id not in held_ids:
		return enemy_weapon_id
	return pick_item_id(candidates, held_ids, rng)


## True when a defeated enemy should drop something. chance is 0..1.
static func rolls_enemy_drop(chance: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < chance


## True with the given chance (0..1).
static func rolls(chance: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < chance


## A random potion id, each as likely as its weight (id -> weight, above zero).
static func pick_potion_id(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for id: String in weights:
		total += weights[id]
	var roll := rng.randi_range(1, total)
	for id: String in weights:
		roll -= weights[id]
		if roll <= 0:
			return id
	return weights.keys()[0]
