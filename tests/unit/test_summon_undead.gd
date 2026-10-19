extends GutTest
## How many skeletons a cast raises, and the spell's Knobs.


func test_a_cast_raises_the_skeletons_per_summon_when_the_cap_has_room() -> void:
	var summon := SummonUndead.new()

	assert_eq(summon.count_to_raise(0, 10), summon.skeletons_per_summon)


func test_a_cast_raises_only_what_fits_under_the_cap() -> void:
	var summon := SummonUndead.new()
	summon.skeletons_per_summon = 3

	assert_eq(summon.count_to_raise(4, 5), 1)
	assert_eq(summon.count_to_raise(5, 5), 0)
	assert_eq(summon.count_to_raise(7, 5), 0, "never a negative count")


func test_its_numbers_are_knobs() -> void:
	var fields: Array[String] = []
	for knob in SummonUndead.new().knobs():
		fields.append(knob.field)

	for field in ["summon_range_cells", "skeletons_per_summon", "rise_seconds", "rise_interval_seconds", "windup"]:
		assert_has(fields, field)


func test_its_release_is_a_summon_not_an_attack() -> void:
	var released := SummonUndead.new().attacks(Vector2.ZERO, Vector2.RIGHT, 0.0)

	assert_eq(released.size(), 1)
	assert_true(released[0] is SummonCast)
