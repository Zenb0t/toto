extends GutTest

## # wall, P the player's start, . floor, ~ deep water, + door, > stairs.
const LAYOUT := """
##########
#P.~.+..>#
##########
"""


func _map() -> DungeonMap:
	return DungeonMapParser.new().parse(LAYOUT)


func _explored_from(map: DungeonMap, origin: Vector2i, sees_through: Callable) -> Exploration:
	var exploration := Exploration.new()
	exploration.look_from(origin, sees_through)
	return exploration


## Pixels hold 8 bits per channel, so colours come back a hair off.
func _assert_colour(actual: Color, expected: Color) -> void:
	var difference := absf(actual.r - expected.r) + absf(actual.g - expected.g) + absf(actual.b - expected.b)
	assert_lt(difference, 0.02, "%s should be %s" % [actual, expected])


func _sees_everything(_cell: Vector2i) -> bool:
	return true


func _sees_only_the_first_room(cell: Vector2i) -> bool:
	return cell.x < 5


func test_cells_never_seen_stay_blank() -> void:
	var map := _map()
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_only_the_first_room)

	var image := MinimapPainter.paint(map, exploration, Vector2i(1, 1))

	assert_eq(image.get_pixel(7, 1).a, 0.0)


func test_walls_are_not_painted() -> void:
	var map := _map()
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_everything)

	var image := MinimapPainter.paint(map, exploration, Vector2i(1, 1))

	assert_eq(image.get_pixel(0, 0).a, 0.0)


func test_seen_floor_is_painted() -> void:
	var map := _map()
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_everything)

	var image := MinimapPainter.paint(map, exploration, Vector2i(1, 1))

	_assert_colour(image.get_pixel(2, 1), MinimapPainter.FLOOR_COLOR)


func test_water_doors_and_stairs_are_told_apart_from_floor() -> void:
	var map := _map()
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_everything)

	var image := MinimapPainter.paint(map, exploration, Vector2i(1, 1))

	_assert_colour(image.get_pixel(3, 1), MinimapPainter.WATER_COLOR)
	_assert_colour(image.get_pixel(5, 1), MinimapPainter.DOOR_COLOR)
	_assert_colour(image.get_pixel(8, 1), MinimapPainter.EXIT_COLOR)


func test_the_stairs_up_have_a_colour_of_their_own() -> void:
	var map := DungeonMapParser.new().parse("""
######
#P.<>#
######
""")
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_everything)

	var image := MinimapPainter.paint(map, exploration, Vector2i(1, 1))

	_assert_colour(image.get_pixel(3, 1), MinimapPainter.STAIRS_UP_COLOR)
	assert_ne(MinimapPainter.STAIRS_UP_COLOR, MinimapPainter.EXIT_COLOR)


func test_the_player_is_marked() -> void:
	var map := _map()
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_everything)

	var image := MinimapPainter.paint(map, exploration, Vector2i(2, 1))

	_assert_colour(image.get_pixel(2, 1), MinimapPainter.PLAYER_COLOR)


func test_cells_seen_before_but_out_of_view_are_darker_than_cells_in_view() -> void:
	var map := _map()
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_everything)
	exploration.look_from(Vector2i(8, 1), _sees_only_the_first_room)  # now only (8, 1) itself is in view

	var image := MinimapPainter.paint(map, exploration, Vector2i(8, 1))

	assert_lt(image.get_pixel(2, 1).v, MinimapPainter.FLOOR_COLOR.v, "remembered")


func test_groves_boulders_and_exits_show_once_seen() -> void:
	var map := DungeonMapParser.new().parse("""
#######
#P.TB=#
#######
""")
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_everything)

	var image := MinimapPainter.paint(map, exploration, Vector2i(1, 1))

	_assert_colour(image.get_pixel(3, 1), MinimapPainter.GROVE_COLOR)
	_assert_colour(image.get_pixel(4, 1), MinimapPainter.BOULDER_COLOR)
	_assert_colour(image.get_pixel(5, 1), MinimapPainter.BARRICADE_COLOR)


func test_groves_never_seen_stay_blank() -> void:
	var map := DungeonMapParser.new().parse("""
#####
#P.T#
#####
""")
	var exploration := Exploration.new()

	var image := MinimapPainter.paint(map, exploration, Vector2i(1, 1))

	assert_eq(image.get_pixel(3, 1).a, 0.0)


func test_a_dirt_road_is_drawn_in_its_own_colour_once_seen() -> void:
	var map := DungeonMapParser.new().parse("""
#####
#Pr.#
#####
""")
	var exploration := _explored_from(map, Vector2i(1, 1), _sees_everything)

	var image := MinimapPainter.paint(map, exploration, Vector2i(1, 1))

	_assert_colour(image.get_pixel(2, 1), MinimapPainter.ROAD_COLOR)
	_assert_colour(image.get_pixel(3, 1), MinimapPainter.FLOOR_COLOR)
