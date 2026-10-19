extends GutTest

const PHONE := Vector2(1280, 720)
const WIDE_PHONE := Vector2(1600, 720)


func test_default_controls_fit_on_screen_without_overlapping() -> void:
	var layout := ControlLayout.new()
	var screen_rect := Rect2(Vector2.ZERO, PHONE)
	var rects: Array[Rect2] = []
	for id in ControlLayout.IDS:
		rects.append(layout.rect_in(id, PHONE))

	for rect in rects:
		assert_true(screen_rect.encloses(rect), "%s should be on screen" % rect)
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			assert_false(rects[i].intersects(rects[j]), "%s and %s should not overlap" % [ControlLayout.IDS[i], ControlLayout.IDS[j]])


func test_default_buttons_are_bigger_than_the_first_prototype() -> void:
	var layout := ControlLayout.new()

	assert_gt(layout.diameter_of(ControlLayout.ATTACK), 140.0)
	assert_gt(layout.diameter_of(ControlLayout.MOVEMENT), 100.0)
	assert_gt(layout.diameter_of(ControlLayout.SKILL), 100.0)


func test_sizes_are_kept_within_usable_limits() -> void:
	var layout := ControlLayout.new()

	layout.set_diameter(ControlLayout.ATTACK, 5.0)
	layout.set_diameter(ControlLayout.MOVEMENT, 5000.0)

	assert_eq(layout.diameter_of(ControlLayout.ATTACK), ControlLayout.MIN_DIAMETER)
	assert_eq(layout.diameter_of(ControlLayout.MOVEMENT), ControlLayout.MAX_DIAMETER)


func test_a_control_dragged_past_the_edge_stays_fully_on_screen() -> void:
	var layout := ControlLayout.new()

	layout.set_center(ControlLayout.ATTACK, Vector2(1.4, -0.3))

	var rect := layout.rect_in(ControlLayout.ATTACK, PHONE)
	assert_true(Rect2(Vector2.ZERO, PHONE).encloses(rect))
	assert_eq(rect.end.x, PHONE.x)
	assert_eq(rect.position.y, 0.0)


func test_the_stick_rests_in_the_left_half_where_it_can_be_touched() -> void:
	var layout := ControlLayout.new()

	layout.set_center(ControlLayout.STICK, Vector2(0.9, 0.5))

	assert_eq(layout.center_of(ControlLayout.STICK).x, ControlLayout.STICK_MAX_X)


func test_the_stick_rests_below_the_top_of_the_screen() -> void:
	var layout := ControlLayout.new()

	layout.set_center(ControlLayout.STICK, Vector2(0.2, 0.0))

	assert_almost_eq(layout.center_of(ControlLayout.STICK).y, ControlLayout.STICK_MIN_Y, 0.001)


func test_the_stick_zone_leaves_the_top_left_corner_free_for_the_map_button() -> void:
	var zone := ControlLayout.stick_zone(Vector2(1280, 720))

	assert_false(zone.has_point(Vector2(60, 92)))
	assert_true(zone.has_point(Vector2(200, 500)))


func test_buttons_keep_their_relative_spot_on_a_wider_screen() -> void:
	var layout := ControlLayout.new()
	layout.set_center(ControlLayout.ATTACK, Vector2(0.8, 0.5))

	var center := layout.rect_in(ControlLayout.ATTACK, WIDE_PHONE).get_center()

	assert_almost_eq(center, Vector2(1280, 360), Vector2(0.01, 0.01))


func test_finds_the_control_under_a_thumb() -> void:
	var layout := ControlLayout.new()
	var attack_center := layout.rect_in(ControlLayout.ATTACK, PHONE).get_center()

	assert_eq(layout.control_at(attack_center, PHONE), ControlLayout.ATTACK)
	assert_eq(layout.control_at(Vector2(640, 40), PHONE), ControlLayout.NONE)


func test_saved_data_restores_the_same_layout() -> void:
	var layout := ControlLayout.new()
	layout.set_center(ControlLayout.MOVEMENT, Vector2(0.3, 0.4))
	layout.set_diameter(ControlLayout.MOVEMENT, 222.0)

	var restored := ControlLayout.from_dict(layout.to_dict())

	assert_eq(restored.center_of(ControlLayout.MOVEMENT), Vector2(0.3, 0.4))
	assert_eq(restored.diameter_of(ControlLayout.MOVEMENT), 222.0)


func test_missing_or_broken_saved_data_falls_back_to_defaults() -> void:
	var defaults := ControlLayout.new()

	var restored := ControlLayout.from_dict({"attack": {"center": "nonsense"}, "utility": 42})

	for id in ControlLayout.IDS:
		assert_eq(restored.center_of(id), defaults.center_of(id))
		assert_eq(restored.diameter_of(id), defaults.diameter_of(id))


func test_editing_a_copy_leaves_the_original_untouched() -> void:
	var original := ControlLayout.new()
	var copy := original.copy()

	copy.set_diameter(ControlLayout.ATTACK, 300.0)

	assert_ne(original.diameter_of(ControlLayout.ATTACK), 300.0)


func test_a_layout_saved_before_the_skill_button_keeps_its_movement_button_and_gets_the_default_skill() -> void:
	var saved := {"utility": {"center": Vector2(0.6, 0.7), "diameter": 150.0}}

	var restored := ControlLayout.from_dict(saved)

	assert_eq(restored.center_of(ControlLayout.MOVEMENT), Vector2(0.6, 0.7))
	assert_eq(restored.center_of(ControlLayout.SKILL), ControlLayout.new().center_of(ControlLayout.SKILL))
