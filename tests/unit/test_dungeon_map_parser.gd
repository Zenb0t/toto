extends GutTest

const TWO_ROOMS := """
#######
#P.+.e#
#######
"""

var _parser := DungeonMapParser.new()


func test_size_matches_the_drawing() -> void:
	var map := _parser.parse(TWO_ROOMS)

	assert_eq(map.size, Vector2i(7, 3))


func test_a_door_splits_floor_into_separate_rooms() -> void:
	var map := _parser.parse(TWO_ROOMS)

	assert_eq(map.room_count, 2)
	assert_ne(map.room_at(Vector2i(2, 1)), map.room_at(Vector2i(4, 1)))


func test_a_door_belongs_to_both_rooms_it_connects() -> void:
	var map := _parser.parse(TWO_ROOMS)
	var door := Vector2i(3, 1)

	assert_has(map.doors_of_room(map.room_at(Vector2i(2, 1))), door)
	assert_has(map.doors_of_room(map.room_at(Vector2i(4, 1))), door)


func test_doors_are_walkable_but_not_part_of_any_room() -> void:
	var map := _parser.parse(TWO_ROOMS)
	var door := Vector2i(3, 1)

	assert_true(map.is_walkable(door))
	assert_eq(map.room_at(door), DungeonMap.NO_ROOM)


func test_walls_are_not_walkable() -> void:
	var map := _parser.parse(TWO_ROOMS)

	assert_false(map.is_walkable(Vector2i(0, 0)))
	assert_eq(map.room_at(Vector2i(0, 0)), DungeonMap.NO_ROOM)


func test_spawn_markers_are_walkable_floor() -> void:
	var map := _parser.parse(TWO_ROOMS)

	assert_eq(map.player_spawn, Vector2i(1, 1))
	assert_eq(map.enemy_spawns, [Vector2i(5, 1)] as Array[Vector2i])
	assert_true(map.is_walkable(map.player_spawn))
	assert_ne(map.room_at(Vector2i(5, 1)), DungeonMap.NO_ROOM)


func test_cells_touching_a_door_are_not_clear_of_doors() -> void:
	var map := _parser.parse(TWO_ROOMS)

	assert_false(map.is_clear_of_doors(Vector2i(2, 1)))
	assert_true(map.is_clear_of_doors(Vector2i(1, 1)))
