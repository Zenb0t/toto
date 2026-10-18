class_name Run
extends RefCounted
## The run-level owner: lives for the whole run and holds the world seed, what the hero carries (HeroState) and
## which map is current. It applies the transition rule (WorldLayout) when the hero takes an exit; the game
## then builds the map it names. Pure; a new run is a new Run.

var world_seed: int
## The hero as they arrived on the current map (kills are counted as they happen).
var hero := HeroState.new()
var current_map_id := WorldLayout.start_map_id()


func _init(seed_value: int) -> void:
	world_seed = seed_value


## A new world with a seed drawn from rng.
static func random(rng: RandomNumberGenerator) -> Run:
	return Run.new(rng.randi())


## The run after this one (dying, or restarting): a new world with a different seed and a fresh hero.
func next_world(rng: RandomNumberGenerator) -> Run:
	var seed_value := rng.randi()
	while seed_value == world_seed:
		seed_value = rng.randi()
	return Run.new(seed_value)


func current_map() -> MapSpec:
	return WorldLayout.spec(world_seed, current_map_id)


## Where an exit from the current map leads (see WorldLayout.destination).
func destination(exit: WorldLayout.Exit) -> WorldLayout.Destination:
	return WorldLayout.destination(current_map_id, exit)


## Takes an exit with the hero as they are now. The current map becomes the one the exit leads to, unless it
## leads out of the world.
func travel(exit: WorldLayout.Exit, carried: HeroState) -> WorldLayout.Destination:
	hero = carried
	var leads_to := destination(exit)
	if not leads_to.leaves_world():
		current_map_id = leads_to.map_id
	return leads_to
