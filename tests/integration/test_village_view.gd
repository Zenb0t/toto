extends GutTest
## How the village stands in the 3D view: buildings, palisade, well and props are models; one that stands between
## the camera (south of the hero, toward the bottom of the screen) and the hero turns see-through.

var _map: DungeonMap
var _view: MapView3D


func before_each() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	_map = DungeonMapParser.new().parse(VillageGenerator.new().generate(Vector2i(36, 28), 0.15, rng).ascii())
	_view = autofree(MapView3D.new())
	var walls: Array[Vector2i] = []
	for y in _map.size.y:
		for x in _map.size.x:
			if not _map.is_open(Vector2i(x, y)) and _has_open_neighbour(Vector2i(x, y)):
				walls.append(Vector2i(x, y))
	_view.show_map(_map, walls, BranchLook.plains())


func _has_open_neighbour(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _map.is_open(cell + Vector2i(dx, dy)):
				return true
	return false


func _inn() -> Village.Building:
	return _map.village.building_of(Village.Kind.INN)


func test_buildings_the_palisade_the_well_and_props_are_models_not_wall_blocks() -> void:
	assert_true(_view.has_village_piece(_inn().rect.get_center()))
	assert_true(_view.has_village_piece(_map.village.well_cell))
	assert_true(_view.has_village_piece(Vector2i(0, 0)), "the palisade")
	assert_true(_view.has_village_piece(_map.cells_with_blocker(DungeonMap.Blocker.PROP)[0]))
	assert_false(_view.has_village_piece(_map.player_spawn))


func test_a_building_between_the_camera_and_the_hero_turns_see_through() -> void:
	var inn := _inn()
	var hero_north_of_it := Vector2i(inn.rect.get_center().x, inn.rect.position.y - 1)

	_view.show_hero_at(hero_north_of_it)

	assert_true(_view.is_see_through(inn.rect.get_center()))


func test_a_building_the_hero_stands_in_front_of_stays_solid() -> void:
	var inn := _inn()
	var hero_south_of_it := Vector2i(inn.rect.get_center().x, inn.rect.end.y + 1)

	_view.show_hero_at(hero_south_of_it)

	assert_false(_view.is_see_through(inn.rect.get_center()))


func test_a_building_turns_solid_again_when_the_hero_walks_out_from_behind_it() -> void:
	var inn := _inn()
	_view.show_hero_at(Vector2i(inn.rect.get_center().x, inn.rect.position.y - 1))

	_view.show_hero_at(Vector2i(inn.rect.get_center().x, inn.rect.end.y + 1))

	assert_false(_view.is_see_through(inn.rect.get_center()))


func test_a_tall_building_hides_the_hero_from_farther_off_than_a_wall_does() -> void:
	var inn := _inn()
	var far_north := Vector2i(inn.rect.get_center().x, inn.rect.position.y - 4)

	_view.show_hero_at(far_north)

	assert_true(_view.is_see_through(inn.rect.get_center()), "the inn is 8 cells deep and tall")
	assert_false(CameraFraming.cells_hiding(far_north).has(inn.rect.position + Vector2i(0, 1)),
		"a wall that far off would not be cut down")


func test_the_palisade_in_front_of_the_hero_turns_see_through_too() -> void:
	var south_wall := Vector2i(0, _map.village.area.end.y - 1)
	_view.show_hero_at(south_wall + Vector2i(0, -2))

	assert_true(_view.is_see_through(south_wall))


func test_barrels_and_crates_are_too_low_to_hide_the_hero() -> void:
	var prop: Vector2i = _map.cells_with_blocker(DungeonMap.Blocker.PROP)[0]

	_view.show_hero_at(prop + Vector2i(0, -1))

	assert_false(_view.is_see_through(prop))
