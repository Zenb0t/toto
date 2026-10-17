extends GutTest

const ALICE := 1
const BOB := 2
const CAROL := 3


func _squad(max_attackers: int, turn_gap: float) -> Squad:
	var squad := Squad.new()
	squad.max_attackers = max_attackers
	squad.turn_gap_seconds = turn_gap
	return squad


func test_a_lone_member_gets_its_turn_right_away() -> void:
	assert_true(_squad(1, 0.5).request_turn(ALICE))


func test_no_more_members_attack_at_once_than_allowed() -> void:
	var squad := _squad(2, 0.0)

	assert_true(squad.request_turn(ALICE))
	assert_true(squad.request_turn(BOB))
	assert_false(squad.request_turn(CAROL))


func test_a_member_that_finished_its_attack_frees_its_turn() -> void:
	var squad := _squad(1, 0.0)
	squad.request_turn(ALICE)
	squad.end_turn(ALICE)

	assert_true(squad.request_turn(BOB))


func test_attacks_start_one_after_another_not_all_at_once() -> void:
	var squad := _squad(3, 0.4)
	squad.request_turn(ALICE)

	var too_soon := squad.request_turn(BOB)
	squad.tick(0.4)
	var later := squad.request_turn(BOB)

	assert_false(too_soon)
	assert_true(later)


func test_a_member_already_attacking_keeps_its_turn() -> void:
	var squad := _squad(1, 1.0)
	squad.request_turn(ALICE)

	assert_true(squad.request_turn(ALICE))
	assert_true(squad.is_attacking(ALICE))


func test_a_defeated_member_frees_its_turn() -> void:
	var squad := _squad(1, 0.0)
	squad.request_turn(ALICE)
	squad.leave(ALICE)

	assert_true(squad.request_turn(BOB))


func test_a_lone_member_stays_where_it_is() -> void:
	var squad := Squad.new()
	squad.report_bearing(ALICE, 1.0)

	assert_almost_eq(squad.flank_bearing(ALICE), 1.0, 0.001)


func test_members_standing_together_spread_apart_around_the_target() -> void:
	var squad := Squad.new()
	squad.flank_spread_degrees = 60.0
	squad.report_bearing(ALICE, 0.0)
	squad.report_bearing(BOB, 0.1)

	var gap := angle_difference(squad.flank_bearing(ALICE), squad.flank_bearing(BOB))

	assert_almost_eq(gap, deg_to_rad(60.0), 0.001)


func test_spots_keep_the_order_members_stand_in_so_nobody_crosses_over() -> void:
	var slots := Squad.slot_bearings([0.3, -0.2, 0.0], deg_to_rad(45.0))

	assert_lt(slots[1], slots[2])
	assert_lt(slots[2], slots[0])


func test_spots_are_centred_on_where_the_group_stands() -> void:
	var slots := Squad.slot_bearings([PI / 2.0 - 0.1, PI / 2.0 + 0.1], deg_to_rad(90.0))

	assert_almost_eq((slots[0] + slots[1]) / 2.0, PI / 2.0, 0.001)


func test_a_big_group_surrounds_the_target_evenly() -> void:
	var slots := Squad.slot_bearings([0.0, 0.1, 0.2, 0.3], deg_to_rad(120.0))
	slots.sort()

	for i in range(1, slots.size()):
		assert_almost_eq(slots[i] - slots[i - 1], TAU / 4.0, 0.001)
