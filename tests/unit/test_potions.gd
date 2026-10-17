extends GutTest


func test_a_healing_potion_restores_its_amount() -> void:
	var potion := HealingPotion.new()
	potion.amount = 5

	assert_eq(potion.effect().heal_amount, 5)


func test_a_haste_potion_speeds_up_for_its_duration() -> void:
	var potion := HastePotion.new()

	var effect := potion.effect()

	assert_eq(effect.haste_multiplier, potion.speed_multiplier)
	assert_eq(effect.haste_seconds, potion.duration)
	assert_gt(effect.haste_multiplier, 1.0)


func test_a_might_potion_adds_damage_for_its_duration() -> void:
	var potion := MightPotion.new()

	var effect := potion.effect()

	assert_eq(effect.might_bonus, potion.bonus_damage)
	assert_eq(effect.might_seconds, potion.duration)


func test_every_potion_has_a_unique_id_a_name_and_a_description() -> void:
	var ids := GameTuning.potion_ids()
	for potion in GameTuning.potions():
		assert_eq(ids.count(potion.id), 1, potion.id)
		assert_ne(potion.display_name, "", potion.id)
		assert_ne(potion.description, "", potion.id)
