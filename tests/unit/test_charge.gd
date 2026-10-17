extends GutTest

const FULL_SECONDS := 1.5


func test_a_tap_has_no_charge() -> void:
	assert_eq(Charge.ratio(0.0, FULL_SECONDS), 0.0)


func test_charge_grows_with_the_time_held() -> void:
	assert_almost_eq(Charge.ratio(0.75, FULL_SECONDS), 0.5, 0.0001)


func test_holding_longer_than_a_full_charge_adds_nothing() -> void:
	assert_eq(Charge.ratio(10.0, FULL_SECONDS), 1.0)
	assert_eq(Charge.damage(10.0, FULL_SECONDS, 60, 240), 240)


func test_a_tap_does_the_minimum_damage() -> void:
	assert_eq(Charge.damage(0.0, FULL_SECONDS, 60, 240), 60)


func test_damage_grows_evenly_between_the_minimum_and_the_maximum() -> void:
	assert_eq(Charge.damage(0.75, FULL_SECONDS, 60, 240), 150)


func test_only_a_full_charge_is_full() -> void:
	assert_false(Charge.is_full(1.4, FULL_SECONDS))
	assert_true(Charge.is_full(FULL_SECONDS, FULL_SECONDS))


func test_an_attacker_that_never_charges_counts_as_fully_charged() -> void:
	assert_true(Charge.is_full(Charge.FULL, FULL_SECONDS))


func test_a_weapon_that_needs_no_charge_time_is_always_full() -> void:
	assert_eq(Charge.ratio(0.0, 0.0), 1.0)
