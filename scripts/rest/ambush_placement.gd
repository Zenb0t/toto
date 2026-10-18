class_name AmbushPlacement
extends RefCounted
## Where an ambush arrives: cells just outside the campfire's light that the hero's side of the map can walk to,
## spread apart. Pure: it reads the map, and the same arguments give the same cells.

## Ambushers stand at least this many cells from each other.
const MIN_APART_CELLS := 1.5
## The cells it looks at lie in a band this thick, in cells, outside the light's edge; if that holds too few it
## widens by one cell at a time up to WIDEN_BY_CELLS more.
const BAND_CELLS := 1.5
const WIDEN_BY_CELLS := 5


## Up to count cells at about light_radius_cells + margin_cells from the fire. Fewer when the ground there can't
## hold them (never a cell the fire can't be walked to, water, lava or a doorway).
static func cells(
		map: DungeonMap, fire: Vector2i, light_radius_cells: float, margin_cells: float, count: int,
		rng: RandomNumberGenerator) -> Array[Vector2i]:
	var inner := light_radius_cells + margin_cells
	var reachable := _reachable(map, fire, inner + BAND_CELLS + WIDEN_BY_CELLS)
	var placed: Array[Vector2i] = []
	for widen in WIDEN_BY_CELLS + 1:
		placed = _spread(_ring(map, reachable, fire, inner, inner + BAND_CELLS + widen), count, rng)
		if placed.size() >= count:
			break
	return placed


static func _ring(
		map: DungeonMap, reachable: Array[Vector2i], fire: Vector2i, inner: float, outer: float) -> Array[Vector2i]:
	var ring: Array[Vector2i] = []
	for cell in reachable:
		var apart := Vector2(cell - fire).length()
		if apart >= inner and apart <= outer and map.is_standable(cell) and not map.is_door(cell):
			ring.append(cell)
	return ring


## count cells of the ring picked at random, keeping them apart.
static func _spread(ring: Array[Vector2i], count: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var shuffled := ring.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Vector2i = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = swap
	var picked: Array[Vector2i] = []
	for cell: Vector2i in shuffled:
		if picked.size() >= count:
			break
		if picked.all(func(other: Vector2i) -> bool: return Vector2(cell - other).length() >= MIN_APART_CELLS):
			picked.append(cell)
	return picked


## The cells within max_cells of the fire that can be walked to from it (four ways, in a fixed order).
static func _reachable(map: DungeonMap, fire: Vector2i, max_cells: float) -> Array[Vector2i]:
	var seen := {fire: true}
	var order: Array[Vector2i] = [fire]
	var next := 0
	while next < order.size():
		var cell := order[next]
		next += 1
		for step in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var neighbour: Vector2i = cell + step
			if seen.has(neighbour) or not map.is_walkable(neighbour):
				continue
			if Vector2(neighbour - fire).length() > max_cells:
				continue
			seen[neighbour] = true
			order.append(neighbour)
	return order
