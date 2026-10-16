class_name Exploration
extends RefCounted
## What the player can see right now and what they remember, like Dungeon Crawl's line of sight and map
## memory. Cells in view are visible; cells seen before stay known, so the map fills in as you explore.
## Knows no nodes: the caller says where the player is and what blocks sight.

## How far the player sees, in cells: farther than any weapon reaches, so nothing can hit you from the dark.
const SIGHT_RADIUS := 16

var _visible := {}  # Vector2i -> true
var _seen := {}  # Vector2i -> true


## Recomputes what is in view from origin. is_clear(cell) says whether sight passes through a cell; a cell
## that blocks sight (a wall) can itself still be seen.
func look_from(origin: Vector2i, is_clear: Callable) -> void:
	var clear_by_cell := {}  # Lines overlap a lot near the origin, so each cell is asked about once.
	var remembered_is_clear := func(cell: Vector2i) -> bool:
		if not clear_by_cell.has(cell):
			clear_by_cell[cell] = is_clear.call(cell)
		return clear_by_cell[cell]
	_visible = {origin: true}
	for y in range(-SIGHT_RADIUS, SIGHT_RADIUS + 1):
		for x in range(-SIGHT_RADIUS, SIGHT_RADIUS + 1):
			var target := origin + Vector2i(x, y)
			if Vector2(x, y).length() <= SIGHT_RADIUS and _line_is_clear(origin, target, remembered_is_clear):
				_visible[target] = true
	_seen.merge(_visible)


func is_visible(cell: Vector2i) -> bool:
	return _visible.has(cell)


func is_seen(cell: Vector2i) -> bool:
	return _seen.has(cell)


## True when every cell strictly between from and to lets sight through (a straight grid line).
static func _line_is_clear(from: Vector2i, to: Vector2i, is_clear: Callable) -> bool:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i in range(1, steps):
		var cell := Vector2i(Vector2(from).lerp(Vector2(to), float(i) / steps).round())
		if not is_clear.call(cell):
			return false
	return true
