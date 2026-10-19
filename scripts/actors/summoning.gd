class_name Summoning
extends Node2D
## Carries out a caster's Summon Undead in the world (the Enemy only announces it): when the cast begins it picks the
## spots (see SummonSpots) between the caster and the hero and marks them with a glow; when the wind-up ends the
## spots pulse one after another, and as each pulse ends a skeleton stands up there, hunting the hero at once.
## Skeletons never give up inside the caster's room and keep to it. They are the caster's own (Enemy.adopt): they
## count toward his summon cap while they live, and from the moment their spot starts to pulse, and all collapse when
## he dies, which also cancels what is still rising. The visuals are drawn in code. Add it to the world the actors
## live in, at the origin.
##
## `raise` is the world's way to make a skeleton at a cell: it builds the Enemy (kind, weapon, tuning, wiring) and
## adds it to the world, and returns it.

const GLOW_COLOR := Color(0.62, 0.35, 0.9)
const SPOT_RADIUS := 15.0
## The band the skeletons make, clear of the rooms' (from 0), the camps' (1,000,000) and the ambushes' (3,000,000).
const BAND_ID := 4_000_000
## Each skeleton is raised from this kind.
const SKELETON_ID := "skeleton"

var caster: Enemy
var hero: Node2D
var map: DungeonMap
## Callable(cell: Vector2i) -> Enemy
var raise: Callable

var _rng := RandomNumberGenerator.new()
## The spots marked for the cast being wound up: they only glow.
var _glowing: Array[Spot] = []
## The spots of casts that were released: they pulse, and their skeleton stands up when the pulse is over.
var _rising: Array[Spot] = []
var _time := 0.0


## One spot: where, and when (on the clock of this node) its pulse starts and ends.
class Spot:
	extends RefCounted
	var cell: Vector2i
	var pulse_start := 0.0
	var pulse_end := 0.0

	func _init(at: Vector2i) -> void:
		cell = at


func _init(summoner: Enemy, target: Node2D, floor_map: DungeonMap, factory: Callable) -> void:
	caster = summoner
	hero = target
	map = floor_map
	raise = factory
	_rng.randomize()
	z_index = 1
	summoner.summon_ground = _has_ground
	summoner.summon_telegraphed.connect(_on_telegraphed)
	summoner.summon_cast.connect(_on_cast)
	summoner.defeated.connect(_on_caster_defeated)


## The cells marked now, glowing or pulsing: where skeletons are to stand.
func marked_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for spot in _glowing + _rising:
		cells.append(spot.cell)
	return cells


func _process(delta: float) -> void:
	if is_queued_for_deletion():
		return  # the caster died earlier this frame: nothing more rises
	_time += delta
	for spot in _rising.duplicate():
		if _time >= spot.pulse_end:
			_rising.erase(spot)
			_raise_at(spot.cell)
	queue_redraw()


func _on_telegraphed(_caster: Enemy, count: int) -> void:
	_glowing.clear()
	for cell in _spots(count):
		_glowing.append(Spot.new(cell))


## Whether a skeleton could rise now (see Enemy.summon_ground): the hero may stand too close for any spot.
func _has_ground() -> bool:
	return not _spots(1).is_empty()


func _spots(count: int) -> Array[Vector2i]:
	var summon: SummonUndead = caster.spell_weapons.get(SpellPicker.Spell.SUMMON, SummonUndead.new())
	return SummonSpots.spots(
		map, DungeonView.world_to_cell(caster.global_position), DungeonView.world_to_cell(hero.global_position),
		summon.summon_range_cells, count, _occupied_cells(), _rng)


## The wind-up is over: the glowing spots start to pulse, one after another.
func _on_cast(_caster: Enemy) -> void:
	var summon: SummonUndead = caster.weapon
	for index in _glowing.size():
		var spot := _glowing[index]
		spot.pulse_start = _time + index * summon.rise_interval_seconds
		spot.pulse_end = spot.pulse_start + summon.rise_seconds
		_rising.append(spot)
	caster.expect_minions(_glowing.size())
	_glowing.clear()


func _on_caster_defeated(_caster: Enemy) -> void:
	queue_free()


func _raise_at(cell: Vector2i) -> void:
	var skeleton: Enemy = raise.call(cell)
	skeleton.never_gives_up = true
	skeleton.wander_cells = _room_cells(cell)
	skeleton.navigation = caster.navigation
	skeleton.ambush(hero, caster.home)
	caster.adopt(skeleton)


func _room_cells(cell: Vector2i) -> Dictionary:
	var cells := {}
	for each in map.cells_of_room(map.room_at(cell)):
		cells[each] = true
	return cells


## The cells of the hero, every monster and the spots already marked, which nothing rises from.
func _occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [DungeonView.world_to_cell(hero.global_position)]
	for node in get_tree().get_nodes_in_group(Enemy.GROUP):
		cells.append(DungeonView.world_to_cell((node as Enemy).global_position))
	cells.append_array(marked_cells())
	return cells


func _draw() -> void:
	for spot in _glowing:
		_draw_glow(spot)
	for spot in _rising:
		if _time < spot.pulse_start:
			_draw_glow(spot)
			continue
		var center := DungeonView.cell_center(spot.cell)
		var progress := inverse_lerp(spot.pulse_start, spot.pulse_end, _time)
		var pulse := 0.5 + 0.5 * sin(progress * TAU * 2.0)
		draw_circle(center, SPOT_RADIUS * (0.8 + 0.5 * progress), Color(GLOW_COLOR, 0.35 + 0.4 * pulse))
		draw_arc(center, SPOT_RADIUS, 0.0, TAU, 24, Color(GLOW_COLOR, 0.9), 2.0, true)


func _draw_glow(spot: Spot) -> void:
	var center := DungeonView.cell_center(spot.cell)
	draw_circle(center, SPOT_RADIUS, Color(GLOW_COLOR, 0.3))
	draw_arc(center, SPOT_RADIUS, 0.0, TAU, 24, Color(GLOW_COLOR, 0.9), 2.0, true)
