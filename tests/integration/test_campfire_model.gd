extends GutTest
## The campfire in the 3D view shows burning, embers with a countdown, or cold stones.


func _model_in_sight() -> CampfireModel:
	var model := CampfireModel.new()
	add_child_autofree(model)
	model.show_at(Vector2i(3, 3), MapView3D.LIT)
	return model


func test_an_unlit_campfire_shows_neither_flame_nor_countdown() -> void:
	var model := _model_in_sight()
	model.show_rest(Campfire.State.UNLIT, 0.0)

	assert_false(model.is_burning())
	assert_false(model.is_in_embers())
	assert_eq(model.countdown_text(), "")


func test_a_burning_campfire_shows_its_flame() -> void:
	var model := _model_in_sight()
	model.show_rest(Campfire.State.BURNING, 6.0)

	assert_true(model.is_burning())
	assert_eq(model.countdown_text(), "")


func test_embers_show_the_seconds_left_before_it_can_be_lit_again() -> void:
	var model := _model_in_sight()
	model.show_rest(Campfire.State.EMBERS, 73.2)

	assert_false(model.is_burning())
	assert_true(model.is_in_embers())
	assert_eq(model.countdown_text(), "Embers 74 s")


func test_a_fire_held_by_a_band_burns_whatever_its_state() -> void:
	var model := _model_in_sight()
	model.show_rest(Campfire.State.UNLIT, 0.0, true)

	assert_true(model.is_burning())


func test_a_fire_out_of_sight_shows_no_countdown() -> void:
	var model := _model_in_sight()
	model.show_rest(Campfire.State.EMBERS, 30.0)
	model.show_at(Vector2i(3, 3), MapView3D.REMEMBERED_BRIGHTNESS)

	assert_eq(model.countdown_text(), "")
