extends GutTest
## The HUD and the arrival banner name the village while the hero is inside it, the plains outside, and the crypt
## by its level.

var _plains: MapSpec
var _map: DungeonMap


func before_each() -> void:
	_plains = MapSpec.new(WorldLayout.PLAINS_ID, MapSpec.Recipe.QUADRANT, 0, 4, QuadrantRecipe.plains())
	_map = DungeonMapParser.new().parse(_plains.ascii())


func test_inside_the_palisade_the_place_is_the_village() -> void:
	var place := Place.at(_plains, _map, _map.player_spawn)

	assert_eq(place.name, "The village")
	assert_true(place.is_village)
	assert_ne(place.greeting, "")


func test_on_the_gate_cells_the_hero_is_still_in_the_village() -> void:
	assert_eq(Place.at(_plains, _map, _map.village.gates[0]).name, "The village")


func test_outside_the_palisade_the_place_is_the_plains() -> void:
	var outside := _map.village.area.position - Vector2i(1, 1)

	var place := Place.at(_plains, _map, outside)

	assert_eq(place.name, "The plains")
	assert_false(place.is_village)


func test_on_a_crypt_level_the_place_is_named_after_the_level() -> void:
	var level := MapSpec.new(WorldLayout.floor_id(2), MapSpec.Recipe.DUNGEON_FLOOR, 2, 1)
	var floor_map := DungeonMapParser.new().parse("#####\n#P..#\n#####")

	var place := Place.at(level, floor_map, Vector2i(2, 1))

	assert_eq(place.name, "Crypt level 2")
	assert_eq(place.greeting, Branch.crypt().greeting)
