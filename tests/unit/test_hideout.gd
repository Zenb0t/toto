extends GutTest
## Where the Lich hides when hurt before the arena locks: out of sight of every doorway of the arena, on many
## generated crypts, through the real map parser.

const SEEDS := 40
const LAST := WorldLayout.FLOOR_COUNT

var _parser := DungeonMapParser.new()


func _level(seed_value: int, level := LAST) -> DungeonMap:
	return _parser.parse(DungeonGenerator.new().generate(seed_value, level))


func _lich_cell(map: DungeonMap) -> Vector2i:
	for spawn in map.enemy_spawns:
		if map.monster_at(spawn) == Lich.ID:
			return spawn
	return DungeonMap.NO_CELL


## Seeds whose arena once left him nowhere to hide: linked above and below, so a corridor came into the back of the
## crypt (28, 729), or with doorways high up the side walls that looked across the crypt's mouth into a nook (716, 1241).
const AWKWARD_SEEDS: Array[int] = [28, 716, 729, 1241]


func _seeds() -> Array[int]:
	var seeds: Array[int] = []
	for seed_value in SEEDS:
		seeds.append(seed_value)
	seeds.append_array(AWKWARD_SEEDS)
	return seeds


func test_on_many_seeds_no_doorway_of_the_arena_can_see_the_hideout() -> void:
	for seed_value in _seeds():
		var map := _level(seed_value)
		var room := map.locking_room_of_kind(LockingRoom.Kind.ARENA)
		var hideout := Hideout.cell_for(map, _lich_cell(map))

		assert_ne(hideout, DungeonMap.NO_CELL, "seed %d has a hideout" % seed_value)
		assert_eq(map.room_at(hideout), room, "seed %d: it lies inside the arena" % seed_value)
		assert_false(Hideout.is_seen_from_doorways(map, room, hideout), "seed %d: hidden from the doors" % seed_value)


func test_the_hideout_is_in_the_back_row_of_his_crypt_on_every_seed() -> void:
	for seed_value in _seeds():
		var map := _level(seed_value)
		var lich := _lich_cell(map)
		var hideout := Hideout.cell_for(map, lich)

		assert_eq(absi(hideout.y - lich.y), 1, "seed %d: the back row of his crypt, a nook beside him" % seed_value)
		assert_lte(absi(hideout.x - lich.x), BossArena.CRYPT_SIZE.x / 2 + BossArena.NOOK_WIDTH, "seed %d" % seed_value)


func test_a_level_without_an_arena_has_no_hideout() -> void:
	assert_eq(Hideout.cell_for(_level(3, 1), Vector2i.ZERO), DungeonMap.NO_CELL)


func test_a_cell_in_the_open_hall_is_seen_from_the_doorways() -> void:
	var map := _level(5)
	var room := map.locking_room_of_kind(LockingRoom.Kind.ARENA)
	var hall_middle := DungeonMap.NO_CELL
	for cell in map.cells_of_room(room):
		if map.is_clear_of_doors(cell) and map.monster_at(cell) == "":
			hall_middle = cell
	var seen := false
	for cell in map.cells_of_room(room):
		seen = seen or Hideout.is_seen_from_doorways(map, room, cell)

	assert_true(seen, "the check does see into the hall, so a hidden cell is meaningful (%s)" % hall_middle)
