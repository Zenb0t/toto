extends GutTest
## Aiming at the mouse cursor.

const PLAYER := Vector2(100, 100)


func test_the_attack_goes_toward_the_cursor() -> void:
	var aim := MouseAim.toward(PLAYER, PLAYER + Vector2(0, -50), MagicMissile.new(), Vector2.RIGHT)

	assert_false(aim.is_auto)
	assert_almost_eq(aim.direction, Vector2.UP, Vector2.ONE * 0.001)


func test_a_cursor_right_on_the_player_aims_the_way_they_face() -> void:
	var aim := MouseAim.toward(PLAYER, PLAYER, MagicMissile.new(), Vector2.LEFT)

	assert_eq(aim.direction, Vector2.LEFT)


func test_weapons_that_aim_at_a_spot_land_on_the_cursor() -> void:
	for weapon: Weapon in [Fireball.new(), MephiticCloud.new(), MagicMissile.new()]:
		var cursor_distance := weapon.aim_range() * 0.4

		var aim := MouseAim.toward(PLAYER, PLAYER + Vector2(cursor_distance, 0), weapon, Vector2.RIGHT)

		assert_almost_eq(weapon.aim_distance(aim.strength), cursor_distance, 0.01, weapon.id)


func test_a_cursor_beyond_the_weapons_reach_aims_as_far_as_it_goes() -> void:
	var fireball := Fireball.new()

	var aim := MouseAim.toward(PLAYER, PLAYER + Vector2(fireball.shot_range * 3, 0), fireball, Vector2.RIGHT)

	assert_eq(aim.strength, 1.0)


func test_a_utility_only_needs_the_way_to_the_cursor() -> void:
	assert_almost_eq(MouseAim.direction(PLAYER, PLAYER + Vector2(30, 30), Vector2.UP),
		Vector2(1, 1).normalized(), Vector2.ONE * 0.001)
