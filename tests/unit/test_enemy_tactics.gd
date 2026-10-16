extends GutTest

const IDEAL := 200.0
const SLACK := 40.0


func test_an_enemy_too_far_away_closes_in() -> void:
	var move := EnemyTactics.move_direction(Vector2(500, 0), IDEAL, SLACK, 1.0)

	assert_eq(move, Vector2.RIGHT)


func test_an_enemy_too_close_backs_off() -> void:
	var move := EnemyTactics.move_direction(Vector2(50, 0), IDEAL, SLACK, 1.0)

	assert_eq(move, Vector2.LEFT)


func test_an_enemy_at_its_favourite_distance_circles_its_target_slowly() -> void:
	var move := EnemyTactics.move_direction(Vector2(IDEAL, 0), IDEAL, SLACK, 1.0)

	assert_almost_eq(move.dot(Vector2.RIGHT), 0.0, 0.001)
	assert_almost_eq(move.length(), EnemyTactics.STRAFE_SPEED, 0.001)


func test_enemies_circle_in_the_direction_they_were_given() -> void:
	var one_way := EnemyTactics.move_direction(Vector2(IDEAL, 0), IDEAL, SLACK, 1.0)
	var other_way := EnemyTactics.move_direction(Vector2(IDEAL, 0), IDEAL, SLACK, -1.0)

	assert_eq(one_way, -other_way)


func test_an_enemy_on_top_of_its_target_does_not_move() -> void:
	assert_eq(EnemyTactics.move_direction(Vector2.ZERO, IDEAL, SLACK, 1.0), Vector2.ZERO)


func test_an_enemy_attacks_only_when_its_target_is_within_reach() -> void:
	assert_true(EnemyTactics.can_attack(80.0, 12.0, 100.0))
	assert_false(EnemyTactics.can_attack(300.0, 12.0, 100.0))


func test_melee_fighters_want_to_be_closer_than_shooters_and_throwers() -> void:
	var sword := Sword.new().ideal_distance()
	var crossbow := Crossbow.new().ideal_distance()
	var wand := Wand.new().ideal_distance()
	var fireball := Fireball.new().ideal_distance()

	assert_lt(sword, crossbow)
	assert_lt(crossbow, wand)
	assert_lt(wand, fireball)
