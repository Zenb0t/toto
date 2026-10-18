extends GutTest
## A calm monster notices the hero only when it can see them close enough, or when it is hurt or hears a noise or a shout.

const ASLEEP := true
const WANDERING := false


func _cues(asleep: bool, hero_cells: float, in_line_of_sight := true) -> Awareness.Cues:
	var cues := Awareness.Cues.new()
	cues.asleep = asleep
	cues.hero_cells = hero_cells
	cues.hero_in_line_of_sight = in_line_of_sight
	return cues


func test_a_sleeping_monster_notices_a_hero_it_sees_within_four_cells() -> void:
	assert_true(Awareness.new().notices(_cues(ASLEEP, 3.9)))
	assert_true(Awareness.new().notices(_cues(ASLEEP, 4.0)))


func test_a_sleeping_monster_sleeps_on_while_the_hero_is_farther_than_four_cells() -> void:
	assert_false(Awareness.new().notices(_cues(ASLEEP, 4.5)))


func test_a_wandering_monster_notices_a_hero_it_sees_within_nine_cells() -> void:
	assert_true(Awareness.new().notices(_cues(WANDERING, 8.5)))
	assert_false(Awareness.new().notices(_cues(WANDERING, 9.5)))


func test_no_monster_notices_a_hero_behind_a_wall() -> void:
	var awareness := Awareness.new()

	assert_false(awareness.notices(_cues(ASLEEP, 1.0, false)))
	assert_false(awareness.notices(_cues(WANDERING, 1.0, false)))


func test_damage_wakes_a_monster_whatever_it_sees() -> void:
	var cues := _cues(ASLEEP, INF, false)
	cues.hurt = true

	assert_true(Awareness.new().notices(cues))


func test_a_monster_whose_band_noticed_the_hero_notices_too() -> void:
	var cues := _cues(ASLEEP, INF, false)
	cues.alerted = true

	assert_true(Awareness.new().notices(cues))


func test_the_sight_radii_can_be_tuned() -> void:
	var awareness := Awareness.new()
	awareness.asleep_sight_cells = 2.0
	awareness.wander_sight_cells = 12.0

	assert_false(awareness.notices(_cues(ASLEEP, 3.0)))
	assert_true(awareness.notices(_cues(WANDERING, 11.0)))


func _line_of_monsters(count: int, spacing: float) -> PackedVector2Array:
	var cells := PackedVector2Array()
	for i in count:
		cells.append(Vector2(i * spacing, 0))
	return cells


func test_a_noise_is_heard_by_a_monster_seven_cells_away_but_not_nine_even_behind_a_wall() -> void:
	# Distance is all that counts: the rules are never told where the walls are.
	var listeners := PackedVector2Array([Vector2(7, 0), Vector2(0, 9)])

	var heard := Awareness.new().noise_hearers(Vector2.ZERO, listeners)

	assert_eq(heard, [0] as Array[int])


func test_a_blast_is_a_noise_heard_where_it_bursts() -> void:
	var listeners := PackedVector2Array([Vector2(10, 20), Vector2(30, 20)])

	assert_eq(Awareness.new().noise_hearers(Vector2(26, 20), listeners), [1] as Array[int])


func test_a_noise_wakes_a_sleeping_monster_that_hears_it() -> void:
	var cues := _cues(ASLEEP, INF, false)
	cues.alerted = true

	assert_true(Awareness.new().notices(cues))


func test_the_noise_radius_can_be_tuned() -> void:
	var awareness := Awareness.new()
	awareness.noise_cells = 3.0

	assert_eq(awareness.noise_hearers(Vector2.ZERO, PackedVector2Array([Vector2(2, 0), Vector2(5, 0)])), [0] as Array[int])


## Each monster in a band of its own.
func _lone_bands(count: int) -> PackedInt32Array:
	var bands := PackedInt32Array()
	for i in count:
		bands.append(i)
	return bands


func test_a_shout_is_heard_within_eight_cells_whatever_band_the_monster_belongs_to() -> void:
	var listeners := PackedVector2Array([Vector2.ZERO, Vector2(8, 0), Vector2(8.5, 0)])

	assert_eq(Awareness.new().shout_hearers(0, listeners, _lone_bands(3)), [1] as Array[int])


func test_the_rest_of_the_band_hears_a_shout_however_far_it_is() -> void:
	var listeners := PackedVector2Array([Vector2.ZERO, Vector2(20, 0), Vector2(21, 0)])
	var bands := PackedInt32Array([5, 5, 6])

	assert_eq(Awareness.new().shout_hearers(0, listeners, bands), [1] as Array[int])


func test_a_shout_chains_through_a_line_of_monsters_each_closer_than_eight_cells_to_the_next() -> void:
	var awareness := Awareness.new()
	var line := _line_of_monsters(6, 7.0)
	var bands := _lone_bands(6)
	var awake := {0: true}
	var to_shout: Array[int] = [0]

	while not to_shout.is_empty():
		var shouter: int = to_shout.pop_front()
		for heard in awareness.shout_hearers(shouter, line, bands):
			if not awake.has(heard):
				awake[heard] = true
				to_shout.append(heard)

	assert_eq(awake.size(), 6, "the last monster, 35 cells from the first, is woken")


func test_a_shout_is_not_heard_by_a_monster_of_another_band_beyond_its_reach() -> void:
	var line := PackedVector2Array([Vector2(0, 0), Vector2(7, 0), Vector2(16, 0)])

	assert_eq(Awareness.new().shout_hearers(1, line, _lone_bands(3)), [0] as Array[int])


func test_the_shout_radius_can_be_tuned() -> void:
	var awareness := Awareness.new()
	awareness.shout_cells = 3.0
	var listeners := PackedVector2Array([Vector2.ZERO, Vector2(2, 0), Vector2(5, 0)])

	assert_eq(awareness.shout_hearers(0, listeners, _lone_bands(3)), [1] as Array[int])


func _chase(seconds_unseen: float, hero_cells_from_home := 0.0, never_gives_up := false) -> Awareness.Chase:
	var chase := Awareness.Chase.new()
	chase.seconds_unseen = seconds_unseen
	chase.hero_cells_from_home = hero_cells_from_home
	chase.never_gives_up = never_gives_up
	return chase


func test_a_hunter_keeps_hunting_while_it_has_seen_the_hero_lately_and_the_hero_is_near_home() -> void:
	assert_false(Awareness.new().gives_up(_chase(4.9, 23.9)))


func test_a_hunter_gives_up_after_five_seconds_without_seeing_the_hero() -> void:
	assert_true(Awareness.new().gives_up(_chase(5.0)))


func test_a_hunter_gives_up_once_the_hero_is_twenty_four_cells_from_its_home() -> void:
	assert_true(Awareness.new().gives_up(_chase(0.0, 24.0)))


func test_a_hunter_whose_home_never_gives_up_hunts_on_however_long_and_far() -> void:
	assert_false(Awareness.new().gives_up(_chase(60.0, 100.0, true)))


func test_the_give_up_time_and_distance_follow_the_awareness_fields() -> void:
	var awareness := Awareness.new()
	awareness.give_up_seconds = 2.0
	awareness.give_up_cells = 10.0

	assert_true(awareness.gives_up(_chase(2.0)))
	assert_true(awareness.gives_up(_chase(0.0, 10.0)))
