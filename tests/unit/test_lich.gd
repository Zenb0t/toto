extends GutTest
## The Lich is a monster of his own, with every number of his a knob in the Tune screen.


func test_the_lich_is_a_unique_monster_apart_from_the_necromancer() -> void:
	var lich := Bestiary.by_id(Lich.ID)
	var necromancer := Bestiary.by_id("necromancer")

	assert_eq(lich.id, "lich")
	assert_ne(lich.letter, necromancer.letter)
	assert_eq(Bestiary.by_letter(Lich.LETTER).id, "lich")
	assert_eq(lich.weapon_id, "mephitic_cloud")
	assert_gt(lich.max_health, necromancer.max_health * 5)
	assert_almost_eq(lich.size, 1.3, 0.001)


func test_ordinary_rooms_are_never_generated_with_a_lich() -> void:
	for pool: Array in DungeonDifficulty.POOLS_BY_DEPTH:
		assert_does_not_have(pool, Lich.LETTER)


func test_every_lich_number_is_a_knob_that_defaults_to_the_class() -> void:
	var tuning := GameTuning.create()
	var lich := GameTuning.lich(tuning)
	var spells := GameTuning.lich_spells(tuning)

	for knob in Lich.new().knobs():
		assert_eq(lich.get(knob.field), Lich.new().get(knob.field), knob.field)
	for knob in SpellPicker.new().knobs():
		assert_eq(spells.get(knob.field), SpellPicker.new().get(knob.field), knob.field)
	assert_not_null(tuning.param(GameTuning.key(Lich.ID, "keep_distance_cells")))
	assert_not_null(tuning.param(GameTuning.key("lich_spells", "pause_seconds")))
	assert_not_null(tuning.param(GameTuning.key("lich_spells", "summon_cap")))


func test_tuned_lich_numbers_make_a_different_lich_and_picker() -> void:
	var tuning := GameTuning.create()
	tuning.set_value(GameTuning.key(Lich.ID, "max_health"), 9000)
	tuning.set_value(GameTuning.key("lich_spells", "pause_seconds"), 3.0)

	assert_eq(GameTuning.lich(tuning).monster().max_health, 9000)
	assert_eq(GameTuning.lich_spells(tuning).pause_seconds, 3.0)


func test_the_tune_screen_has_a_lich_section_holding_his_knobs() -> void:
	var lich_section: TuningSection = null
	for section in GameTuning.sections("dagger", "dash"):
		if section.title == GameTuning.LICH_GROUP:
			lich_section = section
	var in_group := GameTuning.create().params().filter(
		func(param: Tuning.Param) -> bool: return param.group == GameTuning.LICH_GROUP)

	assert_not_null(lich_section)
	assert_eq(in_group.size(), Lich.new().knobs().size() + SpellPicker.new().knobs().size())


func test_the_lich_casts_as_often_as_his_pause_lets_him() -> void:
	var tuning := GameTuning.create()

	var lich_cloud := GameTuning.monster_weapon(tuning, Lich.new().monster())
	var necromancer_cloud := GameTuning.monster_weapon(tuning, Bestiary.by_id("necromancer"))

	assert_eq(lich_cloud.reload, 0.0)
	assert_gt(necromancer_cloud.reload, 0.0)
