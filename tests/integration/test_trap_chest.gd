extends GutTest
## A trap room with real nodes: entering seals it, its chest stays shut and ignores the hero until the band is dead,
## and then opens to them.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var _map: DungeonMap
var _progress: DungeonProgress
var _room: int
var _opened := 0


func before_each() -> void:
	_opened = 0
	_map = DungeonMapParser.new().parse("""
#########
#<......#
#.......#
#...R...#
#...k...#
#.......#
#########
""".strip_edges())
	_room = _map.room_at(Vector2i(4, 3))
	_progress = DungeonProgress.new({_room: 2}, _map.locking_room_ids())


func _chest_and_hero(locked: bool) -> Chest:
	var chest := Chest.new(false, locked)
	chest.position = DungeonView.cell_center(_map.room_center(_room))
	chest.opened.connect(func() -> void: _opened += 1)
	add_child_autofree(chest)
	var hero: Player = PLAYER_SCENE.instantiate()
	hero.position = chest.position
	add_child_autofree(hero)
	return chest


func test_entering_the_marked_room_seals_it() -> void:
	_progress.enter_room(_room)

	assert_eq(_progress.locked_room, _room)


func test_a_locked_chest_stays_shut_under_the_hero() -> void:
	var chest := _chest_and_hero(true)

	await wait_physics_frames(5)

	assert_false(chest.is_open())
	assert_eq(_opened, 0)


func test_the_chest_opens_only_after_the_last_enemy_dies() -> void:
	var chest := _chest_and_hero(true)
	_progress.room_cleared.connect(func(_cleared: int) -> void: chest.unlock())
	_progress.enter_room(_room)
	await wait_physics_frames(3)

	_progress.record_defeat(_room)
	await wait_physics_frames(3)
	assert_false(chest.is_open(), "one of the band is still alive")

	_progress.record_defeat(_room)
	await wait_physics_frames(3)
	assert_true(chest.is_open())
	assert_eq(_opened, 1)


func test_what_comes_out_is_a_gear_piece_the_hero_does_not_hold() -> void:
	var held: Array[String] = [GameTuning.weapon_ids()[0], GameTuning.utility_ids()[0]]
	var rng := RandomNumberGenerator.new()
	for seed_value in 30:
		rng.seed = seed_value
		assert_does_not_have(held, LootTable.pick_item_id(GameTuning.item_ids(), held, rng))


func test_a_chest_of_a_room_cleared_on_an_earlier_visit_opens_at_once() -> void:
	var chest := _chest_and_hero(false)

	await wait_physics_frames(3)

	assert_true(chest.is_open())
