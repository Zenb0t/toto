extends GutTest
## The boss arena and the Lich with real actor scenes: the arena locks when the hero walks in and opens when the
## Lich dies; he keeps his distance, casts one spell at a time with a pause, and never gives up.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const CELL := DungeonView.TILE_SIZE

var _fired := 0


func before_each() -> void:
	_fired = 0


func _hero_at(position: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = position
	add_child_autofree(player)
	return player


## The Lich as the game builds him: his Cloud, his spell rule and the distance he keeps. He starts at the origin.
func _lich(spells := SpellPicker.new()) -> Enemy:
	var lich := Lich.new()
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.become(lich.monster())
	enemy.arm(GameTuning.monster_weapon(GameTuning.create(), lich.monster()))
	enemy.spell_picker = spells
	enemy.keep_distance_cells = lich.keep_distance_cells
	enemy.never_gives_up = true
	enemy.attack_fired.connect(func(_attacks: Array) -> void: _fired += 1)
	add_child_autofree(enemy)
	return enemy


func _arena() -> DungeonMap:
	return DungeonMapParser.new().parse(DungeonGenerator.new().generate(4, WorldLayout.FLOOR_COUNT))


func _progress_of(map: DungeonMap) -> DungeonProgress:
	var counts := {}
	for cell in map.enemy_spawns:
		counts[map.room_at(cell)] = counts.get(map.room_at(cell), 0) + 1
	return DungeonProgress.new(counts, map.locking_room_ids())


func _arena_cell_clear_of_doors(map: DungeonMap) -> Vector2i:
	for cell in map.cells_of_room(map.locking_room_of_kind(LockingRoom.Kind.ARENA)):
		if map.is_clear_of_doors(cell):
			return cell
	return DungeonMap.NO_CELL


func test_walking_into_the_arena_locks_it_and_other_rooms_stay_open() -> void:
	var map := _arena()
	var progress := _progress_of(map)
	var arena := map.locking_room_of_kind(LockingRoom.Kind.ARENA)
	var locked: Array[int] = []
	progress.room_locked.connect(locked.append)

	for room in map.room_count:
		if room != arena:
			progress.enter_room(room)
	assert_eq(progress.locked_room, DungeonProgress.NO_ROOM, "no ordinary room locks")
	progress.enter_room(map.room_at(_arena_cell_clear_of_doors(map)))

	assert_eq(progress.locked_room, arena)
	assert_eq(locked, [arena])


func test_the_lich_dying_opens_the_arena() -> void:
	var map := _arena()
	var progress := _progress_of(map)
	var arena := map.locking_room_of_kind(LockingRoom.Kind.ARENA)
	progress.enter_room(arena)
	var lich := _lich()
	lich.defeated.connect(func(_dead: Enemy) -> void: progress.record_defeat(arena))
	var opened: Array[int] = []
	progress.room_cleared.connect(opened.append)
	assert_eq(progress.locked_room, arena)

	lich.take_damage(lich.health.maximum)

	assert_eq(progress.locked_room, DungeonProgress.NO_ROOM)
	assert_eq(opened, [arena])


func test_the_lich_backs_away_from_a_hero_who_comes_close() -> void:
	var hero := _hero_at(Vector2(3 * CELL, 0))
	var lich := _lich()
	lich.chase(hero)

	await wait_seconds(1.5)

	assert_lt(lich.position.x, -20.0, "he steps away from the hero, after the cast he began")


func test_the_lich_closes_in_on_a_hero_who_is_far_away() -> void:
	var hero := _hero_at(Vector2(20 * CELL, 0))
	var lich := _lich()
	lich.chase(hero)

	await wait_seconds(0.5)

	assert_gt(lich.position.x, 5.0)


func test_the_lich_casts_one_spell_and_the_pause_holds_before_the_next() -> void:
	var spells := SpellPicker.new()
	spells.pause_seconds = 5.0
	var hero := _hero_at(Vector2(8 * CELL, 0))
	var lich := _lich(spells)
	lich.chase(hero)

	await wait_seconds(2.5)

	assert_eq(_fired, 1, "one cast, and the pause has not run out")
	assert_false(spells.is_ready())


func test_with_a_short_pause_the_lich_keeps_casting() -> void:
	var spells := SpellPicker.new()
	spells.pause_seconds = 0.2
	var hero := _hero_at(Vector2(8 * CELL, 0))
	var lich := _lich(spells)
	lich.chase(hero)

	await wait_seconds(3.0)

	assert_gt(_fired, 1)


func test_a_lich_who_has_not_been_woken_ignores_the_hero_until_his_room_locks() -> void:
	var hero := _hero_at(Vector2(6 * CELL, 0))
	var lich := _lich()
	lich.settle(Vector2.ZERO, Band.start_of(1, 0, 0.0, true))

	await wait_seconds(1.0)
	assert_eq(_fired, 0, "he does not cast before the room locks")

	lich.wake(hero)
	await wait_seconds(1.5)

	assert_gt(_fired, 0, "once it has locked he attacks")


func test_the_lich_never_gives_up_however_far_the_hero_gets_from_his_home() -> void:
	var hero := _hero_at(Vector2(40 * CELL, 0))
	var lich := _lich()
	lich.settle(Vector2.ZERO, Band.Start.WANDERING)
	lich.wake(hero)

	await wait_seconds(Awareness.DEFAULT_GIVE_UP_SECONDS + 2.0)

	assert_gt(lich.position.x, 6.0 * CELL, "he is still coming for the hero, not walking home")
