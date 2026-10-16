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


func test_each_enemy_letter_spawns_its_monster() -> void:
	var map := _parser.parse("""
#######
#PkoOs#
#######
""")

	assert_eq(map.monster_at(Vector2i(2, 1)), "kobold")
	assert_eq(map.monster_at(Vector2i(3, 1)), "orc")
	assert_eq(map.monster_at(Vector2i(4, 1)), "ogre")
	assert_eq(map.monster_at(Vector2i(5, 1)), "bandit")
	assert_eq(map.enemy_spawns.size(), 4)


func test_every_monster_letter_is_read_as_an_enemy() -> void:
	var map := _parser.parse("#".repeat(14) + "\n#P" + "".join(Bestiary.letters()) + "#\n" + "#".repeat(14))

	assert_eq(map.enemy_spawns.size(), Bestiary.all().size())


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


const POOL_ROOM := """
#########
#P......#
#..~~L..#
#..~~L*.#
#########
"""


func test_water_and_lava_belong_to_the_room_they_are_in() -> void:
	var map := _parser.parse(POOL_ROOM)

	assert_eq(map.room_count, 1)
	assert_eq(map.terrain_at(Vector2i(3, 2)), DungeonMap.Terrain.WATER)
	assert_eq(map.terrain_at(Vector2i(5, 2)), DungeonMap.Terrain.LAVA)


func test_water_blocks_walking_but_not_sight() -> void:
	var map := _parser.parse(POOL_ROOM)

	assert_false(map.is_walkable(Vector2i(3, 2)))
	assert_true(map.is_see_through(Vector2i(3, 2)))


func test_lava_can_be_walked_on_but_is_no_place_to_stand() -> void:
	var map := _parser.parse(POOL_ROOM)

	assert_true(map.is_walkable(Vector2i(5, 2)))
	assert_false(map.is_standable(Vector2i(5, 2)))


func test_items_can_lie_on_the_floor() -> void:
	assert_eq(_parser.parse(POOL_ROOM).loot_cells, [Vector2i(6, 3)] as Array[Vector2i])


func test_a_rooms_center_is_never_in_its_pool() -> void:
	var map := _parser.parse("""
#######
#P....#
#..~..#
#.....#
#######
""")

	assert_true(map.is_standable(map.room_center(0)))
