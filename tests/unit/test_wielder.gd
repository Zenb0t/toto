extends GutTest

const ORIGIN := Vector2.ZERO


func _wand(windup: float, attack_interval := 1.0) -> MagicMissile:
	var wand := MagicMissile.new()
	wand.windup = windup
	wand.attack_interval = attack_interval
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


func test_no_new_attack_starts_right_after_another() -> void:
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


func test_attacks_follow_each_other_until_the_ammo_runs_out() -> void:
	var wand := _wand(0.0, 0.2)
	wand.ammo = 2
	wand.reload = 5.0
	var wielder := Wielder.new(wand)

	var first := wielder.start(Vector2.RIGHT, 100.0)
	wielder.advance(0.25, ORIGIN)
	var second := wielder.start(Vector2.RIGHT, 100.0)
	wielder.advance(0.25, ORIGIN)
	var third := wielder.start(Vector2.RIGHT, 100.0)

	assert_eq([first, second, third], [true, true, false])


func test_an_empty_weapon_attacks_again_once_a_charge_reloads() -> void:
	var wand := _wand(0.0, 0.1)
	wand.ammo = 1
	wand.reload = 1.0
	var wielder := Wielder.new(wand)
	wielder.start(Vector2.RIGHT, 100.0)

	wielder.advance(1.1, ORIGIN)

	assert_true(wielder.start(Vector2.RIGHT, 100.0))
