class_name VillageProps
extends RefCounted
## The last step of the village: barrels and crates (dungeon props) on a share of the ground the lots left over.
## A prop only goes where it can't wall anything off: every neighbour a walker could step to stays joined to the
## others round it. Pure: the caller passes the random number generator.

## The eight cells around one, in order round it (edges at the odd places).
const RING: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0),
	Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0),
]
## Props keep this far from the gates, so the way in stays open.
const GATE_CLEARANCE := 3


## Puts props on `share` of the leftover ground. Returns how many it placed.
static func scatter(grid: QuadrantGrid, layout: VillageLayout, share: float, rng: RandomNumberGenerator) -> int:
	var leftovers := _leftovers(grid, layout)
	var wanted := roundi(leftovers.size() * share)
	_shuffle(leftovers, rng)
	var placed := 0
	for cell in leftovers:
		if placed >= wanted:
			break
		if _keeps_ground_together(grid, cell):
			grid.put(cell, Village.PROP)
			placed += 1
	return placed


## The ground that is no street, no lot and not at a gate.
static func _leftovers(grid: QuadrantGrid, layout: VillageLayout) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var gates: Array[Vector2i] = []
	for side in QuadrantExits.SIDES:
		gates.append(VillagePalisade.gate_cells(grid.size, side)[1])
	for y in range(1, grid.size.y - 1):
		for x in range(1, grid.size.x - 1):
			var cell := Vector2i(x, y)
			if grid.at(cell) == QuadrantGrid.GRASS and not layout.taken.has(cell) and not layout.is_street(cell) \
					and not _near_a_gate(cell, gates):
				cells.append(cell)
	return cells


static func _near_a_gate(cell: Vector2i, gates: Array[Vector2i]) -> bool:
	for gate in gates:
		if maxi(absi(cell.x - gate.x), absi(cell.y - gate.y)) <= GATE_CLEARANCE:
			return true
	return false


## Whether blocking a cell leaves everyone who could step off it still joined: the walkable cells beside it must
## all be in one run of walkable cells round it.
static func _keeps_ground_together(grid: QuadrantGrid, cell: Vector2i) -> bool:
	var open: Array[bool] = []
	for step in RING:
		open.append(grid.is_walkable(cell + step))
	var group := [-1, -1, -1, -1, -1, -1, -1, -1]
	var groups := 0
	for i in 8:
		if not open[i] or group[i] != -1:
			continue
		var j := i
		while open[j % 8] and group[j % 8] == -1:
			group[j % 8] = groups
			j += 1
		j = i - 1
		while open[(j + 8) % 8] and group[(j + 8) % 8] == -1:
			group[(j + 8) % 8] = groups
			j -= 1
		groups += 1
	var edge_group := -1
	for i in [1, 3, 5, 7]:
		if not open[i]:
			continue
		if edge_group == -1:
			edge_group = group[i]
		elif group[i] != edge_group:
			return false
	return true


static func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept := cells[i]
		cells[i] = cells[j]
		cells[j] = kept
