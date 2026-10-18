extends GutTest
## Warp, the playtest aid: the run owner moves the hero to any place of the slice by the same rule as an exit, and
## the hero lands on walkable ground, checked on generated worlds through the real map parser.

const WORLDS := 6

var _parser := DungeonMapParser.new()


func _hero_holding(kills: int) -> HeroState:
	return HeroState.carrying("sword", "blink", Health.restored(1400, 400), {"haste": 2}, 3000, kills)


## The map the run is on and the cell the hero lands on after warping to a place.
func _landing(run: Run, target_id: String) -> Dictionary:
	run.warp(Warp.target(target_id), run.hero)
	var map := _parser.parse(run.current_map().ascii())
	return {"map": map, "cell": WorldLayout.arrival_cell(map, run.arrival_spot)}


func test_the_places_to_warp_to_are_the_village_the_ruin_the_crypt_entrance_each_level_and_the_arena() -> void:
	var ids: Array[String] = []
	for each in Warp.targets():
		ids.append(each.id)

	assert_eq(ids, [
		Warp.VILLAGE, Warp.RUIN, Warp.CRYPT_ENTRANCE, Warp.level_id(1), Warp.level_id(2), Warp.level_id(3), Warp.ARENA])


func test_warping_puts_the_hero_on_the_map_of_the_place() -> void:
	var run := Run.new(5)
	var expected := {
		Warp.VILLAGE: WorldLayout.PLAINS_ID, Warp.RUIN: WorldLayout.PLAINS_ID,
		Warp.CRYPT_ENTRANCE: WorldLayout.PLAINS_ID, Warp.level_id(1): WorldLayout.floor_id(1),
		Warp.level_id(2): WorldLayout.floor_id(2), Warp.level_id(3): WorldLayout.floor_id(3),
		Warp.ARENA: WorldLayout.floor_id(3)}

	for target_id: String in expected:
		run.warp(Warp.target(target_id), run.hero)
		assert_eq(run.current_map_id, expected[target_id], target_id)


func test_the_hero_lands_on_walkable_ground_at_every_place_of_many_worlds() -> void:
	for world_seed in WORLDS:
		var run := Run.new(world_seed)
		for each in Warp.targets():
			var landing := _landing(run, each.id)
			var map: DungeonMap = landing.map
			assert_true(map.is_standable(landing.cell), "world %d, %s" % [world_seed, each.id])


func test_the_village_is_by_the_inn_where_the_run_starts() -> void:
	var landing := _landing(Run.new(3), Warp.VILLAGE)
	var map: DungeonMap = landing.map

	assert_eq(landing.cell, map.player_spawn)
	assert_true(map.is_in_village(landing.cell))


func test_the_ruin_landing_is_beside_the_chest_and_not_on_it() -> void:
	for world_seed in WORLDS:
		var landing := _landing(Run.new(world_seed), Warp.RUIN)
		var map: DungeonMap = landing.map
		var cell: Vector2i = landing.cell

		assert_ne(cell, map.ruin_cell, "world %d" % world_seed)
		assert_lte(Vector2(cell).distance_to(Vector2(map.ruin_cell)), 3.0, "world %d" % world_seed)


func test_the_crypt_entrance_and_each_level_land_on_the_stairs_the_hero_would_arrive_by() -> void:
	var run := Run.new(9)

	var entrance := _landing(run, Warp.CRYPT_ENTRANCE)
	assert_eq(entrance.cell, (entrance.map as DungeonMap).exit_cell)
	for floor_number in range(1, WorldLayout.FLOOR_COUNT + 1):
		var level := _landing(run, Warp.level_id(floor_number))
		assert_eq(level.cell, (level.map as DungeonMap).stairs_up_cell, "level %d" % floor_number)


func test_the_arena_landing_is_outside_the_arena_next_to_its_door_so_walking_in_still_locks_it() -> void:
	for world_seed in WORLDS:
		var landing := _landing(Run.new(world_seed), Warp.ARENA)
		var map: DungeonMap = landing.map
		var cell: Vector2i = landing.cell
		var arena := map.locking_room_of_kind(LockingRoom.Kind.ARENA)
		var doors := map.doors_of_room(arena)

		assert_ne(map.room_at(cell), arena, "world %d: not inside the arena" % world_seed)
		assert_true(
			doors.any(func(door: Vector2i) -> bool: return door.distance_squared_to(cell) == 1),
			"world %d: next to a door of the arena" % world_seed)


func test_warping_keeps_what_the_hero_carries() -> void:
	var run := Run.new(7)

	run.warp(Warp.target(Warp.level_id(2)), _hero_holding(12))

	assert_eq(run.hero.weapon_id, "sword")
	assert_eq(run.hero.health, 400)
	assert_eq(run.hero.max_health, 1400)
	assert_eq(run.hero.potions, {"haste": 2})
	assert_eq(run.hero.experience, 3000)
	assert_eq(run.hero.kills, 12)


func test_warping_keeps_every_map_record_and_the_world() -> void:
	var run := Run.new(7)
	var world_seed := run.world_seed
	var arena := WorldLayout.floor_id(WorldLayout.FLOOR_COUNT)
	run.record_of(WorldLayout.PLAINS_ID).open_chest(4)
	run.warp(Warp.target(Warp.ARENA), run.hero)
	run.lich_killed()

	run.warp(Warp.target(Warp.VILLAGE), run.hero)

	assert_eq(run.world_seed, world_seed)
	assert_true(run.won)
	assert_true(run.record_of(arena).is_lich_dead())
	assert_true(run.record_of(WorldLayout.PLAINS_ID).is_chest_opened(4))
