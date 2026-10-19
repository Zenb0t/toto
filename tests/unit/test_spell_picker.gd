extends GutTest
## The Lich casts one spell at a time with a pause between; which one comes next follows the rule in SpellPicker.

const SPELL := SpellPicker.Spell


## A picker that knows every spell (the Lich learns them one ticket at a time).
func _knowing_everything() -> SpellPicker:
	var picker := SpellPicker.new()
	picker.known = [SPELL.CLOUD, SPELL.BONE_SPRAY, SPELL.SUMMON]
	return picker


## Casts a spell from start to finish at full health.
func _cast(picker: SpellPicker, situation := SpellPicker.Situation.new()) -> SPELL:
	var spell := picker.pick(situation)
	picker.begin(spell)
	picker.end(situation.health_share)
	picker.advance(60.0)
	return spell


func test_a_fresh_lich_is_ready_to_cast_a_cloud() -> void:
	var picker := SpellPicker.new()
	picker.known = [SPELL.CLOUD, SPELL.BONE_SPRAY]

	assert_true(picker.is_ready())
	assert_eq(picker.pick(SpellPicker.Situation.new()), SPELL.CLOUD)


func test_while_a_spell_is_cast_no_other_is_picked() -> void:
	var picker := _knowing_everything()
	picker.begin(SPELL.CLOUD)

	assert_true(picker.is_casting())
	assert_false(picker.is_ready())
	assert_eq(picker.pick(SpellPicker.Situation.new()), SPELL.NONE)
	picker.advance(60.0)
	assert_eq(picker.pick(SpellPicker.Situation.new()), SPELL.NONE, "waiting does not end a cast")


func test_a_second_spell_cannot_start_while_one_is_being_cast() -> void:
	var picker := _knowing_everything()
	picker.begin(SPELL.CLOUD)

	picker.begin(SPELL.BONE_SPRAY)
	picker.end(1.0)
	picker.advance(60.0)

	var full := SpellPicker.Situation.new(picker.summon_cap)
	assert_eq(picker.pick(full), SPELL.CLOUD, "the Bone Spray never started, so it did not reset the Clouds counted")
	picker.begin(SPELL.CLOUD)
	picker.end(1.0)
	picker.advance(60.0)
	assert_eq(picker.pick(full), SPELL.BONE_SPRAY)


func test_after_a_spell_the_pause_holds_until_it_has_run_out() -> void:
	var picker := SpellPicker.new()
	picker.known = [SPELL.CLOUD]
	picker.pause_seconds = 2.0
	picker.begin(SPELL.CLOUD)
	picker.end(1.0)

	picker.advance(1.9)
	assert_false(picker.is_ready())
	assert_eq(picker.pick(SpellPicker.Situation.new()), SPELL.NONE)

	picker.advance(0.2)
	assert_true(picker.is_ready())
	assert_eq(picker.pick(SpellPicker.Situation.new()), SPELL.CLOUD)


func test_the_pause_does_not_run_while_a_spell_is_cast() -> void:
	var picker := SpellPicker.new()
	picker.pause_seconds = 1.0
	picker.begin(SPELL.CLOUD)
	picker.advance(5.0)
	picker.end(1.0)

	assert_false(picker.is_ready(), "the whole pause still lies ahead")


func test_below_half_health_the_pause_is_shorter() -> void:
	var calm := SpellPicker.new()
	calm.begin(SPELL.CLOUD)
	calm.end(0.9)
	var angry := SpellPicker.new()
	angry.begin(SPELL.CLOUD)
	angry.end(0.4)
	var between := (calm.pause_seconds + angry.phase_two_pause_seconds) / 2.0

	calm.advance(between)
	angry.advance(between)

	assert_false(calm.is_ready())
	assert_true(angry.is_ready())


func test_summon_undead_comes_first_whenever_fewer_skeletons_live_than_the_cap() -> void:
	var picker := _knowing_everything()

	assert_eq(picker.pick(SpellPicker.Situation.new(0)), SPELL.SUMMON)
	assert_eq(picker.pick(SpellPicker.Situation.new(picker.summon_cap - 1)), SPELL.SUMMON)
	assert_ne(picker.pick(SpellPicker.Situation.new(picker.summon_cap)), SPELL.SUMMON)


func test_with_the_cap_full_he_casts_cloud_cloud_bone_spray_over_and_over() -> void:
	var picker := _knowing_everything()
	var full := SpellPicker.Situation.new(picker.summon_cap)

	var spells: Array[SPELL] = []
	for _i in 6:
		spells.append(_cast(picker, full))

	assert_eq(spells, [SPELL.CLOUD, SPELL.CLOUD, SPELL.BONE_SPRAY, SPELL.CLOUD, SPELL.CLOUD, SPELL.BONE_SPRAY])


func test_the_number_of_clouds_between_bone_sprays_is_tunable() -> void:
	var picker := _knowing_everything()
	picker.clouds_per_spray = 3
	var full := SpellPicker.Situation.new(picker.summon_cap)

	var spells: Array[SPELL] = []
	for _i in 4:
		spells.append(_cast(picker, full))

	assert_eq(spells, [SPELL.CLOUD, SPELL.CLOUD, SPELL.CLOUD, SPELL.BONE_SPRAY])


func test_a_lich_who_knows_only_the_cloud_casts_nothing_else() -> void:
	var picker := SpellPicker.new()
	picker.known = [SPELL.CLOUD]

	for _i in 6:
		assert_eq(_cast(picker, SpellPicker.Situation.new(0)), SPELL.CLOUD)


func test_below_half_health_the_summon_cap_goes_up_by_two() -> void:
	var picker := _knowing_everything()

	assert_eq(picker.cap(1.0), 5)
	assert_eq(picker.cap(0.5), 5, "exactly half is not below half")
	assert_eq(picker.cap(0.49), 7)
	assert_eq(picker.pick(SpellPicker.Situation.new(5, 0.9)), SPELL.CLOUD)
	assert_eq(picker.pick(SpellPicker.Situation.new(5, 0.3)), SPELL.SUMMON)


func test_the_summon_cap_never_passes_ten() -> void:
	var picker := _knowing_everything()
	picker.summon_cap = 9
	picker.phase_two_cap_bonus = 5

	assert_eq(picker.cap(0.1), SpellPicker.MAX_SUMMON_CAP)
	assert_ne(picker.pick(SpellPicker.Situation.new(10, 0.1)), SPELL.SUMMON)


func test_as_shipped_he_knows_the_cloud_bone_spray_and_summon_undead() -> void:
	var picker := SpellPicker.new()

	assert_has(picker.known, SPELL.CLOUD)
	assert_has(picker.known, SPELL.BONE_SPRAY)
	assert_has(picker.known, SPELL.SUMMON)


func test_as_shipped_he_raises_skeletons_first_and_then_casts_cloud_cloud_bone_spray() -> void:
	var picker := SpellPicker.new()

	assert_eq(_cast(picker, SpellPicker.Situation.new(0)), SPELL.SUMMON)
	var full := SpellPicker.Situation.new(picker.summon_cap)
	var spells: Array[SPELL] = []
	for _i in 6:
		spells.append(_cast(picker, full))

	assert_eq(spells, [SPELL.CLOUD, SPELL.CLOUD, SPELL.BONE_SPRAY, SPELL.CLOUD, SPELL.CLOUD, SPELL.BONE_SPRAY])


func test_a_skeleton_that_dies_frees_a_place_and_he_summons_again() -> void:
	var picker := _knowing_everything()

	assert_ne(picker.pick(SpellPicker.Situation.new(picker.summon_cap)), SPELL.SUMMON, "the cap is full")
	assert_eq(picker.pick(SpellPicker.Situation.new(picker.summon_cap - 1)), SPELL.SUMMON, "one fell")


func test_with_no_ground_to_raise_a_skeleton_on_he_casts_another_spell() -> void:
	var picker := _knowing_everything()

	assert_eq(picker.pick(SpellPicker.Situation.new(0, 1.0, false)), SPELL.CLOUD)


func test_in_phase_two_the_pause_is_shorter_and_the_cap_two_higher() -> void:
	var picker := _knowing_everything()
	picker.begin(SPELL.CLOUD)
	picker.end(0.3)

	picker.advance(picker.phase_two_pause_seconds + 0.01)

	assert_true(picker.is_ready())
	assert_lt(picker.phase_two_pause_seconds, picker.pause_seconds)
	assert_eq(picker.cap(0.3), picker.cap(1.0) + 2)


func test_bone_spray_is_his_rarest_spell() -> void:
	var picker := _knowing_everything()
	var full := SpellPicker.Situation.new(picker.summon_cap)
	var casts := {SPELL.CLOUD: 0, SPELL.BONE_SPRAY: 0}

	for _i in 30:
		casts[_cast(picker, full)] += 1

	assert_lt(casts[SPELL.BONE_SPRAY], casts[SPELL.CLOUD])
	assert_eq(casts[SPELL.BONE_SPRAY], 10)
