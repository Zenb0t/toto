class_name Band
extends RefCounted
## The monsters of one home start the same way: asleep there, or awake and wandering slowly about it. In the
## dungeon a home is a room. Which bands wander comes from the map's seed, so the same map starts the same way.
## Once one of them notices the hero the rest join it (see Awareness); fighting, they take turns as a Squad.

enum Start { ASLEEP, WANDERING }

## The share of bands that start wandering; the rest sleep.
const DEFAULT_WANDERING_SHARE := 0.25
## How far from home, in cells, a wandering monster strolls.
const DEFAULT_WANDER_RADIUS_CELLS := 6.0


## How the band living at a home starts, on the map with this seed.
static func start_of(map_seed: int, home: int, wandering_share := DEFAULT_WANDERING_SHARE) -> Start:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map_seed, home])
	return Start.WANDERING if rng.randf() < wandering_share else Start.ASLEEP
