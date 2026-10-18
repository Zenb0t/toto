class_name VillagePalisade
extends RefCounted
## The first step of the village: the palisade round it, with a gate in the middle of each side. A gate is three
## cells wide, in line with the plains' own exit on that side. Pure.


static func raise(grid: QuadrantGrid) -> void:
	var size := grid.size
	grid.fill_rect(Rect2i(0, 0, size.x, 1), Village.PALISADE)
	grid.fill_rect(Rect2i(0, size.y - 1, size.x, 1), Village.PALISADE)
	grid.fill_rect(Rect2i(0, 0, 1, size.y), Village.PALISADE)
	grid.fill_rect(Rect2i(size.x - 1, 0, 1, size.y), Village.PALISADE)
	for side in QuadrantExits.SIDES:
		for cell in gate_cells(size, side):
			grid.put(cell, Village.GATE)


## The three cells of the gate on a side (the direction one leaves the village by).
static func gate_cells(size: Vector2i, side: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in range(-1, 2):
		if side.y != 0:
			cells.append(Vector2i(size.x / 2 + offset, 0 if side.y < 0 else size.y - 1))
		else:
			cells.append(Vector2i(0 if side.x < 0 else size.x - 1, size.y / 2 + offset))
	return cells


## The cell just outside the palisade, in front of the middle of a gate.
static func outside_cell(size: Vector2i, side: Vector2i) -> Vector2i:
	return gate_cells(size, side)[1] + side
