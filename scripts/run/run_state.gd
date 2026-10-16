class_name RunState
extends RefCounted
## What a run carries from one floor down to the next, like a Dungeon Crawl character taking the stairs:
## the floor reached, the gear held, health and potions. Each floor itself is new.
## Pure data, plus one explicit hand-over: the game reloads its scene for every floor, so the state for the
## next floor is carried across with carry() and picked up with take_carried().

const FLOOR_COUNT := 5
## Every run starts with these (potion id -> count).
const STARTING_POTIONS := {"healing": 1}

static var _carried: RunState

## 1 is the top floor; FLOOR_COUNT is the bottom, whose stairs lead out.
var floor_number := 1
var weapon_id := GameTuning.DEFAULT_WEAPON_ID
var utility_id := GameTuning.DEFAULT_UTILITY_ID
var health := Player.MAX_HEALTH
var max_health := Player.MAX_HEALTH
var potions := STARTING_POTIONS.duplicate()


## Leaves state for the next scene to pick up.
static func carry(state: RunState) -> void:
	_carried = state


## The state carried from the floor above, or a new run if nothing was carried. Either way, nothing is
## carried any more afterwards, so dying or restarting always starts over.
static func take_carried() -> RunState:
	var state := _carried if _carried != null else RunState.new()
	_carried = null
	return state


## Whether this floor's stairs lead out of the dungeon (the run is won) rather than down.
func is_last_floor() -> bool:
	return floor_number >= FLOOR_COUNT


## The state for the floor below, carrying what the player holds now.
func next_floor(
		held_weapon_id: String, held_utility_id: String, current_health: int, held_potions: Dictionary
) -> RunState:
	var next := RunState.new()
	next.floor_number = floor_number + 1
	next.weapon_id = held_weapon_id
	next.utility_id = held_utility_id
	next.health = current_health
	next.max_health = max_health
	next.potions = held_potions.duplicate()
	return next
