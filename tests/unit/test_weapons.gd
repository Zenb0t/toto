extends GutTest

const ORIGIN := Vector2(10, 20)


func test_the_wand_fires_one_bolt_from_in_front_of_the_player() -> void:
	var attacks := MagicMissile.new().attacks(ORIGIN, Vector2(0, -5), 0.0)

	assert_eq(attacks.size(), 1)
	var bolt: Shot = attacks[0]
	assert_eq(bolt.direction, Vector2.UP)
	assert_eq(bolt.origin, ORIGIN + Vector2.UP * Weapon.MUZZLE_DISTANCE)
	assert_false(bolt.explodes())


func test_a_shot_flies_for_as_long_as_its_range_allows() -> void:
	var wand := MagicMissile.new()
	wand.shot_speed = 200.0
	wand.shot_range = 500.0

	var bolt: Shot = wand.attacks(ORIGIN, Vector2.RIGHT, 0.0)[0]

	assert_eq(bolt.lifetime(), 2.5)


func test_the_sword_swings_an_arc_from_the_player() -> void:
	var sword := Sword.new()

	var swing: Slash = sword.attacks(ORIGIN, Vector2.RIGHT, 0.0)[0]

	assert_eq(swing.origin, ORIGIN)
	assert_eq(swing.reach, sword.reach)
	assert_eq(swing.arc_degrees, sword.arc_degrees)


func test_the_fireball_is_lobbed_to_land_where_it_was_aimed() -> void:
	var fireball := Fireball.new()

	var shot: Shot = fireball.attacks(ORIGIN, Vector2.RIGHT, 150.0)[0]

	assert_true(shot.lobbed)
	assert_true(shot.explodes())
	assert_eq(shot.travel_range, 150.0)
	assert_eq(shot.blast_radius, fireball.blast_radius)


func test_the_fireball_never_lands_beyond_its_max_range() -> void:
	var fireball := Fireball.new()

	var shot: Shot = fireball.attacks(ORIGIN, Vector2.RIGHT, fireball.shot_range * 3.0)[0]

	assert_eq(shot.travel_range, fireball.shot_range)


func test_a_full_drag_aims_the_fireball_at_its_max_range() -> void:
	var fireball := Fireball.new()

	assert_eq(fireball.aim_distance(1.0), fireball.shot_range)


func test_a_short_drag_aims_the_fireball_closer_than_its_share_of_the_range() -> void:
	var fireball := Fireball.new()
	fireball.shot_range = 400.0
	fireball.aim_curve = 2.0

	assert_almost_eq(fireball.aim_distance(0.5), 100.0, 0.001)


func test_a_fireball_aim_curve_of_one_aims_in_proportion_to_the_drag() -> void:
	var fireball := Fireball.new()
	fireball.shot_range = 400.0
	fireball.aim_curve = 1.0

	assert_almost_eq(fireball.aim_distance(0.5), 200.0, 0.001)


func test_a_weapon_aims_in_proportion_to_the_drag_by_default() -> void:
	var wand := MagicMissile.new()

	assert_almost_eq(wand.aim_distance(0.25), wand.aim_range() * 0.25, 0.001)


func test_the_sword_sweeps_for_its_sweep_time() -> void:
	var sword := Sword.new()
	sword.sweep_seconds = 0.3

	var swing: Slash = sword.attacks(ORIGIN, Vector2.RIGHT, 0.0)[0]

	assert_eq(swing.sweep_seconds, 0.3)


func test_the_crossbow_fans_its_bolts_around_the_aim() -> void:
	var crossbow := Crossbow.new()
	crossbow.bolts = 3
	crossbow.spread_degrees = 40.0

	var directions: Array[Vector2] = []
	for bolt: Shot in crossbow.attacks(ORIGIN, Vector2.RIGHT, 0.0):
		directions.append(bolt.direction)

	assert_eq(directions.size(), 3)
	assert_almost_eq(directions[0], Vector2.RIGHT.rotated(deg_to_rad(-20)), Vector2(0.001, 0.001))
	assert_almost_eq(directions[1], Vector2.RIGHT, Vector2(0.001, 0.001))
	assert_almost_eq(directions[2], Vector2.RIGHT.rotated(deg_to_rad(20)), Vector2(0.001, 0.001))


func test_each_weapon_previews_its_own_shape() -> void:
	assert_eq(MagicMissile.new().aim_shape().kind, AimShape.Kind.LINE)
	assert_eq(Sword.new().aim_shape().kind, AimShape.Kind.CONE)
	assert_eq(Crossbow.new().aim_shape().kind, AimShape.Kind.FAN)
	assert_eq(Fireball.new().aim_shape().kind, AimShape.Kind.LOB)


func test_every_weapon_has_a_unique_id() -> void:
	var ids := GameTuning.weapon_ids()

	for id in ids:
		assert_eq(ids.count(id), 1, id)


func test_the_dash_preview_shows_how_far_one_dash_goes() -> void:
	var dash := Dash.new()
	dash.dash_speed = 600.0
	dash.dash_duration = 0.2

	assert_eq(dash.aim_range(), 120.0)
