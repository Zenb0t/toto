class_name MapSpec
extends RefCounted
## Which map this is and how to make it: its id in the world (see WorldLayout), the generator recipe and the
## seed. The same spec always makes the same map. Pure.

## How a map is generated.
enum Recipe {
	## A floor of the descent: DungeonGenerator, dressed as the floor's branch.
	DUNGEON_FLOOR,
}

var id: String
var recipe: Recipe
## How deep the map lies, for the recipes that use it (the descent's floor 1 is the top).
var floor_number: int
var seed_value: int


func _init(map_id: String, map_recipe: Recipe, depth: int, map_seed: int) -> void:
	id = map_id
	recipe = map_recipe
	floor_number = depth
	seed_value = map_seed


## The map in the ASCII format DungeonMapParser reads.
func ascii() -> String:
	match recipe:
		Recipe.DUNGEON_FLOOR:
			return DungeonGenerator.new().generate(seed_value, floor_number)
	push_error("Unknown map recipe %d" % recipe)
	return ""


## What the map is (its name, greeting and look).
func branch() -> Branch:
	return Branch.for_floor(floor_number)
