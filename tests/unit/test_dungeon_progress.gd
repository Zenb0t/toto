extends GutTest

const ROOM_A := 0
const ROOM_B := 1
const EMPTY_ROOM := 2


func _progress() -> DungeonProgress:
	return DungeonProgress.new({ROOM_A: 2, ROOM_B: 1})


func test_entering_a_room_with_enemies_locks_it() -> void:
	var progress := _progress()
	watch_signals(progress)

	progress.enter_room(ROOM_A)

	assert_eq(progress.locked_room, ROOM_A)
	assert_signal_emitted_with_parameters(progress, "room_locked", [ROOM_A])


func test_entering_a_room_without_enemies_does_not_lock() -> void:
	var progress := _progress()

	progress.enter_room(EMPTY_ROOM)

	assert_eq(progress.locked_room, DungeonProgress.NO_ROOM)


func test_cannot_lock_a_second_room_while_one_is_locked() -> void:
	var progress := _progress()
	progress.enter_room(ROOM_A)

	progress.enter_room(ROOM_B)

	assert_eq(progress.locked_room, ROOM_A)


func test_room_stays_locked_until_its_last_enemy_falls() -> void:
	var progress := _progress()
	progress.enter_room(ROOM_A)

	progress.record_defeat(ROOM_A)
	assert_eq(progress.locked_room, ROOM_A)

	progress.record_defeat(ROOM_A)
	assert_eq(progress.locked_room, DungeonProgress.NO_ROOM)


func test_clearing_a_room_announces_it() -> void:
	var progress := _progress()
	watch_signals(progress)
	progress.enter_room(ROOM_B)

	progress.record_defeat(ROOM_B)

	assert_signal_emitted_with_parameters(progress, "room_cleared", [ROOM_B])
	assert_signal_not_emitted(progress, "dungeon_cleared")


func test_cleared_rooms_never_lock_again() -> void:
	var progress := _progress()
	progress.enter_room(ROOM_B)
	progress.record_defeat(ROOM_B)

	progress.enter_room(ROOM_B)

	assert_eq(progress.locked_room, DungeonProgress.NO_ROOM)


func test_defeating_every_enemy_clears_the_dungeon() -> void:
	var progress := _progress()
	watch_signals(progress)

	progress.record_defeat(ROOM_A)
	progress.record_defeat(ROOM_A)
	progress.record_defeat(ROOM_B)

	assert_signal_emit_count(progress, "dungeon_cleared", 1)
	assert_eq(progress.total_enemies_left(), 0)


func test_extra_defeats_in_a_cleared_room_are_ignored() -> void:
	var progress := _progress()
	progress.record_defeat(ROOM_B)

	progress.record_defeat(ROOM_B)

	assert_eq(progress.enemies_left_in(ROOM_B), 0)
	assert_eq(progress.total_enemies_left(), 2)
