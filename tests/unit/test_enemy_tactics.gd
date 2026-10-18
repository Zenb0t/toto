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


func test_melee_fighters_want_to_be_closer_than_shooters() -> void:
	var sword := Sword.new().ideal_distance()
	var crossbow := Crossbow.new().ideal_distance()
	var wand := MagicMissile.new().ideal_distance()

	assert_lt(sword, crossbow)
	assert_lt(crossbow, wand)


func test_throwers_keep_well_clear_of_their_own_blast() -> void:
	var fireball := Fireball.new()

	assert_gt(fireball.ideal_distance(), fireball.blast_radius * 2.0)


func test_an_enemy_far_from_its_flank_spot_circles_toward_it() -> void:
	var toward_spot := EnemyTactics.move_direction(Vector2(IDEAL, 0), IDEAL, SLACK, 1.0, 1.0)
	var other_side := EnemyTactics.move_direction(Vector2(IDEAL, 0), IDEAL, SLACK, 1.0, -1.0)

	assert_almost_eq(toward_spot.length(), 1.0, 0.001)
	assert_almost_eq(toward_spot.dot(Vector2.RIGHT), 0.0, 0.001)
	assert_eq(toward_spot, -other_side)


func test_a_flanking_enemy_circles_the_way_a_positive_flank_gap_points() -> void:
	var circling := EnemyTactics.move_direction(Vector2(IDEAL, 0), IDEAL, SLACK, 1.0)
	var flanking := EnemyTactics.move_direction(Vector2(IDEAL, 0), IDEAL, SLACK, 1.0, 1.0)

	assert_gt(circling.dot(flanking), 0.0)


func test_a_distant_flanking_enemy_closes_in_while_it_circles() -> void:
	var move := EnemyTactics.move_direction(Vector2(500, 0), IDEAL, SLACK, 1.0, 1.0)

	assert_gt(move.dot(Vector2.RIGHT), 0.0)
	assert_lt(move.dot(Vector2.RIGHT), 0.99)


func test_an_enemy_close_to_its_flank_spot_circles_slowly_as_usual() -> void:
	var near_spot := EnemyTactics.move_direction(Vector2(IDEAL, 0), IDEAL, SLACK, 1.0, 0.05)

	assert_almost_eq(near_spot.length(), EnemyTactics.STRAFE_SPEED, 0.001)


func test_enemies_aim_ahead_of_a_moving_target() -> void:
	var aim := EnemyTactics.lead(Vector2(200, 0), Vector2(0, 100), 0.5, 1.0)

	assert_eq(aim, Vector2(200, 50))


func test_with_no_lead_enemies_aim_at_where_the_target_is() -> void:
	assert_eq(EnemyTactics.lead(Vector2(200, 0), Vector2(0, 100), 0.5, 0.0), Vector2(200, 0))


func test_shots_take_time_to_fly_but_blows_land_at_once() -> void:
	assert_gt(MagicMissile.new().travel_seconds(300.0), 0.0)
	assert_eq(Sword.new().travel_seconds(300.0), 0.0)


func test_a_wanderer_never_strolls_farther_from_home_than_its_radius() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var home := Vector2(100, 50)

	var farthest := 0.0
	for _try in 200:
		farthest = maxf(farthest, home.distance_to(EnemyTactics.wander_goal(home, 64.0, rng)))

	assert_lte(farthest, 64.0)
	assert_gt(farthest, 32.0, "it uses the room it has")
