class_name GroveSmoothing
extends RefCounted
## Rounds woods off, like a cellular automaton: a grass cell mostly surrounded by trees becomes trees (no nooks or
## holes inside a wood), and a tree cell with few trees round it becomes grass (no ragged specks). Only grass and
## trees change; water, rocks and anything stamped stay as they are. Pure.

## Of the eight cells round a cell, this many trees or more turn grass into trees...
const FILL_AT := 5
## ...and this many or fewer turn trees into grass.
const THIN_AT := 2


## Runs `passes` rounds over the cells of `area`; each round reads the grid as the last one left it.
static func smooth(grid: QuadrantGrid, area: Rect2i, passes: int) -> void:
	for _pass in passes:
		var changes := {}  # Vector2i -> the symbol it becomes
		for y in range(area.position.y, area.end.y):
			for x in range(area.position.x, area.end.x):
				var cell := Vector2i(x, y)
				var symbol := grid.at(cell)
				if symbol != QuadrantGrid.GRASS and symbol != QuadrantGrid.GROVE:
					continue
				var trees := _trees_round(grid, cell)
				if symbol == QuadrantGrid.GRASS and trees >= FILL_AT:
					changes[cell] = QuadrantGrid.GROVE
				elif symbol == QuadrantGrid.GROVE and trees <= THIN_AT:
					changes[cell] = QuadrantGrid.GRASS
		for cell: Vector2i in changes:
			grid.put(cell, changes[cell])


static func _trees_round(grid: QuadrantGrid, cell: Vector2i) -> int:
	var count := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var next := cell + Vector2i(dx, dy)
			if (dx != 0 or dy != 0) and grid.contains(next) and grid.at(next) == QuadrantGrid.GROVE:
				count += 1
	return count
