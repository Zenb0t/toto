extends GutTest
## A calm monster notices the hero only when it can see them close enough, or when it is hurt or alerted.

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
