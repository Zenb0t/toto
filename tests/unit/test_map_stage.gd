extends GutTest
## A map's stage starts out knowing what the hero knows from the start: a village is home, so all of it is explored,
## and the woods of the plains are landmarks seen from afar.


func _plains_stage(world_seed: int) -> MapStage:
	return autofree(MapStage.new(WorldLayout.spec(world_seed, WorldLayout.PLAINS_ID)))


func test_a_new_run_starts_by_the_inn_with_the_whole_village_already_explored() -> void:
	for world_seed in 4:
		var stage := _plains_stage(world_seed)
		var arrival := WorldLayout.arrival_cell(stage.map, WorldLayout.Spot.START)

		var step := (arrival - stage.map.village.inn_doorstep).abs()
		assert_eq(step.x + step.y, 1, "the hero starts right by the inn's doorstep, world %d" % world_seed)
		for cell in stage.map.village.cells():
			assert_true(stage.exploration.is_seen(cell), "world %d cell %s" % [world_seed, cell])


func test_the_plains_outside_the_village_are_not_explored_yet() -> void:
	var stage := _plains_stage(1)

	assert_false(stage.exploration.is_seen(stage.map.village.area.position - Vector2i(3, 3)))


func test_a_dungeon_floor_starts_unexplored() -> void:
	var stage: MapStage = autofree(MapStage.new(WorldLayout.spec(1, WorldLayout.floor_id(1))))

	assert_eq(stage.exploration.seen_cells().size(), 0)


func test_the_woods_of_the_plains_are_known_from_the_start() -> void:
	var stage := _plains_stage(2)

	for cell in stage.map.cells_with_blocker(DungeonMap.Blocker.GROVE):
		assert_true(stage.exploration.is_seen(cell), str(cell))


func test_the_hero_sees_farther_on_the_plains_than_in_the_crypt() -> void:
	var plains := _plains_stage(1)
	var crypt: MapStage = autofree(MapStage.new(WorldLayout.spec(1, WorldLayout.floor_id(1))))

	assert_gt(plains.exploration.sight_radius, crypt.exploration.sight_radius)
