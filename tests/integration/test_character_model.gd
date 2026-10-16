extends GutTest
## Characters hold their weapon and act out what they do.


func _model(look := CharacterLook.hero()) -> CharacterModel:
	var model := CharacterModel.new(look)
	add_child_autofree(model)
	return model


func test_a_character_holds_the_weapon_it_is_given() -> void:
	var model := _model()

	model.hold("crossbow")

	assert_eq(model.held_weapon_id(), "crossbow")


func test_a_character_stands_idle_and_runs_while_moving() -> void:
	var model := _model()
	await wait_process_frames(2)
	assert_eq(model.current_animation(), CharacterModel.IDLE)

	model.show_moving(true)
	await wait_process_frames(2)

	assert_eq(model.current_animation(), CharacterModel.RUN)


func test_an_attack_plays_the_weapons_swing_then_goes_back_to_standing() -> void:
	var model := _model()
	model.hold("sword")

	model.play_attack()

	assert_eq(model.current_animation(), CharacterLook.attack_animation("sword"))
	await wait_seconds(2.0)
	assert_eq(model.current_animation(), CharacterModel.IDLE)


func test_models_without_their_own_animations_share_them() -> void:
	var mage := _model(CharacterLook.of_monster(Bestiary.by_id("pyromancer")))

	mage.show_moving(true)
	await wait_process_frames(2)

	assert_eq(mage.current_animation(), CharacterModel.RUN)


func test_a_hit_flashes_the_model_for_a_moment() -> void:
	var model := _model()

	model.flash()
	assert_true(model.is_flashing())
	await wait_seconds(CharacterModel.FLASH_SECONDS + 0.1)

	assert_false(model.is_flashing())


func test_skeletons_share_the_adventurers_animations() -> void:
	var skeleton := _model(CharacterLook.of_monster(Bestiary.by_id("skeleton")))

	skeleton.show_moving(true)
	await wait_process_frames(2)

	assert_eq(skeleton.current_animation(), CharacterModel.RUN)
