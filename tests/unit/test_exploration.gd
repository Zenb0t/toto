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


func test_cells_seen_on_an_earlier_visit_are_remembered_after_restoring() -> void:
	var earlier := _explored_from(ORIGIN)

	var again := Exploration.new()
	again.restore(earlier.seen_cells())

	assert_true(again.is_seen(Vector2i(3, 3)))
	assert_false(again.is_visible(Vector2i(3, 3)), "remembered, not in view")
	assert_false(again.is_seen(Vector2i(7, 1)), "never seen before")


func test_restored_cells_stay_remembered_after_looking_again() -> void:
	var earlier := _explored_from(ORIGIN)
	var again := Exploration.new()
	again.restore(earlier.seen_cells())

	again.look_from(Vector2i(7, 1), _is_clear)

	assert_true(again.is_seen(Vector2i(1, 1)))
	assert_true(again.is_seen(Vector2i(7, 1)))


func test_cells_never_in_view_are_unknown() -> void:
	assert_false(_explored_from(ORIGIN).is_seen(Vector2i(6, 1)))


func test_the_player_sees_farther_than_any_weapon_reaches() -> void:
	var sight := Exploration.SIGHT_RADIUS * DungeonView.TILE_SIZE
	for weapon in GameTuning.weapons():
		assert_lt(weapon.aim_range(), float(sight), weapon.id)


func test_a_first_look_reports_every_cell_it_brings_into_view() -> void:
	var exploration := _explored_from(ORIGIN)

	var changed := exploration.changed_cells()

	assert_true(changed.has(Vector2i(3, 3)))
	assert_true(changed.has(ORIGIN))
	assert_false(changed.has(Vector2i(6, 1)), "never in view")


func test_a_step_reports_the_cells_that_came_into_view_and_those_that_left_it() -> void:
	var exploration := _explored_from(ORIGIN)

	exploration.look_from(Vector2i(7, 1), _is_clear)

	var changed := exploration.changed_cells()
	assert_true(changed.has(Vector2i(6, 1)), "came into view")
	assert_true(changed.has(Vector2i(2, 2)), "left it")


func test_cells_still_in_view_after_a_step_are_not_reported() -> void:
	var exploration := Exploration.new()
	var clear := func(_cell: Vector2i) -> bool: return true
	exploration.look_from(Vector2i.ZERO, clear)

	exploration.look_from(Vector2i(1, 0), clear)

	assert_false(exploration.changed_cells().has(Vector2i(5, 0)))


func test_a_step_reports_exactly_the_cells_that_look_different() -> void:
	var exploration := _explored_from(ORIGIN)
	var before := _states(exploration)

	exploration.look_from(Vector2i(6, 3), _is_clear)

	var after := _states(exploration)
	var changed := exploration.changed_cells()
	for cell: Vector2i in after:
		assert_eq(changed.has(cell), before[cell] != after[cell], str(cell))


func test_a_look_from_the_same_cell_again_reports_nothing() -> void:
	var exploration := _explored_from(ORIGIN)

	exploration.look_from(ORIGIN, _is_clear)

	assert_eq(exploration.changed_cells().size(), 0)


## What every cell of ROOM (and a ring round it) looks like: 0 unknown, 1 remembered, 2 in view.
func _states(exploration: Exploration) -> Dictionary:
	var states := {}
	for y in range(-1, ROOM.size() + 1):
		for x in range(-1, ROOM[0].length() + 1):
			var cell := Vector2i(x, y)
			states[cell] = 2 if exploration.is_visible(cell) else (1 if exploration.is_seen(cell) else 0)
	return states


func test_a_wider_sight_sees_farther() -> void:
	var exploration := Exploration.new()
	exploration.sight_radius = Exploration.OUTDOOR_SIGHT_RADIUS

	exploration.look_from(Vector2i.ZERO, func(_cell: Vector2i) -> bool: return true)

	assert_true(exploration.is_visible(Vector2i(Exploration.OUTDOOR_SIGHT_RADIUS, 0)))
	assert_false(exploration.is_visible(Vector2i(Exploration.OUTDOOR_SIGHT_RADIUS + 1, 0)))
