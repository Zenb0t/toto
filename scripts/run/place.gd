class_name Place
extends RefCounted
## Where the hero is, as the HUD and the arrival banner name it: "The village" while inside the palisade,
## otherwise the map itself ("The plains", "Crypt level 2"; see MapSpec.place_name). Pure.

const VILLAGE_NAME := "The village"
const VILLAGE_GREETING := "Smoke from the chimneys. Nothing here bites."

var name: String
var greeting: String
## Whether this is the village rather than the map it stands on.
var is_village := false


func _init(place_name: String, place_greeting: String, in_village := false) -> void:
	name = place_name
	greeting = place_greeting
	is_village = in_village


## The place a cell of a map is in, on the map that spec makes.
static func at(spec: MapSpec, map: DungeonMap, cell: Vector2i) -> Place:
	if map.is_in_village(cell):
		return Place.new(VILLAGE_NAME, VILLAGE_GREETING, true)
	return Place.new(spec.place_name(), spec.branch().greeting)
