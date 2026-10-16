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
