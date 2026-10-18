class_name WorldLayout
extends RefCounted
## Which maps a world holds and how they connect: today a descent of FLOOR_COUNT floors, each one's stairs leading
## down to the next and the last one's out of the dungeon. Every map's seed comes from the world seed, so the same
## world seed always gives the same maps. Pure.

const FLOOR_COUNT := 5

## A way off a map.
enum Exit {
	STAIRS_DOWN,
}

## Where on a map the hero appears.
enum Spot {
	## The map's start (the `@` of the map format).
	START,
}


## Where an exit leads: a map and the spot on it, or out of the world (the run is won).
class Destination:
	extends RefCounted
	## Empty when the exit leads out of the world.
	var map_id: String
	var spot: Spot

	func _init(to_map_id: String, at_spot := Spot.START) -> void:
		map_id = to_map_id
		spot = at_spot

	func leaves_world() -> bool:
		return map_id == ""


## The map a run starts on.
static func start_map_id() -> String:
	return floor_id(1)


static func floor_id(floor_number: int) -> String:
	return "floor_%d" % floor_number


static func map_ids() -> Array[String]:
	var ids: Array[String] = []
	for floor_number in range(1, FLOOR_COUNT + 1):
		ids.append(floor_id(floor_number))
	return ids


## The map's spec in the world grown from world_seed.
static func spec(world_seed: int, map_id: String) -> MapSpec:
	return MapSpec.new(map_id, MapSpec.Recipe.DUNGEON_FLOOR, _floor_number(map_id), map_seed(world_seed, map_id))


## A map's own seed: the same for the same world seed and map, different from map to map.
static func map_seed(world_seed: int, map_id: String) -> int:
	return ("%d/%s" % [world_seed, map_id]).hash()


## The transition rule: where taking an exit from a map leads.
static func destination(from_map_id: String, exit: Exit) -> Destination:
	match exit:
		Exit.STAIRS_DOWN:
			var below := _floor_number(from_map_id) + 1
			return Destination.new(floor_id(below) if below <= FLOOR_COUNT else "")
	push_error("Unknown exit %d" % exit)
	return Destination.new(from_map_id)


static func _floor_number(map_id: String) -> int:
	var index := map_ids().find(map_id)
	if index < 0:
		push_error("Unknown map id '%s'" % map_id)
	return index + 1
