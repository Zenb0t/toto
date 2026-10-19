class_name SummonSpots
extends RefCounted
## Where Summon Undead raises skeletons: floor spots within the summon range of the caster, between him and the
## hero, in the caster's own room (the boss arena), on ground a skeleton can stand on (never a pillar, a wall,
## water, lava, a doorway or a boulder), away from the caster, from the hero and from each other, and off cells that
## are already taken. Pure: it reads the map, and the same arguments give the same spots.
##
## "Between" means in front of the caster along the line to the hero (past MIN_FROM_CASTER_CELLS, short of the
## hero by MIN_FROM_HERO_CELLS) and no farther off that line than half the range, so the skeletons stand in the
## hero's way and not in a ring round the Lich. A hero too close for any such spot gets no skeletons
## (and the Lich casts another spell, see Enemy.summon_ground).

## Skeletons rise at least this far from the caster, from the hero and from each other, in cells.
const MIN_FROM_CASTER_CELLS := 1.5
const MIN_FROM_HERO_CELLS := 1.5
const MIN_APART_CELLS := 1.5


## Up to count spots (fewer when the ground between them can't hold that many), in the order they rise.
static func spots(
		map: DungeonMap, caster: Vector2i, hero: Vector2i, range_cells: float, count: int, taken: Array[Vector2i],
		rng: RandomNumberGenerator) -> Array[Vector2i]:
	var picked: Array[Vector2i] = []
	if count <= 0 or caster == hero:
		return picked
	var candidates := _candidates(map, caster, hero, range_cells, taken)
	_shuffle(candidates, rng)
	for cell in candidates:
		if picked.size() >= count:
			break
		if picked.all(func(other: Vector2i) -> bool: return Vector2(cell - other).length() >= MIN_APART_CELLS):
			picked.append(cell)
	return picked


static func _candidates(
		map: DungeonMap, caster: Vector2i, hero: Vector2i, range_cells: float, taken: Array[Vector2i]) -> Array[Vector2i]:
	var toward := Vector2(hero - caster)
	var line := toward.normalized()
	var reach := ceili(range_cells)
	var cells: Array[Vector2i] = []
	for y in range(caster.y - reach, caster.y + reach + 1):
		for x in range(caster.x - reach, caster.x + reach + 1):
			var cell := Vector2i(x, y)
			var offset := Vector2(cell - caster)
			if offset.length() > range_cells or cell in taken or not _is_floor(map, cell):
				continue
			if map.room_at(cell) != map.room_at(caster):
				continue
			var along := offset.dot(line)
			var aside := absf(offset.cross(line))
			if along < MIN_FROM_CASTER_CELLS or along > toward.length() - MIN_FROM_HERO_CELLS:
				continue
			if aside > range_cells / 2.0 or Vector2(cell - hero).length() < MIN_FROM_HERO_CELLS:
				continue
			cells.append(cell)
	return cells


static func _is_floor(map: DungeonMap, cell: Vector2i) -> bool:
	return map.is_standable(cell) and not map.is_door(cell) and map.blocker_at(cell) == DungeonMap.NO_BLOCKER


## Fisher-Yates with the given generator, so the order is the generator's.
static func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[j]
		cells[j] = swap
