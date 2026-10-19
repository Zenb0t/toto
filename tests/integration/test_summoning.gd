extends GutTest
## Summon Undead with real actor scenes in a real boss arena: the Lich telegraphs, skeletons rise between him and
## the hero, only living ones count toward the cap, they hunt at once and all collapse when he dies.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const CELL := DungeonView.TILE_SIZE

var _map: DungeonMap
var _lich_cell: Vector2i
var _hero_cell: Vector2i
var _raised_at: Array[Vector2i] = []
var _skeletons: Array[Enemy] = []


func before_each() -> void:
	_raised_at.clear()
	_skeletons.clear()
	_map = DungeonMapParser.new().parse(DungeonGenerator.new().generate(3, WorldLayout.FLOOR_COUNT))
	for spawn in _map.enemy_spawns:
		if _map.monster_at(spawn) == Lich.ID:
			_lich_cell = spawn
	_hero_cell = _arena_cell_about(8.0)
	assert_ne(_hero_cell, DungeonMap.NO_CELL, "a cell of the arena the Lich sees")


## A cell of the arena that the Lich sees, about distance cells from him.
func _arena_cell_about(distance: float) -> Vector2i:
	var pathfinder := Pathfinder.new(_map)
	for cell in _map.cells_of_room(_map.room_at(_lich_cell)):
		var apart := Vector2(cell - _lich_cell).length()
		if absf(apart - distance) < 0.5 and _map.is_standable(cell) \
				and pathfinder.can_see(DungeonView.cell_center(_lich_cell), DungeonView.cell_center(cell)):
			return cell
	return DungeonMap.NO_CELL


func _hero() -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = DungeonView.cell_center(_hero_cell)
	add_child_autofree(player)
	return player


## The Lich as main.gd builds him, with Summon Undead as his only spell but for the Cloud, and a Summoning to carry it out.
func _lich(hero: Player, spells := SpellPicker.new()) -> Enemy:
	var lich := Lich.new()
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.become(lich.monster())
	enemy.arm(GameTuning.monster_weapon(GameTuning.create(), lich.monster()))
	spells.pause_seconds = 0.1
	spells.phase_two_pause_seconds = 0.1
	spells.known = [SpellPicker.Spell.CLOUD, SpellPicker.Spell.SUMMON]
	enemy.spell_picker = spells
	enemy.spell_weapons = GameTuning.lich_spell_weapons(GameTuning.create())
	enemy.keep_distance_cells = lich.keep_distance_cells
	enemy.never_gives_up = true
	enemy.navigation = Pathfinder.new(_map)
	enemy.position = DungeonView.cell_center(_lich_cell)
	enemy.home = enemy.position
	add_child_autofree(enemy)
	add_child_autofree(Summoning.new(enemy, hero, _map, _raise))
	enemy.chase(hero)
	return enemy


func _raise(cell: Vector2i) -> Enemy:
	var skeleton: Enemy = ENEMY_SCENE.instantiate()
	var kind := Bestiary.by_id(Summoning.SKELETON_ID)
	skeleton.become(kind)
	skeleton.arm(GameTuning.monster_weapon(GameTuning.create(), kind))
	skeleton.position = DungeonView.cell_center(cell)
	add_child_autofree(skeleton)
	_raised_at.append(cell)
	_skeletons.append(skeleton)
	return skeleton


func _alive() -> int:
	var alive := 0
	for skeleton in _skeletons:
		if is_instance_valid(skeleton) and not skeleton.is_queued_for_deletion():
			alive += 1
	return alive


func test_skeletons_rise_between_the_lich_and_the_hero_within_the_summon_range() -> void:
	var hero := _hero()
	_lich(hero)

	await wait_seconds(2.5)

	assert_gt(_raised_at.size(), 0, "he summoned")
	var toward := Vector2(_hero_cell - _lich_cell)
	for cell in _raised_at:
		var offset := Vector2(cell - _lich_cell)
		assert_lte(offset.length(), SummonUndead.DEFAULT_RANGE_CELLS)
		assert_gt(offset.dot(toward.normalized()), 0.0, "in front of him")
		assert_lt(offset.dot(toward.normalized()), toward.length(), "short of the hero")
		assert_eq(_map.room_at(cell), _map.room_at(_lich_cell), "inside the arena")


func test_a_cast_raises_no_more_than_the_skeletons_per_summon() -> void:
	var hero := _hero()
	var lich := _lich(hero)
	var telegraphed: Array[int] = []
	lich.summon_telegraphed.connect(func(_caster: Enemy, count: int) -> void: telegraphed.append(count))

	await wait_seconds(1.6)

	assert_gt(telegraphed.size(), 0)
	assert_eq(telegraphed[0], SummonUndead.DEFAULT_SKELETONS_PER_SUMMON)


func test_the_spots_glow_during_the_telegraph_before_anything_rises() -> void:
	var hero := _hero()
	var lich := _lich(hero)
	var summoning: Summoning = get_children().filter(func(node: Node) -> bool: return node is Summoning)[0]
	var marked: Array[int] = []
	lich.summon_telegraphed.connect(func(_caster: Enemy, _count: int) -> void: marked.append(summoning.marked_cells().size()))

	await wait_seconds(0.8)

	assert_eq(_raised_at.size(), 0, "the wind-up is not over")
	assert_eq(marked.size(), 1)
	assert_gt(marked[0], 0, "the spots are marked")


func test_the_summoned_hunt_the_hero_at_once() -> void:
	var hero := _hero()
	_lich(hero)

	await wait_seconds(2.5)

	assert_gt(_skeletons.size(), 0)
	for skeleton in _skeletons:
		assert_true(skeleton.is_hunting())
		assert_true(skeleton.never_gives_up)


func test_he_keeps_summoning_until_the_cap_and_never_passes_it() -> void:
	var hero := _hero()
	var spells := SpellPicker.new()
	_lich(hero, spells)

	await wait_seconds(8.0)

	assert_eq(_alive(), spells.summon_cap, "the cap is filled and not passed")
	assert_eq(_raised_at.size(), spells.summon_cap, "and nothing is raised once it is full")


func test_a_skeleton_that_dies_frees_a_place_and_he_raises_another() -> void:
	var hero := _hero()
	var spells := SpellPicker.new()
	_lich(hero, spells)
	await wait_seconds(8.0)
	assert_eq(_alive(), spells.summon_cap)

	_skeletons[0].take_damage(_skeletons[0].health.maximum)
	await wait_seconds(3.0)

	assert_eq(_alive(), spells.summon_cap)
	assert_eq(_raised_at.size(), spells.summon_cap + 1)


func test_every_skeleton_collapses_when_the_lich_dies() -> void:
	var hero := _hero()
	var lich := _lich(hero)
	await wait_seconds(3.0)
	assert_gt(_alive(), 0)

	lich.take_damage(lich.health.maximum)
	await wait_physics_frames(2)

	assert_eq(_alive(), 0)


func test_skeletons_still_rising_when_the_lich_dies_never_stand_up() -> void:
	var hero := _hero()
	var lich := _lich(hero)
	await wait_seconds(1.1)  # his wind-up is over, the first pulse is not
	var before := _raised_at.size()

	lich.take_damage(lich.health.maximum)
	await wait_seconds(2.0)

	assert_eq(_raised_at.size(), before, "nothing rises after his death")
	assert_eq(_alive(), 0)


func test_a_pulse_that_ends_in_the_frame_the_lich_dies_raises_nothing() -> void:
	var hero := _hero()
	var lich := _lich(hero)
	var summoning: Summoning = get_children().filter(func(node: Node) -> bool: return node is Summoning)[0]
	await wait_seconds(1.1)  # his wind-up is over, the first pulse is not
	var before := _raised_at.size()

	lich.take_damage(lich.health.maximum)
	summoning._process(5.0)  # the rest of this frame, before anything queued is freed

	assert_eq(_raised_at.size(), before, "nothing rises after his death")


func test_with_the_hero_too_close_for_any_spot_he_casts_his_cloud_instead_of_an_empty_summon() -> void:
	_hero_cell = _arena_cell_about(2.0)
	assert_ne(_hero_cell, DungeonMap.NO_CELL, "a cell of the arena next to the Lich")
	var hero := _hero()
	var lich := _lich(hero)
	var summons: Array[int] = []
	lich.summon_telegraphed.connect(func(_caster: Enemy, count: int) -> void: summons.append(count))
	var attacks: Array[int] = []
	lich.attack_fired.connect(func(_attacks: Array) -> void: attacks.append(1))

	await wait_seconds(1.5)

	assert_eq(summons.size(), 0, "no summon with no ground between them")
	assert_gt(attacks.size(), 0, "he attacks instead")
