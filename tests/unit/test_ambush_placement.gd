extends GutTest
## Where an ambush arrives: at the edge of the fire's light, on ground the hero's side can walk, spread out.

const LIGHT := 2.5
const MARGIN := 1.5

var _plains: Array[DungeonMap] = []
var _crypts: Array[DungeonMap] = []


func before_all() -> void:
	for seed_value in 8:
		_plains.append(DungeonMapParser.new().parse(QuadrantGenerator.new().generate(QuadrantRecipe.plains(), seed_value)))
		_crypts.append(DungeonMapParser.new().parse(DungeonGenerator.new().generate(seed_value, 1)))


func _placed(map: DungeonMap, fire: Vector2i, lighting := 0, count := 3) -> Array[Vector2i]:
	return AmbushPlacement.cells(map, fire, LIGHT, MARGIN, count, Ambush.placement_rng(1, fire, lighting))


func test_the_ambushers_arrive_outside_the_light_but_near_its_edge() -> void:
	for map in _plains + _crypts:
		for fire in map.campfire_cells:
			for cell in _placed(map, fire):
				var apart := Vector2(cell - fire).length()
				assert_gte(apart, LIGHT + MARGIN, "outside the light")
				assert_lte(apart, LIGHT + MARGIN + AmbushPlacement.BAND_CELLS + AmbushPlacement.WIDEN_BY_CELLS)


func test_three_ambushers_find_room_at_every_campfire() -> void:
	for map in _plains + _crypts:
		for fire in map.campfire_cells:
			assert_eq(_placed(map, fire).size(), 3, "campfire %s" % fire)


func test_they_stand_on_safe_open_ground_and_apart() -> void:
	for map in _plains + _crypts:
		for fire in map.campfire_cells:
			var cells := _placed(map, fire)
			for cell in cells:
				assert_true(map.is_standable(cell))
				assert_false(map.is_door(cell))
			for i in cells.size():
				for j in range(i + 1, cells.size()):
					assert_gte(Vector2(cells[i] - cells[j]).length(), AmbushPlacement.MIN_APART_CELLS)


func test_the_same_lighting_places_them_in_the_same_cells() -> void:
	var map := _plains[0]
	var fire := map.campfire_cells[0]

	assert_eq(_placed(map, fire, 3), _placed(map, fire, 3))


func test_another_lighting_places_them_elsewhere() -> void:
	var map := _plains[0]
	var fire := map.campfire_cells[0]
	var seen := {}
	for lighting in 6:
		seen[_placed(map, fire, lighting)] = true

	assert_gt(seen.size(), 1)


func test_fewer_ambushers_come_when_the_ground_has_no_room() -> void:
	var rows := PackedStringArray([
		"#P........#",
		"#.........#",
		"#.........#",
		"#.........#",
		"###########",
	])
	var map := DungeonMapParser.new().parse("\n".join(rows))

	assert_eq(AmbushPlacement.cells(map, Vector2i(1, 2), 0.5, 0.5, 3, RandomNumberGenerator.new()).size(), 3)
	assert_eq(AmbushPlacement.cells(map, Vector2i(5, 2), 8.0, 1.0, 3, RandomNumberGenerator.new()).size(), 0,
		"no ground that far from the fire")
