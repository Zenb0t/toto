class_name Place
extends RefCounted
## Where the hero is, as the HUD and the arrival banner name it: "the village" while inside the palisade, otherwise
## the map's own branch ("the plains", "the Lair"...). Pure.

const VILLAGE_GREETING := "Smoke from the chimneys. Nothing here bites."

var name: String
var greeting: String
## Whether this is the village rather than the branch the map is in.
var is_village := false


func _init(place_name: String, place_greeting: String, in_village := false) -> void:
	name = place_name
	greeting = place_greeting
	is_village = in_village


## The place a cell of a map is in, on a map of a branch.
static func at(branch: Branch, map: DungeonMap, cell: Vector2i) -> Place:
	if map.is_in_village(cell):
		return Place.new("village", VILLAGE_GREETING, true)
	return Place.new(branch.display_name, branch.greeting)
