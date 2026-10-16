extends GutTest

const TWO_ROOMS := """
#######
#P.+.s#
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


func test_each_enemy_letter_arms_its_enemy_with_a_weapon() -> void:
	var map := _parser.parse("""
#######
#Pswcf#
#######
""")

	assert_eq(map.enemy_weapon_at(Vector2i(2, 1)), "sword")
	assert_eq(map.enemy_weapon_at(Vector2i(3, 1)), "wand")
	assert_eq(map.enemy_weapon_at(Vector2i(4, 1)), "crossbow")
	assert_eq(map.enemy_weapon_at(Vector2i(5, 1)), "fireball")


func test_cells_touching_a_door_are_not_clear_of_doors() -> void:
	var map := _parser.parse(TWO_ROOMS)

	assert_false(map.is_clear_of_doors(Vector2i(2, 1)))
	assert_true(map.is_clear_of_doors(Vector2i(1, 1)))


func test_a_rooms_center_is_the_floor_cell_in_its_middle() -> void:
	var map := _parser.parse("""
#######
#P....#
#.....#
#.....#
#######
""")

	assert_eq(map.room_center(map.room_at(Vector2i(1, 1))), Vector2i(3, 2))


func test_the_center_of_an_l_shaped_room_is_still_on_its_floor() -> void:
	var map := _parser.parse("""
######
#...P#
#.####
#.####
######
""")
	var room := map.room_at(Vector2i(1, 1))

	assert_eq(map.room_at(map.room_center(room)), room)


func test_the_exit_is_walkable_floor() -> void:
	var map := _parser.parse("""
#####
#P.>#
#####
""")

	assert_eq(map.exit_cell, Vector2i(3, 1))
	assert_true(map.is_walkable(map.exit_cell))
	assert_eq(map.room_at(map.exit_cell), map.room_at(map.player_spawn))


func test_a_map_may_have_no_exit() -> void:
	assert_eq(_parser.parse(TWO_ROOMS).exit_cell, DungeonMap.NO_CELL)
