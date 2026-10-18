extends GutTest
## Hurt monsters heal while the hero is away from their map.


func test_healing_comes_a_step_every_tick() -> void:
	assert_eq(Regeneration.healed(100, 900, 0.5, 10.0), 100, "not a whole tick yet")
	assert_eq(Regeneration.healed(100, 900, 1.0, 10.0), 110)
	assert_eq(Regeneration.healed(100, 900, 12.4, 10.0), 220)


func test_healing_stops_at_full_health() -> void:
	assert_eq(Regeneration.healed(100, 900, 1000.0, 10.0), 900)


func test_no_healing_when_the_rate_is_zero() -> void:
	assert_eq(Regeneration.healed(100, 900, 1000.0, 0.0), 100)
