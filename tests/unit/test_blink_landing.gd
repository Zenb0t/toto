extends GutTest
## Where a blink lands: over water and past low obstacles, never through a wall or a shut door, and only where
## the hero can stand.

const CELL := DungeonView.TILE_SIZE
const RADIUS := Player.RADIUS


func _map(ascii: String) -> DungeonMap:
	return DungeonMapParser.new().parse(ascii)


func _centre(cell: Vector2i) -> Vector2:
	return DungeonView.cell_center(cell)


func _no_door_closed(_cell: Vector2i) -> bool:
	return false


func _land(map: DungeonMap, from_cell: Vector2i, to_cell: Vector2i, door_closed := _no_door_closed) -> Vector2:
	return BlinkLanding.find(_centre(from_cell), _centre(to_cell), map, door_closed, RADIUS)


func test_on_open_floor_it_lands_on_the_spot_aimed_at() -> void:
	var map := _map("""
#######
#P....#
#######
""")

	assert_eq(_land(map, Vector2i(1, 1), Vector2i(5, 1)), _centre(Vector2i(5, 1)))


func test_it_crosses_deep_water_to_the_far_bank() -> void:
	var map := _map("""
#######
#P~~~.#
#######
""")

	assert_eq(_land(map, Vector2i(1, 1), Vector2i(5, 1)), _centre(Vector2i(5, 1)))


func test_aimed_into_deep_water_it_lands_on_the_last_dry_spot_before_it() -> void:
	var map := _map("""
#######
#P..~~#
#######
""")

	var landing := _land(map, Vector2i(1, 1), Vector2i(5, 1))

	assert_true(map.is_walkable(DungeonView.world_to_cell(landing + Vector2.RIGHT * RADIUS * 0.9)))
	assert_gt(landing.x, _centre(Vector2i(2, 1)).x)
	assert_lt(landing.x, 4 * CELL)


func test_a_wall_stops_it_short_even_with_floor_beyond() -> void:
	var map := _map("""
#########
#P..#...#
#########
""")

	var landing := _land(map, Vector2i(1, 1), Vector2i(6, 1))

	assert_lt(landing.x, 4 * CELL)
	assert_gt(landing.x, _centre(Vector2i(2, 1)).x)


func test_a_closed_door_stops_it_but_an_open_one_does_not() -> void:
	var map := _map("""
#########
#P..+...#
#########
""")
	var door := Vector2i(4, 1)
	var door_shut := func(cell: Vector2i) -> bool: return cell == door

	assert_lt(_land(map, Vector2i(1, 1), Vector2i(6, 1), door_shut).x, 4 * CELL)
	assert_eq(_land(map, Vector2i(1, 1), Vector2i(6, 1)), _centre(Vector2i(6, 1)))


func test_it_hops_over_a_boulder_but_never_lands_on_one() -> void:
	var map := _map("""
#######
#P.B..#
#######
""")

	assert_eq(_land(map, Vector2i(1, 1), Vector2i(5, 1)), _centre(Vector2i(5, 1)))
	assert_lt(_land(map, Vector2i(1, 1), Vector2i(3, 1)).x, 3 * CELL)


func test_it_may_land_in_lava_and_shallow_water_which_can_be_walked() -> void:
	var map := _map("""
#######
#P.L,.#
#######
""")

	assert_eq(_land(map, Vector2i(1, 1), Vector2i(3, 1)), _centre(Vector2i(3, 1)))
	assert_eq(_land(map, Vector2i(1, 1), Vector2i(4, 1)), _centre(Vector2i(4, 1)))


func test_with_no_far_bank_it_stays_on_its_own_bank() -> void:
	var map := _map("""
#####
#P~~#
#####
""")

	assert_eq(DungeonView.world_to_cell(_land(map, Vector2i(1, 1), Vector2i(3, 1))), Vector2i(1, 1))


func test_with_nowhere_to_land_it_stays_where_it_started() -> void:
	var map := _map("""
#####
#P#.#
#####
""")
	var start := _centre(Vector2i(1, 1)) + Vector2.RIGHT * (CELL / 2.0 - RADIUS)

	assert_eq(BlinkLanding.find(start, _centre(Vector2i(3, 1)), map, _no_door_closed, RADIUS), start)
