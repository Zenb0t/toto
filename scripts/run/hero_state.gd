class_name HeroState
extends RefCounted
## What the hero carries from one map to the next, like a Dungeon Crawl character taking the stairs: the gear
## held, health, potions, experience and the monsters slain so far. Pure data; the maps themselves are not in it.

## Every run starts with these (potion id -> count).
const STARTING_POTIONS := {"healing": 1}

var weapon_id := GameTuning.DEFAULT_WEAPON_ID
var utility_id := GameTuning.DEFAULT_UTILITY_ID
var health := Player.MAX_HEALTH
var max_health := Player.MAX_HEALTH
var potions := STARTING_POTIONS.duplicate()
var experience := 0
## Monsters slain on every map so far, counted as the run goes.
var kills := 0


## The hero as they are now, ready to take onto another map.
static func carrying(
		held_weapon_id: String, held_utility_id: String, hero_health: Health, held_potions: Dictionary,
		experience_points: int, monsters_slain: int
) -> HeroState:
	var hero := HeroState.new()
	hero.weapon_id = held_weapon_id
	hero.utility_id = held_utility_id
	hero.health = hero_health.current
	hero.max_health = hero_health.maximum
	hero.potions = held_potions.duplicate()
	hero.experience = experience_points
	hero.kills = monsters_slain
	return hero
