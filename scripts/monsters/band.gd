class_name Band
extends RefCounted
## The monsters of one home start the same way: asleep there, or awake and wandering slowly about it. In the
## dungeon a home is a room; on the plains it is the campfire a camp stands round (see Camps). Which bands wander comes from the map's seed, so the same map starts the same way.
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


## The band a monster spawning at this cell belongs to: a camp's monsters live at its campfire, any others at
## the middle of their room (or where they stand, outside any room). room_share and camp_share are the shares of
## each kind of band that start wandering.
static func home_of(map: DungeonMap, spawn_cell: Vector2i, room_share: float, camp_share: float) -> Home:
	var campfire := Camps.campfire_of(map, spawn_cell)
	if campfire != DungeonMap.NO_CELL:
		return Home.new(Camps.band_id(map, campfire), campfire, camp_share)
	var room := map.room_at(spawn_cell)
	var home := spawn_cell if room == DungeonMap.NO_ROOM else map.room_center(room)
	return Home.new(room, home, room_share)


## Where a band lives and how its kind starts (see home_of).
class Home:
	extends RefCounted
	## Which band it is: the number start_of rolls by, the same for every monster of the band.
	var id: int
	var cell: Vector2i
	var wandering_share: float

	func _init(band_id: int, home_cell: Vector2i, share: float) -> void:
		id = band_id
		cell = home_cell
		wandering_share = share
