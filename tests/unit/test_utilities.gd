extends GutTest


func test_a_dash_bursts_toward_the_aim_for_its_duration() -> void:
	var dash := Dash.new()

	var effect := dash.activate(Vector2(0, 3))

	assert_eq(effect.dash_direction, Vector2.DOWN)
	assert_eq(effect.dash_speed, dash.dash_speed)
	assert_eq(effect.dash_seconds, dash.dash_duration)


func test_a_shield_protects_for_its_duration_wherever_it_is_aimed() -> void:
	var shield := Shield.new()
	shield.duration = 2.0

	var effect := shield.activate(Vector2.LEFT)

	assert_eq(effect.shield_seconds, 2.0)
	assert_eq(effect.dash_seconds, 0.0)


func test_only_the_dash_needs_an_aim_preview() -> void:
	assert_not_null(Dash.new().aim_shape())
	assert_null(Shield.new().aim_shape())


func test_every_item_has_a_unique_id_and_a_description() -> void:
	var ids := GameTuning.item_ids()
	for id in ids:
		assert_eq(ids.count(id), 1, id)
		assert_ne(GameTuning.item(GameTuning.create(), id).description, "", id)
