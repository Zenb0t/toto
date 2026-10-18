extends GutTest
## The HUD and the arrival banner name the village while the hero is inside it, and the plains outside.

var _map: DungeonMap


func before_each() -> void:
	var recipe := QuadrantRecipe.plains()
	_map = DungeonMapParser.new().parse(QuadrantGenerator.new().generate(recipe, 4))


func test_inside_the_palisade_the_place_is_the_village() -> void:
	var place := Place.at(Branch.plains(), _map, _map.player_spawn)

	assert_eq(place.name, "village")
	assert_true(place.is_village)
	assert_ne(place.greeting, "")


func test_on_the_gate_cells_the_hero_is_still_in_the_village() -> void:
	assert_eq(Place.at(Branch.plains(), _map, _map.village.gates[0]).name, "village")


func test_outside_the_palisade_the_place_is_the_plains() -> void:
	var outside := _map.village.area.position - Vector2i(1, 1)

	var place := Place.at(Branch.plains(), _map, outside)

	assert_eq(place.name, "plains")
	assert_false(place.is_village)


func test_a_map_without_a_village_is_named_after_its_branch() -> void:
	var floor_map := DungeonMapParser.new().parse("#####\n#P..#\n#####")

	assert_eq(Place.at(Branch.for_floor(2), floor_map, Vector2i(2, 1)).name, Branch.for_floor(2).display_name)
