extends GutTest
## Brawl Stars style ammo: a few charges, reloading one at a time.


func test_starts_full() -> void:
	var ammo := Ammo.new(3, 1.0)

	assert_eq(ammo.charges(), 3)
	assert_true(ammo.is_full())


func test_each_attack_spends_one_charge_until_empty() -> void:
	var ammo := Ammo.new(2, 1.0)

	assert_true(ammo.try_spend())
	assert_true(ammo.try_spend())
	assert_false(ammo.try_spend())
	assert_eq(ammo.charges(), 0)


func test_charges_come_back_one_at_a_time() -> void:
	var ammo := Ammo.new(3, 1.0)
	ammo.try_spend()
	ammo.try_spend()
	ammo.try_spend()

	ammo.tick(1.5)

	assert_eq(ammo.charges(), 1)
	assert_almost_eq(ammo.level(), 1.5, 0.001)


func test_reloading_stops_when_full() -> void:
	var ammo := Ammo.new(3, 1.0)
	ammo.try_spend()

	ammo.tick(10.0)

	assert_eq(ammo.charges(), 3)
	assert_eq(ammo.level(), 3.0)


func test_the_bar_shows_full_segments_then_the_one_reloading() -> void:
	var ammo := Ammo.new(3, 2.0)
	ammo.try_spend()
	ammo.try_spend()

	ammo.tick(1.0)

	assert_eq(ammo.segment_fills(), [1.0, 0.5, 0.0] as Array[float])
