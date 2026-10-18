class_name MapSpec
extends RefCounted
## Which map this is and how to make it: its id in the world (see WorldLayout), the generator recipe and the
## seed. The same spec always makes the same map. Pure.

## How a map is generated.
enum Recipe {
	## A floor of the descent: DungeonGenerator, dressed as the floor's branch.
	DUNGEON_FLOOR,
	## A quadrant of open ground (the plains): QuadrantGenerator by a QuadrantRecipe.
	QUADRANT,
}

var id: String
var recipe: Recipe
## How deep the map lies, for the recipes that use it (the descent's floor 1 is the top; the open ground above
## it is 0).
var floor_number: int
var seed_value: int
## What a QUADRANT map is made of (null for the other recipes).
var quadrant: QuadrantRecipe


func _init(map_id: String, map_recipe: Recipe, depth: int, map_seed: int, quadrant_recipe: QuadrantRecipe = null) -> void:
	id = map_id
	recipe = map_recipe
	floor_number = depth
	seed_value = map_seed
	quadrant = quadrant_recipe


## The map in the ASCII format DungeonMapParser reads.
func ascii() -> String:
	match recipe:
		Recipe.DUNGEON_FLOOR:
			return DungeonGenerator.new().generate(seed_value, floor_number)
		Recipe.QUADRANT:
			return QuadrantGenerator.new().generate(quadrant, seed_value)
	push_error("Unknown map recipe %d" % recipe)
	return ""


## The version of the generator the recipe uses, kept in the map's record (see MapRecord).
func generator_version() -> int:
	match recipe:
		Recipe.DUNGEON_FLOOR:
			return DungeonGenerator.VERSION
		Recipe.QUADRANT:
			return QuadrantRecipe.VERSION
	return 0


## What the map is (its name, greeting and look).
func branch() -> Branch:
	if recipe != Recipe.QUADRANT:
		return Branch.for_floor(floor_number)
	var plains := Branch.plains()
	plains.look.building_scale = quadrant.building_scale
	return plains
