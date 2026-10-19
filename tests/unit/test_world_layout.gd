extends GutTest
## Which maps a world holds, their seeds, and where each map's exits lead.


func test_the_world_is_the_plains_and_each_floor_of_the_descent_each_with_its_own_id() -> void:
	var ids := WorldLayout.map_ids()

	assert_eq(ids.size(), WorldLayout.FLOOR_COUNT + 1)
	assert_eq(ids[0], WorldLayout.PLAINS_ID)
	assert_eq(WorldLayout.start_map_id(), WorldLayout.PLAINS_ID)
	for i in ids.size():
		assert_eq(ids.find(ids[i]), i, "%s appears once" % ids[i])


func test_a_maps_seed_comes_from_the_world_seed() -> void:
	assert_eq(WorldLayout.map_seed(99, "crypt_2"), WorldLayout.map_seed(99, "crypt_2"))
	assert_ne(WorldLayout.map_seed(99, "crypt_2"), WorldLayout.map_seed(100, "crypt_2"), "another world")
	assert_ne(WorldLayout.map_seed(99, "crypt_2"), WorldLayout.map_seed(99, "crypt_3"), "another floor")


func test_a_floors_spec_is_its_depth_in_the_descent() -> void:
	for floor_number in range(1, WorldLayout.FLOOR_COUNT + 1):
		var spec := WorldLayout.spec(99, WorldLayout.floor_id(floor_number))

		assert_eq(spec.floor_number, floor_number)
		assert_eq(spec.recipe, MapSpec.Recipe.DUNGEON_FLOOR)
		assert_eq(spec.seed_value, WorldLayout.map_seed(99, spec.id))


func test_the_plains_spec_is_a_quadrant_made_by_its_recipe() -> void:
	var recipe := QuadrantRecipe.new()
	recipe.rock_pile_count = 3

	var spec := WorldLayout.spec(99, WorldLayout.PLAINS_ID, recipe)

	assert_eq(spec.recipe, MapSpec.Recipe.QUADRANT)
	assert_eq(spec.quadrant, recipe)
	assert_eq(spec.seed_value, WorldLayout.map_seed(99, WorldLayout.PLAINS_ID))
	assert_true(spec.branch().outdoors)


func test_the_crypt_entrance_leads_to_the_first_floors_stairs_up_and_they_lead_back() -> void:
	var down := WorldLayout.destination(WorldLayout.PLAINS_ID, WorldLayout.Exit.STAIRS_DOWN)
	var up := WorldLayout.destination(WorldLayout.floor_id(1), WorldLayout.Exit.STAIRS_UP)

	assert_eq([down.map_id, down.spot], [WorldLayout.floor_id(1), WorldLayout.Spot.STAIRS_UP])
	assert_eq([up.map_id, up.spot], [WorldLayout.PLAINS_ID, WorldLayout.Spot.STAIRS_DOWN])


func test_the_stairs_down_lead_to_the_stairs_up_one_floor_down() -> void:
	for floor_number in range(1, WorldLayout.FLOOR_COUNT):
		var destination := WorldLayout.destination(WorldLayout.floor_id(floor_number), WorldLayout.Exit.STAIRS_DOWN)

		assert_eq(destination.map_id, WorldLayout.floor_id(floor_number + 1))
		assert_eq(destination.spot, WorldLayout.Spot.STAIRS_UP)


func test_the_stairs_up_lead_to_the_stairs_down_one_floor_up() -> void:
	for floor_number in range(2, WorldLayout.FLOOR_COUNT + 1):
		var destination := WorldLayout.destination(WorldLayout.floor_id(floor_number), WorldLayout.Exit.STAIRS_UP)

		assert_eq(destination.map_id, WorldLayout.floor_id(floor_number - 1))
		assert_eq(destination.spot, WorldLayout.Spot.STAIRS_DOWN)


func test_each_spot_is_a_cell_of_the_map() -> void:
	var map := DungeonMapParser.new().parse("""
######
#P.<>#
######
""")

	assert_eq(WorldLayout.arrival_cell(map, WorldLayout.Spot.START), Vector2i(1, 1))
	assert_eq(WorldLayout.arrival_cell(map, WorldLayout.Spot.STAIRS_UP), Vector2i(3, 1))
	assert_eq(WorldLayout.arrival_cell(map, WorldLayout.Spot.STAIRS_DOWN), Vector2i(4, 1))


func test_only_stairs_are_exits() -> void:
	var map := DungeonMapParser.new().parse("""
######
#P.<>#
######
""")

	assert_eq(WorldLayout.exit_at(map, Vector2i(4, 1)), WorldLayout.Exit.STAIRS_DOWN)
	assert_eq(WorldLayout.exit_at(map, Vector2i(3, 1)), WorldLayout.Exit.STAIRS_UP)
	assert_eq(WorldLayout.exit_at(map, Vector2i(2, 1)), WorldLayout.NO_EXIT)
	assert_eq(WorldLayout.exit_at(map, Vector2i(1, 1)), WorldLayout.NO_EXIT, "the start is not an exit")


func test_every_level_has_stairs_down_but_the_last_where_the_lich_waits() -> void:
	assert_true(WorldLayout.has_stairs_down(WorldLayout.PLAINS_ID))
	for floor_number in range(1, WorldLayout.FLOOR_COUNT):
		assert_true(WorldLayout.has_stairs_down(WorldLayout.floor_id(floor_number)))
	assert_false(WorldLayout.has_stairs_down(WorldLayout.floor_id(WorldLayout.FLOOR_COUNT)))



func test_the_crypt_entrance_lets_the_hero_down_while_monsters_still_roam_the_plains() -> void:
	assert_true(WorldLayout.stairs_down_open(WorldLayout.PLAINS_ID, false))


func test_a_crypt_levels_stairs_down_wait_for_their_room_to_be_clear() -> void:
	var level := WorldLayout.floor_id(1)

	assert_false(WorldLayout.stairs_down_open(level, false))
	assert_true(WorldLayout.stairs_down_open(level, true))
