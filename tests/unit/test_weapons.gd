extends GutTest

const ORIGIN := Vector2(10, 20)


func test_the_wand_fires_one_bolt_from_in_front_of_the_player() -> void:
	var attacks := Wand.new().attacks(ORIGIN, Vector2(0, -5))

	assert_eq(attacks.size(), 1)
	var bolt: Shot = attacks[0]
	assert_eq(bolt.direction, Vector2.UP)
	assert_eq(bolt.origin, ORIGIN + Vector2.UP * Weapon.MUZZLE_DISTANCE)
	assert_false(bolt.explodes())


func test_a_shot_flies_for_as_long_as_its_range_allows() -> void:
	var wand := Wand.new()
	wand.shot_speed = 200.0
	wand.shot_range = 500.0

	var bolt: Shot = wand.attacks(ORIGIN, Vector2.RIGHT)[0]

	assert_eq(bolt.lifetime(), 2.5)


func test_the_sword_swings_an_arc_from_the_player() -> void:
	var sword := Sword.new()

	var swing: Slash = sword.attacks(ORIGIN, Vector2.RIGHT)[0]

	assert_eq(swing.origin, ORIGIN)
	assert_eq(swing.reach, sword.reach)
	assert_eq(swing.arc_degrees, sword.arc_degrees)


func test_the_fireball_explodes_with_its_blast_radius() -> void:
	var fireball := Fireball.new()

	var shot: Shot = fireball.attacks(ORIGIN, Vector2.RIGHT)[0]

	assert_true(shot.explodes())
	assert_eq(shot.blast_radius, fireball.blast_radius)


func test_the_crossbow_fans_its_bolts_around_the_aim() -> void:
	var crossbow := Crossbow.new()
	crossbow.bolts = 3
	crossbow.spread_degrees = 40.0

	var directions: Array[Vector2] = []
	for bolt: Shot in crossbow.attacks(ORIGIN, Vector2.RIGHT):
		directions.append(bolt.direction)

	assert_eq(directions.size(), 3)
	assert_almost_eq(directions[0], Vector2.RIGHT.rotated(deg_to_rad(-20)), Vector2(0.001, 0.001))
	assert_almost_eq(directions[1], Vector2.RIGHT, Vector2(0.001, 0.001))
	assert_almost_eq(directions[2], Vector2.RIGHT.rotated(deg_to_rad(20)), Vector2(0.001, 0.001))


func test_each_weapon_previews_its_own_shape() -> void:
	assert_eq(Wand.new().aim_shape().kind, AimShape.Kind.LINE)
	assert_eq(Sword.new().aim_shape().kind, AimShape.Kind.CONE)
	assert_eq(Crossbow.new().aim_shape().kind, AimShape.Kind.FAN)
	assert_gt(Fireball.new().aim_shape().end_radius, 0.0)


func test_every_weapon_has_a_unique_id() -> void:
	var ids := GameTuning.weapon_ids()

	for id in ids:
		assert_eq(ids.count(id), 1, id)


func test_the_dash_preview_shows_how_far_one_dash_goes() -> void:
	var utility := Utility.new()
	utility.dash_speed = 600.0
	utility.dash_duration = 0.2

	assert_eq(utility.aim_range(), 120.0)
