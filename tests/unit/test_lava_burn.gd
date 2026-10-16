extends GutTest

const ACTOR := 1


func test_stepping_into_lava_burns_at_once() -> void:
	assert_eq(LavaBurn.new().damage_due(ACTOR, true, 0.016), LavaBurn.DAMAGE)


func test_staying_in_lava_burns_again_every_interval() -> void:
	var lava := LavaBurn.new()
	lava.damage_due(ACTOR, true, 0.016)

	var soon := lava.damage_due(ACTOR, true, LavaBurn.BURN_INTERVAL / 2.0)
	var later := lava.damage_due(ACTOR, true, LavaBurn.BURN_INTERVAL / 2.0)

	assert_eq(soon, 0)
	assert_eq(later, LavaBurn.DAMAGE)


func test_floor_never_burns() -> void:
	assert_eq(LavaBurn.new().damage_due(ACTOR, false, 1.0), 0)


func test_stepping_out_and_back_in_burns_again_at_once() -> void:
	var lava := LavaBurn.new()
	lava.damage_due(ACTOR, true, 0.016)
	lava.damage_due(ACTOR, false, 0.016)

	assert_eq(lava.damage_due(ACTOR, true, 0.016), LavaBurn.DAMAGE)


func test_each_actor_burns_on_its_own_clock() -> void:
	var lava := LavaBurn.new()
	lava.damage_due(ACTOR, true, 0.016)

	assert_eq(lava.damage_due(2, true, 0.016), LavaBurn.DAMAGE)
