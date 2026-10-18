class_name WorldLayout
extends RefCounted
## Which maps a world holds and how they connect: the plains (the centre quadrant, where a run starts), whose
## crypt entrance leads down into the crypt: FLOOR_COUNT levels, each one's stairs down leading to the next level's
## stairs up (and back). Until the Lich waits at the bottom, the last level's stairs lead out of the world (the run
## is won). The first level's stairs up lead back out to the mausoleum. Every map's seed comes from the world seed, so the same world seed always gives the same maps. Pure.

## The levels of the crypt.
const FLOOR_COUNT := 3
const PLAINS_ID := "plains"
## exit_at's answer for a cell that leads nowhere.
const NO_EXIT := -1

## A way off a map.
enum Exit {
	STAIRS_DOWN,
	STAIRS_UP,
}

## Where on a map the hero appears.
enum Spot {
	## The map's start (the `P` of the map format, or its stairs up when it has no `P`).
	START,
	STAIRS_DOWN,
	STAIRS_UP,
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
	return PLAINS_ID


static func floor_id(floor_number: int) -> String:
	return "crypt_%d" % floor_number


static func map_ids() -> Array[String]:
	var ids: Array[String] = [PLAINS_ID]
	for floor_number in range(1, FLOOR_COUNT + 1):
		ids.append(floor_id(floor_number))
	return ids


## The map's spec in the world grown from world_seed. plains: what the plains is made of; crypt: what the
## crypt's levels are made of.
static func spec(
		world_seed: int, map_id: String, plains := QuadrantRecipe.plains(), crypt := CryptRecipe.new()) -> MapSpec:
	if map_id == PLAINS_ID:
		return MapSpec.new(map_id, MapSpec.Recipe.QUADRANT, 0, map_seed(world_seed, map_id), plains)
	return MapSpec.new(map_id, MapSpec.Recipe.DUNGEON_FLOOR, _floor_number(map_id), map_seed(world_seed, map_id), null, crypt)


## A map's own seed: the same for the same world seed and map, different from map to map.
static func map_seed(world_seed: int, map_id: String) -> int:
	return ("%d/%s" % [world_seed, map_id]).hash()


## The transition rule: where taking an exit from a map leads. Stairs lead to the matching stairs on the
## other floor, so going down and back up puts the hero where they were.
static func destination(from_map_id: String, exit: Exit) -> Destination:
	var floor_number := _floor_number(from_map_id)
	match exit:
		Exit.STAIRS_DOWN:
			if floor_number == FLOOR_COUNT:
				return Destination.new("")
			return Destination.new(floor_id(floor_number + 1), Spot.STAIRS_UP)
		Exit.STAIRS_UP:
			assert(floor_number > 0, "the plains have no stairs up")
			if floor_number == 1:
				return Destination.new(PLAINS_ID, Spot.STAIRS_DOWN)
			return Destination.new(floor_id(floor_number - 1), Spot.STAIRS_DOWN)
	push_error("Unknown exit %d" % exit)
	return Destination.new(from_map_id)


## The cell of a map where the hero appears at a spot.
static func arrival_cell(map: DungeonMap, spot: Spot) -> Vector2i:
	match spot:
		Spot.STAIRS_DOWN:
			return map.exit_cell
		Spot.STAIRS_UP:
			return map.stairs_up_cell
	return map.player_spawn


## Which exit a cell of a map is (stairs down or up), or NO_EXIT.
static func exit_at(map: DungeonMap, cell: Vector2i) -> int:
	if cell == DungeonMap.NO_CELL:
		return NO_EXIT
	if cell == map.exit_cell:
		return Exit.STAIRS_DOWN
	if cell == map.stairs_up_cell:
		return Exit.STAIRS_UP
	return NO_EXIT


## The plains are 0, the crypt's levels 1 to FLOOR_COUNT.
static func _floor_number(map_id: String) -> int:
	var index := map_ids().find(map_id)
	if index < 0:
		push_error("Unknown map id '%s'" % map_id)
	return index
