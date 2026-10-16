extends GutTest

const NEAR_WALL := Vector2i(5, 0)
const FAR_WALL := Vector2i(62, 0)
const DOOR := Vector2i(2, 0)
const PILLAR := Vector2i(29, 2)
## A long hall, with a door in its top wall and a pillar in the middle.
const HALL_WIDTH := 64


func _hall() -> DungeonMap:
	var rows := PackedStringArray([
		"##+" + "#".repeat(HALL_WIDTH - 3),
		"#P" + ".".repeat(HALL_WIDTH - 3) + "#",
		"#" + ".".repeat(28) + "#" + ".".repeat(HALL_WIDTH - 31) + "#",
		"#" + ".".repeat(HALL_WIDTH - 2) + "#",
		"#".repeat(HALL_WIDTH),
	])
	return DungeonMapParser.new().parse("\n".join(rows))


func _map_view() -> MapView3D:
	var view: MapView3D = autofree(MapView3D.new())
	var map := _hall()
	var walls: Array[Vector2i] = []
	for y in map.size.y:
		for x in map.size.x:
			if not map.is_open(Vector2i(x, y)):
				walls.append(Vector2i(x, y))
	view.show_map(map, walls)
	return view


## Nothing blocks sight, so what is in view depends only on distance.
func _looking_from(origin: Vector2i, exploration := Exploration.new()) -> Exploration:
	exploration.look_from(origin, func(_cell: Vector2i) -> bool: return true)
	return exploration


func test_walls_in_sight_stand_lit() -> void:
	var view := _map_view()

	view.show_exploration(_looking_from(Vector2i(2, 3)))

	assert_true(view.is_standing(NEAR_WALL))
	assert_eq(view.brightness(NEAR_WALL), MapView3D.LIT)


func test_walls_never_seen_are_not_shown() -> void:
	var view := _map_view()

	view.show_exploration(_looking_from(Vector2i(2, 3)))

	assert_false(view.is_standing(FAR_WALL))


func test_walls_seen_before_but_out_of_sight_are_dimmed() -> void:
	var view := _map_view()
	var exploration := _looking_from(Vector2i(2, 3))

	view.show_exploration(_looking_from(Vector2i(60, 3), exploration))

	assert_true(view.is_standing(NEAR_WALL))
	assert_lt(view.brightness(NEAR_WALL), view.brightness(FAR_WALL))


func test_a_door_stands_only_while_it_is_closed() -> void:
	var view := _map_view()
	var doors: Array[Vector2i] = [DOOR]
	assert_false(view.is_standing(DOOR), "open at first")

	view.set_doors_closed(doors, true)
	assert_true(view.is_standing(DOOR), "closed")

	view.set_doors_closed(doors, false)
	assert_false(view.is_standing(DOOR), "open again")


func test_a_pillar_stands_like_a_wall() -> void:
	var view := _map_view()

	view.show_exploration(_looking_from(Vector2i(30, 3)))

	assert_true(view.is_standing(PILLAR))


func test_walls_facing_the_camera_get_torches() -> void:
	assert_gt(_map_view().torch_count(), 0)


func test_floor_cells_have_no_block() -> void:
	var view := _map_view()

	assert_false(view.is_standing(Vector2i(3, 3)))


func test_a_wall_beside_floor_in_sight_is_lit_even_if_sight_grazes_past_it() -> void:
	var view := _map_view()
	var exploration := Exploration.new()
	var floor_only := func(cell: Vector2i) -> bool: return cell.y > 0
	exploration.look_from(Vector2i(10, 1), floor_only)
	assert_false(exploration.is_visible(Vector2i(20, 0)), "the wall itself isn't in the line of sight")

	view.show_exploration(exploration)

	assert_eq(view.brightness(Vector2i(20, 0)), MapView3D.LIT)


func test_walls_in_front_of_the_hero_are_cut_down_and_grow_back() -> void:
	var view := _map_view()
	var bottom_wall := Vector2i(20, 4)

	view.show_hero_at(Vector2i(20, 3))
	assert_true(view.is_cut_away(bottom_wall))
	assert_false(view.is_cut_away(Vector2i(20, 0)), "walls behind the hero stay whole")

	view.show_hero_at(Vector2i(20, 1))
	assert_false(view.is_cut_away(bottom_wall))


func test_a_cave_branch_shows_its_walls_without_torches_or_columns() -> void:
	var view: MapView3D = autofree(MapView3D.new())
	var map := _hall()
	var walls: Array[Vector2i] = []
	for y in map.size.y:
		for x in map.size.x:
			if not map.is_open(Vector2i(x, y)):
				walls.append(Vector2i(x, y))

	view.show_map(map, walls, BranchLook.lair())

	assert_eq(view.torch_count(), 0)
	assert_true(view.is_standing(PILLAR), "the pillar stands, as rock")
