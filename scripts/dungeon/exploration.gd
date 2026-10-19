class_name Exploration
extends RefCounted
## What the player can see right now and what they remember, like Dungeon Crawl's line of sight and map
## memory. Cells in view are visible; cells seen before stay known, so the map fills in as you explore.
## Knows no nodes: the caller says where the player is and what blocks sight.

## How far the player sees, in cells: farther than any weapon reaches, so nothing can hit you from the dark.
const SIGHT_RADIUS := 16
## Outdoors the land is open and the camera stands farther back, so the hero sees farther.
const OUTDOOR_SIGHT_RADIUS := 22

## How far the player sees from here, in cells (SIGHT_RADIUS, or OUTDOOR_SIGHT_RADIUS outdoors).
var sight_radius := SIGHT_RADIUS

var _visible := {}  # Vector2i -> true
var _seen := {}  # Vector2i -> true
var _changed: Array[Vector2i] = []


## Recomputes what is in view from origin. is_clear(cell) says whether sight passes through a cell; a cell
## that blocks sight (a wall) can itself still be seen.
func look_from(origin: Vector2i, is_clear: Callable) -> void:
	var clear_by_cell := {}  # Lines overlap a lot near the origin, so each cell is asked about once.
	var remembered_is_clear := func(cell: Vector2i) -> bool:
		if not clear_by_cell.has(cell):
			clear_by_cell[cell] = is_clear.call(cell)
		return clear_by_cell[cell]
	var before := _visible
	_visible = {origin: true}
	for y in range(-sight_radius, sight_radius + 1):
		for x in range(-sight_radius, sight_radius + 1):
			var target := origin + Vector2i(x, y)
			if Vector2(x, y).length() <= sight_radius and _line_is_clear(origin, target, remembered_is_clear):
				_visible[target] = true
	_seen.merge(_visible)
	_changed = _difference(before, _visible)
	_changed.append_array(_difference(_visible, before))


## The cells the last look_from changed: those that came into view (a cell seen for the first time is one) and
## those that left it. Everything else looks as it did, so a view only needs to redraw these.
func changed_cells() -> Array[Vector2i]:
	return _changed.duplicate()


func is_visible(cell: Vector2i) -> bool:
	return _visible.has(cell)


func is_seen(cell: Vector2i) -> bool:
	return _seen.has(cell)


## Every cell seen so far, to keep when the map is left (see restore).
func seen_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(_seen.keys())
	return cells


## Remembers cells seen on an earlier visit, as if they had been seen again. What is in view is unchanged.
## They are not counted in changed_cells(): a view shows the whole exploration again after a restore.
func restore(cells: Array[Vector2i]) -> void:
	for cell in cells:
		_seen[cell] = true


## The cells of one set that are not in the other.
static func _difference(cells: Dictionary, without: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if not without.has(cell):
			result.append(cell)
	return result


## True when every cell strictly between from and to lets sight through (a straight grid line).
static func _line_is_clear(from: Vector2i, to: Vector2i, is_clear: Callable) -> bool:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i in range(1, steps):
		var cell := Vector2i(Vector2(from).lerp(Vector2(to), float(i) / steps).round())
		if not is_clear.call(cell):
			return false
	return true
