extends GutTest
## A map's record, ready for save games: it goes through a plain dictionary (and JSON) unchanged.


func _filled_record() -> MapRecord:
	var record := MapRecord.new(DungeonGenerator.VERSION)
	record.kill(Vector2i(10, 4))
	record.kill(Vector2i(12, 6))
	record.open_chest(3)
	record.take_loot(Vector2i(30, 12))
	var explored: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]
	record.remember_explored(explored)
	var dropped: Array[MapRecord.DroppedItem] = [
		MapRecord.DroppedItem.new("sword", false, Vector2(100, 60)),
		MapRecord.DroppedItem.new("healing", true, Vector2(130.5, 64.25)),
	]
	record.remember_dropped(dropped)
	record.remember_hurt({Vector2i(40, 20): 250, Vector2i(41, 22): 30}, 75.5)
	return record


func test_a_record_round_trips_through_a_dictionary_unchanged() -> void:
	var record := _filled_record()

	var again := MapRecord.from_dict(record.to_dict())

	assert_eq_deep(again.to_dict(), record.to_dict())


func test_a_record_read_back_from_json_says_the_same_things() -> void:
	var record := _filled_record()

	var again := MapRecord.from_dict(JSON.parse_string(JSON.stringify(record.to_dict())))

	assert_eq(again.generator_version, DungeonGenerator.VERSION)
	assert_true(again.is_killed(Vector2i(12, 6)))
	assert_true(again.is_chest_opened(3))
	assert_true(again.is_loot_taken(Vector2i(30, 12)))
	assert_eq(again.explored_cells(), record.explored_cells())
	assert_eq(again.dropped_items()[1].item_id, "healing")
	assert_true(again.dropped_items()[1].is_potion)
	assert_eq(again.dropped_items()[1].position, Vector2(130.5, 64.25))
	assert_eq(again.health_on_return(Vector2i(41, 22), 900, 75.5, 10.0), 30)
	assert_eq_deep(again.to_dict(), record.to_dict())


func test_an_empty_record_round_trips_too() -> void:
	var record := MapRecord.new(DungeonGenerator.VERSION)

	assert_eq_deep(MapRecord.from_dict(record.to_dict()).to_dict(), record.to_dict())


func test_a_killed_monster_is_no_longer_hurt() -> void:
	var record := MapRecord.new(DungeonGenerator.VERSION)
	record.remember_hurt({Vector2i(10, 4): 100}, 0.0)

	record.kill(Vector2i(10, 4))

	assert_eq(record.to_dict().hurt, [])
