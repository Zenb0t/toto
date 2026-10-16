extends GutTest


func test_starts_at_full_health() -> void:
	var health := Health.new(10)

	assert_eq(health.current, 10)
	assert_false(health.is_dead())


func test_damage_reduces_current_health() -> void:
	var health := Health.new(10)

	health.take_damage(3)

	assert_eq(health.current, 7)


func test_health_never_drops_below_zero() -> void:
	var health := Health.new(10)

	health.take_damage(999)

	assert_eq(health.current, 0)
	assert_true(health.is_dead())


func test_dying_is_announced_exactly_once() -> void:
	var health := Health.new(5)
	watch_signals(health)

	health.take_damage(5)
	health.take_damage(5)

	assert_signal_emit_count(health, "died", 1)


func test_surviving_damage_does_not_announce_death() -> void:
	var health := Health.new(5)
	watch_signals(health)

	health.take_damage(4)

	assert_signal_not_emitted(health, "died")


func test_healing_is_capped_at_maximum() -> void:
	var health := Health.new(10)
	health.take_damage(2)

	health.heal(50)

	assert_eq(health.current, 10)


func test_dead_actors_cannot_be_healed() -> void:
	var health := Health.new(10)
	health.take_damage(10)

	health.heal(5)

	assert_true(health.is_dead())


func test_negative_damage_is_ignored() -> void:
	var health := Health.new(10)

	health.take_damage(-4)

	assert_eq(health.current, 10)


func test_restored_health_resumes_where_it_was_left() -> void:
	var health := Health.restored(10, 4)

	assert_eq(health.current, 4)
	assert_eq(health.maximum, 10)


func test_restored_health_stays_within_its_limits() -> void:
	assert_eq(Health.restored(10, 25).current, 10)
	assert_eq(Health.restored(10, 0).current, 1, "never restored dead")


func test_raising_the_maximum_heals_as_much() -> void:
	var health := Health.restored(10, 6)

	health.raise_maximum(2)

	assert_eq(health.maximum, 12)
	assert_eq(health.current, 8)
