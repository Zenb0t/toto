extends GutTest

## A wall splits the room except for a gap at the bottom.
const WALLED := """
#########
#P..#...#
#...#...#
#...#...#
#.......#
#########
"""

var _parser := DungeonMapParser.new()


func _at(cell: Vector2i) -> Vector2:
	return DungeonView.cell_center(cell)


func test_a_wall_blocks_the_view() -> void:
	var finder := Pathfinder.new(_parser.parse(WALLED))

	assert_false(finder.can_see(_at(Vector2i(2, 2)), _at(Vector2i(6, 2))))


func test_open_floor_does_not_block_the_view() -> void:
	var finder := Pathfinder.new(_parser.parse(WALLED))

	assert_true(finder.can_see(_at(Vector2i(1, 4)), _at(Vector2i(7, 4))))


func test_the_way_round_a_wall_goes_through_the_gap() -> void:
	var finder := Pathfinder.new(_parser.parse(WALLED))

	var path := finder.path(_at(Vector2i(2, 1)), _at(Vector2i(6, 1)))

	assert_false(path.is_empty())
	assert_eq(path[-1], _at(Vector2i(6, 1)))
	assert_has(Array(path), _at(Vector2i(4, 4)))


func test_there_is_no_way_into_a_wall() -> void:
	var finder := Pathfinder.new(_parser.parse(WALLED))

	assert_true(finder.path(_at(Vector2i(1, 1)), _at(Vector2i(4, 1))).is_empty())


## A pool splits the room with lava as the only short way across; a long way goes round the bottom.
const POOL := """
##########
#P..~~...#
#...LL...#
#...~~...#
#........#
##########
"""


func test_water_blocks_the_way_but_not_the_view() -> void:
	var finder := Pathfinder.new(_parser.parse(POOL))

	assert_true(finder.can_see(_at(Vector2i(2, 1)), _at(Vector2i(7, 1))))
	assert_true(finder.path(_at(Vector2i(2, 1)), _at(Vector2i(4, 1))).is_empty())


func test_paths_go_round_lava_when_there_is_another_way() -> void:
	var finder := Pathfinder.new(_parser.parse(POOL))

	var path := finder.path(_at(Vector2i(3, 2)), _at(Vector2i(6, 2)))

	assert_does_not_have(Array(path), _at(Vector2i(4, 2)))
	assert_does_not_have(Array(path), _at(Vector2i(5, 2)))


func test_paths_go_round_shallow_water_when_dry_ground_is_close() -> void:
	var map := DungeonMapParser.new().parse("""
#######
#P....#
#.,,,.#
#.....#
#######
""")
	var path := Pathfinder.new(map).path(DungeonView.cell_center(Vector2i(1, 2)), DungeonView.cell_center(Vector2i(5, 2)))

	for point in path:
		assert_ne(map.terrain_at(DungeonView.world_to_cell(point)), DungeonMap.Terrain.SHALLOW, str(point))
