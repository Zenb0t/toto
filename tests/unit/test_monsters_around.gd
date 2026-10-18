extends GutTest
## When monsters around forbid resting: one hunting the hero anywhere, or an awake one in sight.

var _rule := MonstersAround.new()


func _hunter(cells := 60.0) -> MonstersAround.Nearby:
	return MonstersAround.Nearby.new(true, true, cells, false)


func _watcher(cells: float, in_line_of_sight := true) -> MonstersAround.Nearby:
	return MonstersAround.Nearby.new(true, false, cells, in_line_of_sight)


func _sleeper(cells: float) -> MonstersAround.Nearby:
	return MonstersAround.Nearby.new(false, false, cells, true)


func _check(monsters: Array[MonstersAround.Nearby]) -> MonstersAround.Verdict:
	return _rule.check(monsters)


func test_with_no_monsters_the_hero_may_rest() -> void:
	assert_eq(_check([]), MonstersAround.Verdict.CALM)


func test_rest_is_refused_while_a_monster_hunts_the_hero_however_far() -> void:
	assert_eq(_check([_hunter(80.0)]), MonstersAround.Verdict.HUNTED)


func test_rest_is_refused_with_an_awake_monster_in_sight() -> void:
	assert_eq(_check([_watcher(10.0)]), MonstersAround.Verdict.WATCHED)


func test_an_awake_monster_beyond_the_hero_sight_does_not_stop_them() -> void:
	assert_eq(_check([_watcher(_rule.sight_cells + 1.0)]), MonstersAround.Verdict.CALM)


func test_an_awake_monster_behind_a_wall_does_not_stop_them() -> void:
	assert_eq(_check([_watcher(5.0, false)]), MonstersAround.Verdict.CALM)


func test_sleeping_monsters_nearby_do_not_stop_them() -> void:
	assert_eq(_check([_sleeper(2.0), _sleeper(6.0)]), MonstersAround.Verdict.CALM)


func test_a_hunter_outranks_a_watcher() -> void:
	assert_eq(_check([_watcher(5.0), _hunter()]), MonstersAround.Verdict.HUNTED)


func test_the_sight_distance_is_tunable() -> void:
	_rule.sight_cells = 5.0

	assert_eq(_check([_watcher(8.0)]), MonstersAround.Verdict.CALM)
	assert_eq(_check([_watcher(4.0)]), MonstersAround.Verdict.WATCHED)


func test_each_refusal_has_a_message_and_a_calm_one_has_none() -> void:
	assert_ne(MonstersAround.message(MonstersAround.Verdict.HUNTED), "")
	assert_ne(MonstersAround.message(MonstersAround.Verdict.WATCHED), "")
	assert_eq(MonstersAround.message(MonstersAround.Verdict.CALM), "")
