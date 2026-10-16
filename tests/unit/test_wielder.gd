extends GutTest

const ORIGIN := Vector2.ZERO


func _wand(windup: float, cooldown := 1.0) -> Wand:
	var wand := Wand.new()
	wand.windup = windup
	wand.cooldown = cooldown
	return wand


func _released_shot(attacks: Array) -> Shot:
	assert_eq(attacks.size(), 1)
	return attacks[0]


func test_an_attack_is_released_only_after_the_wind_up() -> void:
	var wielder := Wielder.new(_wand(0.5))
	wielder.start(Vector2.RIGHT, 100.0)

	var early := wielder.advance(0.3, ORIGIN)
	var late := wielder.advance(0.3, ORIGIN)

	assert_true(early.is_empty())
	assert_eq(late.size(), 1)


func test_no_new_attack_starts_during_the_cooldown() -> void:
	var wielder := Wielder.new(_wand(0.0, 1.0))
	wielder.start(Vector2.RIGHT, 100.0)
	wielder.advance(0.0, ORIGIN)
	wielder.advance(0.5, ORIGIN)

	assert_false(wielder.start(Vector2.RIGHT, 100.0))


func test_without_a_target_the_aim_stays_where_it_started() -> void:
	var wielder := Wielder.new(_wand(0.5))
	wielder.start(Vector2.UP, 100.0)

	var shot := _released_shot(wielder.advance(0.6, Vector2(50, 50)))

	assert_eq(shot.direction, Vector2.UP)


func test_with_a_target_the_aim_follows_it_during_the_wind_up() -> void:
	var wielder := Wielder.new(_wand(0.5))
	var target := Node2D.new()
	target.position = Vector2(100, 0)
	wielder.start(Vector2.RIGHT, 100.0, target)

	target.position = Vector2(0, -100)
	var shot := _released_shot(wielder.advance(0.6, ORIGIN))

	assert_almost_eq(shot.direction, Vector2.UP, Vector2(0.001, 0.001))
	target.free()
