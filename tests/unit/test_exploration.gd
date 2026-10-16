extends GutTest

## . open, # wall. The origin is at (1, 1).
const ROOM := [
	"#########",
	"#...#...#",
	"#...#...#",
	"#.......#",
	"#########",
]
const ORIGIN := Vector2i(1, 1)


func _is_clear(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= ROOM.size() or cell.x < 0 or cell.x >= ROOM[0].length():
		return false
	return ROOM[cell.y][cell.x] != "#"


func _explored_from(origin: Vector2i) -> Exploration:
	var exploration := Exploration.new()
	exploration.look_from(origin, _is_clear)
	return exploration


func test_open_floor_in_view_is_visible() -> void:
	assert_true(_explored_from(ORIGIN).is_visible(Vector2i(3, 3)))


func test_the_walls_bounding_the_view_are_visible_too() -> void:
	assert_true(_explored_from(ORIGIN).is_visible(Vector2i(4, 1)))


func test_what_is_behind_a_wall_stays_hidden() -> void:
	assert_false(_explored_from(ORIGIN).is_visible(Vector2i(6, 1)))


func test_cells_beyond_sight_range_are_not_visible() -> void:
	var exploration := Exploration.new()
	exploration.look_from(Vector2i.ZERO, func(_cell: Vector2i) -> bool: return true)

	assert_false(exploration.is_visible(Vector2i(Exploration.SIGHT_RADIUS + 1, 0)))


func test_cells_seen_before_are_remembered_after_moving_away() -> void:
	var exploration := _explored_from(ORIGIN)

	exploration.look_from(Vector2i(7, 1), _is_clear)

	assert_false(exploration.is_visible(Vector2i(2, 2)))
	assert_true(exploration.is_seen(Vector2i(2, 2)))


func test_cells_never_in_view_are_unknown() -> void:
	assert_false(_explored_from(ORIGIN).is_seen(Vector2i(6, 1)))


func test_the_player_sees_farther_than_any_weapon_reaches() -> void:
	var sight := Exploration.SIGHT_RADIUS * DungeonView.TILE_SIZE
	for weapon in GameTuning.weapons():
		assert_lt(weapon.aim_range(), float(sight), weapon.id)
