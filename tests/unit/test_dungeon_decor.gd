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
