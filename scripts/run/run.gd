class_name Run
extends RefCounted
## The run-level owner: lives for the whole run and holds the world seed, what the hero carries (HeroState),
## which map is current, where on it the hero arrives, one MapRecord per visited map and how long the run has
## been played. It applies the transition rule (WorldLayout) when the hero takes an exit; the game then builds
## the map it names and replays its record. Pure; a new run is a new Run.

var world_seed: int
## What the plains of this world are made of (Tune → World as it was when the world began).
var plains: QuadrantRecipe
## The hero as they arrived on the current map (kills are counted as they happen).
var hero := HeroState.new()
var current_map_id := WorldLayout.start_map_id()
## Where on the current map the hero appears.
var arrival_spot := WorldLayout.Spot.START
## Seconds of play since the run began (the game's clock: it stops while paused).
var seconds_played := 0.0
var _records := {}  # map id -> MapRecord


func _init(seed_value: int, plains_recipe := QuadrantRecipe.plains()) -> void:
	world_seed = seed_value
	plains = plains_recipe


## A new world with a seed drawn from rng.
static func random(rng: RandomNumberGenerator, plains_recipe := QuadrantRecipe.plains()) -> Run:
	return Run.new(rng.randi(), plains_recipe)


## The run after this one (dying, or restarting, or New world in the Tune screen): a new world with a different
## seed and a fresh hero. plains: what its plains are made of; the tuning may have changed since this world began.
func next_world(rng: RandomNumberGenerator, plains_recipe := plains) -> Run:
	var seed_value := rng.randi()
	while seed_value == world_seed:
		seed_value = rng.randi()
	return Run.new(seed_value, plains_recipe)


## The same world again from the start (Same seed again in the Tune screen): the same seed, a fresh hero and no
## memory of this run. plains: what its plains are made of, which the tuning may have changed.
func same_world_again(plains_recipe := plains) -> Run:
	return Run.new(world_seed, plains_recipe)


func current_map() -> MapSpec:
	return WorldLayout.spec(world_seed, current_map_id, plains)


## Moves the run's clock on.
func advance(seconds: float) -> void:
	seconds_played += seconds


## What the hero changed on a map so far (an empty record for a map not visited yet).
func record_of(map_id: String) -> MapRecord:
	if not _records.has(map_id):
		_records[map_id] = MapRecord.new(WorldLayout.spec(world_seed, map_id, plains).generator_version())
	return _records[map_id]


## Where an exit from the current map leads (see WorldLayout.destination).
func destination(exit: WorldLayout.Exit) -> WorldLayout.Destination:
	return WorldLayout.destination(current_map_id, exit)


## Takes an exit with the hero as they are now. The current map becomes the one the exit leads to, and the
## hero arrives on its matching spot, unless it leads out of the world.
func travel(exit: WorldLayout.Exit, carried: HeroState) -> WorldLayout.Destination:
	hero = carried
	var leads_to := destination(exit)
	if not leads_to.leaves_world():
		current_map_id = leads_to.map_id
		arrival_spot = leads_to.spot
	return leads_to
