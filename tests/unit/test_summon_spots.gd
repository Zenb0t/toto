extends GutTest
## Where Summon Undead raises skeletons: in the Lich's arena, within the summon range, between him and the hero, on
## floor a skeleton can stand on. Checked on many generated arenas through the real map parser.

const SEEDS := 40
const RANGE := 6.0

var _arenas: Array[DungeonMap] = []


func before_all() -> void:
	for seed_value in SEEDS:
		_arenas.append(DungeonMapParser.new().parse(DungeonGenerator.new().generate(seed_value, WorldLayout.FLOOR_COUNT)))


func _lich_cell(map: DungeonMap) -> Vector2i:
	for spawn in map.enemy_spawns:
		if map.monster_at(spawn) == Lich.ID:
			return spawn
	return DungeonMap.NO_CELL


## An arena cell about distance cells from the Lich, or NO_CELL.
func _hero_cell(map: DungeonMap, distance: float) -> Vector2i:
	var lich := _lich_cell(map)
	for cell in map.cells_of_room(map.room_at(lich)):
		if absf(Vector2(cell - lich).length() - distance) < 0.5 and map.is_standable(cell):
			return cell
	return DungeonMap.NO_CELL


func _spots(map: DungeonMap, hero: Vector2i, count := 3, taken: Array[Vector2i] = [], seed_value := 1) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return SummonSpots.spots(map, _lich_cell(map), hero, RANGE, count, taken, rng)


func test_spots_lie_within_the_summon_range_of_the_lich() -> void:
	for map in _arenas:
		var hero := _hero_cell(map, 8.0)
		for spot in _spots(map, hero, 5):
			assert_lte(Vector2(spot - _lich_cell(map)).length(), RANGE)


func test_spots_lie_between_the_lich_and_the_hero() -> void:
	for map in _arenas:
		var lich := _lich_cell(map)
		var hero := _hero_cell(map, 8.0)
		var line := Vector2(hero - lich).normalized()
		for spot in _spots(map, hero, 5):
			var along := Vector2(spot - lich).dot(line)
			assert_gt(along, 0.0, "in front of him")
			assert_lt(along, Vector2(hero - lich).length(), "short of the hero")


func test_spots_are_floor_in_the_arena_never_a_wall_pillar_or_doorway() -> void:
	for map in _arenas:
		var arena := map.room_at(_lich_cell(map))
		for spot in _spots(map, _hero_cell(map, 8.0), 5):
			assert_true(map.is_standable(spot))
			assert_false(map.is_door(spot))
			assert_eq(map.room_at(spot), arena)


func test_spots_are_apart_and_off_the_caster_and_the_hero() -> void:
	for map in _arenas:
		var lich := _lich_cell(map)
		var hero := _hero_cell(map, 8.0)
		var spots := _spots(map, hero, 5)
		for i in spots.size():
			assert_gte(Vector2(spots[i] - lich).length(), SummonSpots.MIN_FROM_CASTER_CELLS)
			assert_gte(Vector2(spots[i] - hero).length(), SummonSpots.MIN_FROM_HERO_CELLS)
			for j in range(i + 1, spots.size()):
				assert_gte(Vector2(spots[i] - spots[j]).length(), SummonSpots.MIN_APART_CELLS)


func test_cells_already_taken_are_not_used() -> void:
	var map := _arenas[0]
	var hero := _hero_cell(map, 8.0)
	var first := _spots(map, hero, 5)

	var second := _spots(map, hero, 5, first)

	for spot in second:
		assert_does_not_have(first, spot)


func test_the_arena_has_room_for_a_full_summon() -> void:
	for map in _arenas:
		assert_eq(_spots(map, _hero_cell(map, 8.0), 3).size(), 3)


func test_the_same_seed_gives_the_same_spots_and_other_seeds_other_ones() -> void:
	var map := _arenas[0]
	var hero := _hero_cell(map, 8.0)
	var seen := {}
	for seed_value in 8:
		assert_eq(_spots(map, hero, 3, [], seed_value), _spots(map, hero, 3, [], seed_value))
		seen[_spots(map, hero, 3, [], seed_value)] = true

	assert_gt(seen.size(), 1)


func test_when_none_are_asked_for_none_are_given() -> void:
	var map := _arenas[0]

	assert_eq(_spots(map, _hero_cell(map, 8.0), 0).size(), 0)
