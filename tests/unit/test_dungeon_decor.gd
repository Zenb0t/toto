extends GutTest

const HALL := """
##########
#P.......#
#..##....#
#..##....#
#........#
##########
"""


func _hall() -> DungeonMap:
	return DungeonMapParser.new().parse(HALL)


## The walls the game draws: those next to open cells (like DungeonView.wall_cells()).
func _walls(map: DungeonMap) -> Array[Vector2i]:
	var walls: Array[Vector2i] = []
	for y in map.size.y:
		for x in map.size.x:
			var cell := Vector2i(x, y)
			if not map.is_open(cell) and DungeonDecor.NEIGHBOURS_8.any(
					func(step: Vector2i) -> bool: return map.is_open(cell + step)):
				walls.append(cell)
	return walls


func test_the_same_cell_always_looks_the_same() -> void:
	assert_eq(DungeonDecor.tint(Vector2i(4, 7)), DungeonDecor.tint(Vector2i(4, 7)))
	assert_eq(DungeonDecor.crack(Vector2i(9, 2)), DungeonDecor.crack(Vector2i(9, 2)))


func test_noise_always_picks_an_entry_of_a_list() -> void:
	var three := ["a", "b", "c"]
	for x in 200:
		for y in 200:
			var index := floori(DungeonDecor.noise(Vector2i(x, y), 18) * three.size())
			if index < 0 or index >= three.size():
				fail_test("cell (%d, %d) picks index %d" % [x, y, index])
				return
	pass_test("every cell picks one of the three")


func test_tints_vary_within_their_range() -> void:
	var seen := {}
	for x in 50:
		var tint := DungeonDecor.tint(Vector2i(x, 3))
		assert_between(tint, -1.0, 1.0)
		seen[snappedf(tint, 0.1)] = true

	assert_gt(seen.size(), 5)


func test_only_some_tiles_are_cracked_and_cracks_stay_on_their_tile() -> void:
	var cracked := 0
	for x in 300:
		var crack := DungeonDecor.crack(Vector2i(x, x * 7))
		if not crack.is_empty():
			cracked += 1
		for point in crack:
			assert_true(Rect2(0, 0, 1, 1).has_point(point), str(point))

	assert_between(cracked, 10, 80)


func test_walls_inside_a_room_are_pillars_and_the_outer_walls_are_not() -> void:
	var map := _hall()
	var pillars := DungeonDecor.pillar_cells(map, _walls(map))

	assert_has(pillars, Vector2i(3, 2))
	assert_has(pillars, Vector2i(4, 3))
	assert_does_not_have(pillars, Vector2i(0, 0))
	assert_does_not_have(pillars, Vector2i(5, 0))
	assert_eq(pillars.size(), 4)


func test_torches_hang_only_on_walls_above_open_floor() -> void:
	var map := DungeonMapParser.new().parse(DungeonGenerator.new().generate(5))
	var walls := _walls(map)
	var torches := DungeonDecor.torch_cells(map, walls)

	assert_gt(torches.size(), 5)
	for cell in torches:
		assert_true(map.is_open(cell + Vector2i.DOWN), str(cell))
		assert_false(map.is_door(cell + Vector2i.DOWN), str(cell))


func test_torches_are_spread_out() -> void:
	var map := DungeonMapParser.new().parse(DungeonGenerator.new().generate(5))
	var torches := DungeonDecor.torch_cells(map, _walls(map))

	for cell in torches:
		assert_does_not_have(torches, cell + Vector2i.RIGHT)
		assert_does_not_have(torches, cell + Vector2i.LEFT)


func test_torchlight_falls_only_on_open_floor_and_fades_with_distance() -> void:
	var map := _hall()
	var torch := Vector2i(6, 0)

	var light := DungeonDecor.torch_light(map, [torch] as Array[Vector2i])

	for cell: Vector2i in light:
		assert_true(map.is_open(cell), str(cell))
	assert_gt(light[Vector2i(6, 1)], light[Vector2i(6, 3)])
	assert_does_not_have(light, Vector2i(6, 0), "not on the wall itself")
	assert_does_not_have(light, Vector2i(1, 4), "out of reach")


func test_banners_hang_on_walls_above_open_floor_and_never_where_a_torch_is() -> void:
	var map := DungeonMapParser.new().parse(DungeonGenerator.new().generate(5))
	var walls := _walls(map)
	var banners := DungeonDecor.banner_cells(map, walls)
	var torches := DungeonDecor.torch_cells(map, walls)

	assert_gt(banners.size(), 0)
	for cell in banners:
		assert_true(map.is_open(cell + Vector2i.DOWN), str(cell))
		assert_does_not_have(torches, cell)


func test_clutter_lies_along_walls_and_never_in_the_way_of_the_game() -> void:
	var map := DungeonMapParser.new().parse(DungeonGenerator.new().generate(5))

	var clutter := DungeonDecor.clutter_cells(map, 4)

	assert_gt(clutter.size(), 3)
	for cell: Vector2i in clutter:
		assert_false(map.is_open(cell + Vector2i.UP), "a wall above %s" % cell)
		assert_true(map.is_standable(cell))
		assert_does_not_have(map.enemy_spawns, cell)
		assert_does_not_have(map.loot_cells, cell)
		assert_ne(cell, map.exit_cell)
		assert_between(clutter[cell], 0, 3)


func test_a_long_wall_inside_a_room_stays_a_wall() -> void:
	var map := DungeonMapParser.new().parse("""
##########
#P.......#
#........#
#.######.#
#........#
##########
""")

	assert_eq(DungeonDecor.pillar_cells(map, _walls(map)), [] as Array[Vector2i])
