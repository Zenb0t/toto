extends GutTest
## The Lich's Bone Spray: 3 waves of 5 shards over a half circle, each wave offset from the last, starting a little
## way out from him. The pattern is pure; the shots are built from it.

const CELL := DungeonView.TILE_SIZE


func test_it_is_three_waves_of_five_shards() -> void:
	var spray := BoneSpray.new()

	assert_eq(spray.waves, 3)
	assert_eq(spray.shards_per_wave, 5)
	assert_eq(spray.attacks(Vector2.ZERO, Vector2.RIGHT, 0.0).size(), 15)
	for wave in 3:
		assert_eq(spray.shard_directions(Vector2.RIGHT, wave).size(), 5, "wave %d" % wave)


func test_the_first_wave_fans_over_a_half_circle_centred_on_the_aim() -> void:
	var spray := BoneSpray.new()

	var angles := spray.wave_angles_degrees(0)

	assert_eq(angles, [-90.0, -45.0, 0.0, 45.0, 90.0])
	assert_almost_eq(angles[-1] - angles[0], 180.0, 0.001)


func test_each_wave_is_offset_from_the_last() -> void:
	var spray := BoneSpray.new()

	for wave in range(1, spray.waves):
		var before := spray.wave_angles_degrees(wave - 1)
		var now := spray.wave_angles_degrees(wave)
		for index in now.size():
			assert_almost_eq(absf(now[index] - before[index]), spray.wave_offset_degrees, 0.001, "wave %d" % wave)


func test_the_default_offset_puts_the_next_wave_through_the_gaps_of_the_one_before() -> void:
	var spray := BoneSpray.new()
	var gap := spray.spread_degrees / (spray.shards_per_wave - 1)

	assert_almost_eq(spray.wave_offset_degrees, gap / 2.0, 0.001)


func test_the_shards_fly_toward_where_the_hero_is() -> void:
	var spray := BoneSpray.new()

	var up := spray.shard_directions(Vector2.UP, 0)

	assert_almost_eq(Vector2.UP.angle_to(up[2]), 0.0, 0.001, "the middle shard flies at the hero")
	assert_almost_eq(Vector2.UP.angle_to(up[0]), -PI / 2.0, 0.001, "the outer ones fly to either side of the Lich")
	assert_almost_eq(Vector2.UP.angle_to(up[4]), PI / 2.0, 0.001)


func test_the_shards_start_a_little_way_out_from_him_each_along_its_own_direction() -> void:
	var spray := BoneSpray.new()
	var origin := Vector2(100, 50)

	for direction in spray.shard_directions(Vector2.RIGHT, 0):
		var start := spray.start_point(origin, direction)
		assert_almost_eq(start.distance_to(origin), spray.start_distance_cells * CELL, 0.01)
		assert_almost_eq((start - origin).normalized().dot(direction), 1.0, 0.001)
	assert_gt(spray.start_distance_cells, 0.0)


func test_the_waves_follow_each_other_at_the_wave_interval() -> void:
	var spray := BoneSpray.new()

	assert_eq(spray.wave_delay(0), 0.0)
	assert_almost_eq(spray.wave_delay(1), spray.wave_interval_seconds, 0.0001)
	assert_almost_eq(spray.wave_delay(2), 2.0 * spray.wave_interval_seconds, 0.0001)


func test_the_shots_carry_the_pattern_with_the_delay_of_their_wave() -> void:
	var spray := BoneSpray.new()

	var shots := spray.attacks(Vector2.ZERO, Vector2.RIGHT, 0.0)

	for wave in 3:
		for index in 5:
			var shot: Shot = shots[wave * 5 + index]
			assert_almost_eq(shot.delay, spray.wave_delay(wave), 0.0001)
			assert_almost_eq(shot.direction.angle(), deg_to_rad(spray.wave_angles_degrees(wave)[index]), 0.001)
			assert_eq(shot.speed, spray.shard_speed)
			assert_eq(shot.damage, spray.damage)
			assert_false(shot.lobbed, "ordinary shots, so walls and pillars stop them")


func test_waves_shards_spread_and_offset_are_tunable() -> void:
	var spray := BoneSpray.new()
	spray.waves = 2
	spray.shards_per_wave = 3
	spray.spread_degrees = 120.0
	spray.wave_offset_degrees = 30.0

	assert_eq(spray.attacks(Vector2.ZERO, Vector2.RIGHT, 0.0).size(), 6)
	assert_eq(spray.wave_angles_degrees(0), [-60.0, 0.0, 60.0])
	assert_eq(spray.wave_angles_degrees(1), [-30.0, 30.0, 90.0])


func test_every_number_of_the_spray_is_a_knob_that_defaults_to_the_class() -> void:
	var tuning := GameTuning.create()
	var tuned: BoneSpray = GameTuning.lich_spell_weapons(tuning)[SpellPicker.Spell.BONE_SPRAY]

	for field in ["shards_per_wave", "waves", "spread_degrees", "wave_offset_degrees", "wave_interval_seconds",
			"shard_speed", "shard_range", "damage", "start_distance_cells", "windup"]:
		assert_not_null(tuning.param(GameTuning.key("bone_spray", field)), field)
		assert_eq(tuned.get(field), BoneSpray.new().get(field), field)


func test_tuned_spray_numbers_make_a_different_spray() -> void:
	var tuning := GameTuning.create()
	tuning.set_value(GameTuning.key("bone_spray", "waves"), 5)
	tuning.set_value(GameTuning.key("bone_spray", "shards_per_wave"), 7)

	var tuned: BoneSpray = GameTuning.lich_spell_weapons(tuning)[SpellPicker.Spell.BONE_SPRAY]

	assert_eq(tuned.waves, 5)
	assert_eq(tuned.attacks(Vector2.ZERO, Vector2.RIGHT, 0.0).size(), 35)
