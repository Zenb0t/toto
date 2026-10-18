extends GutTest
## Which maps a world holds, their seeds, and where each map's exits lead.


func test_each_floor_has_its_own_id() -> void:
	var ids := WorldLayout.map_ids()

	assert_eq(ids.size(), WorldLayout.FLOOR_COUNT)
	for i in ids.size():
		assert_eq(ids.find(ids[i]), i, "%s appears once" % ids[i])


func test_a_maps_seed_comes_from_the_world_seed() -> void:
	assert_eq(WorldLayout.map_seed(99, "floor_2"), WorldLayout.map_seed(99, "floor_2"))
	assert_ne(WorldLayout.map_seed(99, "floor_2"), WorldLayout.map_seed(100, "floor_2"), "another world")
	assert_ne(WorldLayout.map_seed(99, "floor_2"), WorldLayout.map_seed(99, "floor_3"), "another floor")


func test_a_floors_spec_is_its_depth_in_the_descent() -> void:
	for floor_number in range(1, WorldLayout.FLOOR_COUNT + 1):
		var spec := WorldLayout.spec(99, WorldLayout.floor_id(floor_number))

		assert_eq(spec.floor_number, floor_number)
		assert_eq(spec.recipe, MapSpec.Recipe.DUNGEON_FLOOR)
		assert_eq(spec.seed_value, WorldLayout.map_seed(99, spec.id))


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


func test_only_the_bottom_floors_stairs_lead_out() -> void:
	var bottom := WorldLayout.floor_id(WorldLayout.FLOOR_COUNT)

	assert_true(WorldLayout.destination(bottom, WorldLayout.Exit.STAIRS_DOWN).leaves_world())

