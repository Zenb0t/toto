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


func test_a_blink_jumps_its_distance_toward_the_aim() -> void:
	var blink := Blink.new()
	blink.distance = 100.0

	assert_eq(blink.activate(Vector2(0, -5)).blink_offset, Vector2(0, -100))


func test_a_frost_nova_lets_out_a_chilling_burst() -> void:
	var frost := FrostNova.new()

	var effect := frost.activate(Vector2.RIGHT)

	assert_eq(effect.attacks.size(), 1)
	var nova: Nova = effect.attacks[0]
	assert_eq(nova.radius, frost.radius)
	assert_eq(nova.damage, frost.damage)
	assert_lt(nova.slow_multiplier, 1.0)
	assert_false(nova.hurts_player)


func test_a_frost_nova_previews_the_area_around_you() -> void:
	var shape := FrostNova.new().aim_shape()

	assert_eq(shape.length, 0.0)
	assert_eq(shape.end_radius, FrostNova.new().radius)
