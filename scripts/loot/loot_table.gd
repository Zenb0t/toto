class_name LootTable
extends RefCounted
## What loot drops. Pure: the caller passes the random number generator, so results can be reproduced.

## Chance a defeated enemy leaves gear. Rare, so new gear is a moment.
const DEFAULT_ENEMY_DROP_CHANCE := 0.02
## Chance a defeated enemy leaves a potion (rolled when it drops no item).
const DEFAULT_POTION_DROP_CHANCE := 0.1
## Chance a chest holds a potion as well as its item.
const DEFAULT_CHEST_POTION_CHANCE := 0.3
## Share of the items lying on the floor from the start that are potions.
const FLOOR_POTION_SHARE := 0.5


## Something found: a potion, or gear (a weapon or a utility).
class Find:
	extends RefCounted
	var item_id: String
	var is_potion: bool

	func _init(found_id: String, potion: bool) -> void:
		item_id = found_id
		is_potion = potion


## What lies on a map's loot cell from the start: a potion or a piece of gear, rolled from the map's seed and
## the cell alone, so the same map always holds the same finds, whatever the hero carries when they come.
static func floor_find(
		map_seed: int, loot_cell: Vector2i, item_ids: Array[String], potion_weights: Dictionary
) -> Find:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%d/loot/%d,%d" % [map_seed, loot_cell.x, loot_cell.y]).hash()
	if rolls(FLOOR_POTION_SHARE, rng):
		return Find.new(pick_potion_id(potion_weights, rng), true)
	var nothing_held: Array[String] = []
	return Find.new(pick_item_id(item_ids, nothing_held, rng), false)


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
