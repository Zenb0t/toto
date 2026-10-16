extends GutTest
## Guards the hand-made playtest dungeon against layout mistakes.

var _map: DungeonMap


func before_each() -> void:
	_map = DungeonMapParser.new().parse(TestDungeon.LAYOUT)


func _enemy_rooms() -> Array[int]:
	var rooms: Array[int] = []
	for spawn in _map.enemy_spawns:
		rooms.append(_map.room_at(spawn))
	return rooms


func test_player_starts_in_a_room_without_enemies() -> void:
	assert_does_not_have(_enemy_rooms(), _map.room_at(_map.player_spawn))


func test_every_other_room_has_enemies_to_fight() -> void:
	var start_room := _map.room_at(_map.player_spawn)
	for room in _map.room_count:
		if room != start_room:
			assert_has(_enemy_rooms(), room, "room %d" % room)


func test_every_room_can_be_reached_from_the_start() -> void:
	var reached := {_map.player_spawn: true}
	var frontier: Array[Vector2i] = [_map.player_spawn]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if _map.is_walkable(next) and not reached.has(next):
				reached[next] = true
				frontier.append(next)

	assert_eq(reached.size(), _map.walkable_cells().size())


func test_every_room_has_at_least_one_door() -> void:
	for room in _map.room_count:
		assert_false(_map.doors_of_room(room).is_empty(), "room %d" % room)
