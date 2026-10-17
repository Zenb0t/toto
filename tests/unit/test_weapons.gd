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


func test_every_arc_weapon_sweeps_its_own_reach_and_arc_from_the_player() -> void:
	for weapon: ArcWeapon in [Dagger.new(), Sword.new(), Battleaxe.new()]:
		var swing: Slash = weapon.attacks(ORIGIN, Vector2.RIGHT, 0.0)[0]

		assert_eq(swing.origin, ORIGIN, weapon.id)
		assert_eq(swing.reach, weapon.reach, weapon.id)
		assert_eq(swing.arc_degrees, weapon.arc_degrees, weapon.id)
		assert_eq(weapon.aim_shape().kind, AimShape.Kind.CONE, weapon.id)


func test_the_dagger_reaches_less_and_hits_lighter_than_the_sword_but_reloads_faster() -> void:
	var dagger := Dagger.new()
	var sword := Sword.new()

	assert_lt(dagger.reach, sword.reach)
	assert_lt(dagger.arc_degrees, sword.arc_degrees)
	assert_lt(dagger.damage, sword.damage)
	assert_lt(dagger.reload, sword.reload)


func test_two_dagger_stabs_kill_a_goblin_and_three_kill_a_bandit() -> void:
	var damage := Dagger.new().damage

	assert_lte(Bestiary.by_id("goblin").max_health, damage * 2)
	assert_lte(Bestiary.by_id("bandit").max_health, damage * 3)
	assert_gt(Bestiary.by_id("bandit").max_health, damage * 2)


func test_the_fireball_is_lobbed_to_land_where_it_was_aimed() -> void:
	var fireball := Fireball.new()

	var shot: Shot = fireball.attacks(ORIGIN, Vector2.RIGHT, 150.0)[0]

	assert_true(shot.lobbed)
	assert_true(shot.explodes())
	assert_eq(shot.travel_range, 150.0)
	assert_eq(shot.blast_radius, fireball.blast_radius)


func test_the_fireball_leaves_burning_ground_over_its_blast() -> void:
	var fireball := Fireball.new()

	var shot: Shot = fireball.attacks(ORIGIN, Vector2.RIGHT, 150.0)[0]

	assert_true(shot.leaves_burning_ground())
	assert_eq(shot.burn_damage, fireball.burn_damage)
	assert_eq(shot.burn_seconds, fireball.burn_seconds)


func test_a_fireball_without_burn_time_leaves_no_fire() -> void:
	var fireball := Fireball.new()
	fireball.burn_seconds = 0.0

	var shot: Shot = fireball.attacks(ORIGIN, Vector2.RIGHT, 150.0)[0]

	assert_false(shot.leaves_burning_ground())


func test_the_fireballs_burn_is_tunable() -> void:
	var fields := Fireball.new().knobs().map(func(knob: Knob) -> String: return knob.field)

	assert_has(fields, "burn_damage")
	assert_has(fields, "burn_seconds")


func test_the_fireball_never_lands_beyond_its_max_range() -> void:
	var fireball := Fireball.new()

	var shot: Shot = fireball.attacks(ORIGIN, Vector2.RIGHT, fireball.shot_range * 3.0)[0]

	assert_eq(shot.travel_range, fireball.shot_range)


func test_a_full_drag_aims_the_fireball_at_its_max_range() -> void:
	var fireball := Fireball.new()

	assert_eq(fireball.aim_distance(1.0), fireball.shot_range)


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


func test_a_lightning_bolt_chains_like_jessies_shot_instead_of_piercing() -> void:
	var bolt: Shot = LightningBolt.new().attacks(Vector2.ZERO, Vector2.RIGHT, 0.0)[0]

	assert_false(bolt.pierces)
	assert_eq(bolt.bounces, 0)
	assert_gt(bolt.chains, 0)


func test_a_mephitic_cloud_is_lobbed_where_aimed_and_leaves_a_cloud() -> void:
	var weapon := MephiticCloud.new()

	var shot: Shot = weapon.attacks(Vector2.ZERO, Vector2.UP, 200.0)[0]

	assert_true(shot.lobbed)
	assert_true(shot.leaves_cloud())
	assert_eq(shot.travel_range, 200.0)
	assert_false(shot.explodes())
	assert_false(weapon.needs_line_of_sight())


func test_a_mephitic_cloud_gives_a_grace_window_and_keeps_its_500_total() -> void:
	var weapon := MephiticCloud.new()
	var shot: Shot = weapon.attacks(Vector2.ZERO, Vector2.UP, 200.0)[0]

	assert_eq(shot.first_tick_delay, 0.6)
	var ticks := floori((shot.cloud_seconds - shot.first_tick_delay) / PoisonCloud.TICK_SECONDS + 0.001) + 1
	assert_eq(ticks * shot.damage, 500)


func test_a_battleaxe_hits_harder_and_wider_than_a_sword_but_slower() -> void:
	var axe := Battleaxe.new()
	var sword := Sword.new()

	assert_gt(axe.damage, sword.damage)
	assert_gt(axe.arc_degrees, sword.arc_degrees)
	assert_gt(axe.reload, sword.reload)
	assert_gt(axe.windup, sword.windup)
	assert_ne(axe.id, sword.id)


func test_knuckles_throw_a_quick_flurry_of_short_punches() -> void:
	var knuckles := Knuckles.new()

	var punches := knuckles.attacks(Vector2.ZERO, Vector2.RIGHT, 0.0)

	assert_eq(punches.size(), knuckles.punches)
	for index in punches.size():
		var punch: Shot = punches[index]
		assert_almost_eq(punch.delay, index * knuckles.punch_gap, 0.0001)
		assert_eq(punch.travel_range, knuckles.punch_range)


func test_knuckle_punches_alternate_sides_of_the_aim() -> void:
	var punches := Knuckles.new().attacks(Vector2.ZERO, Vector2.RIGHT, 0.0)

	assert_lt((punches[0] as Shot).direction.y, 0.0)
	assert_gt((punches[1] as Shot).direction.y, 0.0)


func test_knuckles_reach_less_far_than_any_shooting_weapon() -> void:
	var knuckles := Knuckles.new()

	for shooter: Weapon in [MagicMissile.new(), Crossbow.new(), LightningBolt.new()]:
		assert_lt(knuckles.aim_range(), shooter.aim_range(), shooter.id)


func _arrow(held_seconds: float, bow := Bow.new()) -> Shot:
	return bow.charged_attacks(ORIGIN, Vector2.RIGHT, 0.0, held_seconds)[0]


func test_a_quick_tap_of_the_bow_fires_a_weak_arrow_that_does_not_pierce() -> void:
	var bow := Bow.new()

	var arrow := _arrow(0.0, bow)

	assert_eq(arrow.damage, bow.min_damage)
	assert_false(arrow.pierces)


func test_a_fully_charged_arrow_does_the_most_damage_and_pierces() -> void:
	var bow := Bow.new()

	var arrow := _arrow(bow.full_charge_seconds, bow)

	assert_eq(arrow.damage, bow.max_damage)
	assert_true(arrow.pierces)


func test_charging_a_bow_past_full_is_capped() -> void:
	var bow := Bow.new()

	assert_eq(_arrow(bow.full_charge_seconds * 5.0, bow).damage, bow.max_damage)


func test_a_bow_arrow_hits_harder_the_longer_it_is_drawn() -> void:
	var bow := Bow.new()

	var short := _arrow(bow.full_charge_seconds * 0.25, bow).damage
	var long := _arrow(bow.full_charge_seconds * 0.75, bow).damage

	assert_gt(short, bow.min_damage)
	assert_gt(long, short)
	assert_lt(long, bow.max_damage)


func test_a_half_drawn_arrow_does_not_pierce() -> void:
	assert_false(_arrow(Bow.new().full_charge_seconds * 0.9).pierces)


func test_an_attacker_that_does_not_charge_shoots_the_bow_fully_charged() -> void:
	var bow := Bow.new()

	var arrow: Shot = bow.attacks(ORIGIN, Vector2.RIGHT, 0.0)[0]

	assert_eq(arrow.damage, bow.max_damage)
	assert_true(arrow.pierces)


func test_the_bow_shoots_one_arrow_from_in_front_of_the_player() -> void:
	var attacks := Bow.new().charged_attacks(ORIGIN, Vector2.UP, 0.0, 0.0)

	assert_eq(attacks.size(), 1)
	assert_eq((attacks[0] as Shot).origin, ORIGIN + Vector2.UP * Weapon.MUZZLE_DISTANCE)


func test_the_bow_reaches_farther_and_flies_faster_than_the_crossbow() -> void:
	var bow := Bow.new()
	var crossbow := Crossbow.new()

	assert_gt(bow.aim_range(), crossbow.aim_range())
	assert_gt(bow.shot_speed, crossbow.shot_speed)


func test_the_bow_previews_a_line() -> void:
	assert_eq(Bow.new().aim_shape().kind, AimShape.Kind.LINE)


func test_only_the_bow_charges_and_slows_the_hero_while_drawn() -> void:
	assert_gt(Bow.new().charge_seconds(), 0.0)
	assert_lt(Bow.new().charging_move_share(), 1.0)
	for other: Weapon in [MagicMissile.new(), Crossbow.new(), Sword.new(), Fireball.new()]:
		assert_eq(other.charge_seconds(), 0.0, other.id)
		assert_eq(other.charging_move_share(), 1.0, other.id)


func test_a_weapon_that_does_not_charge_attacks_the_same_however_long_the_button_was_held() -> void:
	var wand := MagicMissile.new()

	var tapped: Shot = wand.charged_attacks(ORIGIN, Vector2.RIGHT, 0.0, 0.0)[0]
	var held: Shot = wand.charged_attacks(ORIGIN, Vector2.RIGHT, 0.0, 5.0)[0]

	assert_eq(tapped.damage, held.damage)
