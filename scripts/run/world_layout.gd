class_name WorldLayout
extends RefCounted
## Which maps a world holds and how they connect: the plains (the centre quadrant, where a run starts), whose
## crypt entrance leads down into the crypt: FLOOR_COUNT levels, each one's stairs down leading to the next level's
## stairs up (and back). The last level has no stairs down: its boss arena, where the Lich waits, is the end of the
## world (killing him wins the run, and play goes on). The first level's stairs up lead back out to the mausoleum. Every map's seed comes from the world seed, so the same world seed always gives the same maps. Pure.

## The levels of the crypt.
const FLOOR_COUNT := CryptRecipe.LEVELS
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
	## Beside the ruin's chest and just outside the arena's door: only warping lands here (see Warp).
	RUIN,
	ARENA_DOOR,
}


## Where an exit leads: a map and the spot on it.
class Destination:
	extends RefCounted
	var map_id: String
	var spot: Spot

	func _init(to_map_id: String, at_spot := Spot.START) -> void:
		map_id = to_map_id
		spot = at_spot


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
		return MapSpec.new(map_id, MapSpec.Recipe.QUADRANT, 0, map_seed(world_seed, map_id), plains, crypt)
	return MapSpec.new(map_id, MapSpec.Recipe.DUNGEON_FLOOR, _floor_number(map_id), map_seed(world_seed, map_id), null, crypt)


## A map's own seed: the same for the same world seed and map, different from map to map.
static func map_seed(world_seed: int, map_id: String) -> int:
	return ("%d/%s" % [world_seed, map_id]).hash()


## Whether a map has stairs down: every crypt level but the last, and the way down from the plains (the crypt
## entrance).
static func has_stairs_down(map_id: String) -> bool:
	return _floor_number(map_id) < FLOOR_COUNT


## Whether the stairs down let the hero through. In the crypt they wait for their room to be clear; the crypt
## entrance on the plains is always open (the plains have no rooms: all their monsters share one, so waiting for it
## would mean clearing every camp first).
static func stairs_down_open(map_id: String, room_cleared: bool) -> bool:
	return map_id == PLAINS_ID or room_cleared


## The transition rule: where taking an exit from a map leads. Stairs lead to the matching stairs on the
## other floor, so going down and back up puts the hero where they were.
static func destination(from_map_id: String, exit: Exit) -> Destination:
	var floor_number := _floor_number(from_map_id)
	match exit:
		Exit.STAIRS_DOWN:
			assert(floor_number < FLOOR_COUNT, "the last level has no stairs down")
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
		Spot.RUIN:
			return Warp.cell_beside_ruin(map)
		Spot.ARENA_DOOR:
			return Warp.cell_outside_arena(map)
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
