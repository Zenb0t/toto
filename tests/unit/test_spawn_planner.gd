extends GutTest

const SEED := 99
const PER_ROOM := 2

var _layout: DungeonLayout
var _planner := SpawnPlanner.new()


func before_each() -> void:
	_layout = DungeonGenerator.new().generate(SEED)


func test_plans_the_requested_number_of_enemies_for_every_room_except_the_first() -> void:
	var cells := _planner.plan_enemy_cells(_layout, SEED, PER_ROOM)

	assert_eq(cells.size(), (_layout.rooms.size() - 1) * PER_ROOM)


func test_never_spawns_enemies_in_the_players_starting_room() -> void:
	var start_room := _layout.rooms[0]

	for cell in _planner.plan_enemy_cells(_layout, SEED, PER_ROOM):
		assert_false(start_room.has_point(cell))


func test_every_enemy_spawns_on_a_floor_cell() -> void:
	for cell in _planner.plan_enemy_cells(_layout, SEED, PER_ROOM):
		assert_true(_layout.is_floor(cell))


func test_same_seed_plans_the_same_spawns() -> void:
	assert_eq(
		_planner.plan_enemy_cells(_layout, SEED, PER_ROOM),
		_planner.plan_enemy_cells(_layout, SEED, PER_ROOM),
	)
