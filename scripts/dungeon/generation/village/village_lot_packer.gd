class_name VillageLotPacker
extends RefCounted
## The third step of the village: puts a lot on the ground left by the streets. A lot stands with its doorstep right
## beside a street (or, for the inn, the square), turned to face it and maybe mirrored; it keeps off the palisade,
## the streets and the other lots, and never touches another building. Of all the ways it can stand it takes one
## of the snuggest (the most neighbours: the palisade, other lots, the streets), so the lots end up packed along
## the street edges. Pure: the caller passes the random number generator.

const BUILDING_LETTERS := "HICSM"
## A cell next to the palisade or another lot counts double a cell next to a street.
const SNUG_NEIGHBOUR := 2
const SNUG_STREET := 1


## Where a lot ended up.
class Placed:
	extends RefCounted
	var lot_id: String
	var kind: Village.Kind
	var rect: Rect2i
	## The way its door faces.
	var facing: Vector2i
	var doorstep: Vector2i
	## The street or square cell in front of the doorstep.
	var front: Vector2i

	func _init(id: String, building_kind: Village.Kind, area: Rect2i, door_faces: Vector2i, door: Vector2i) -> void:
		lot_id = id
		kind = building_kind
		rect = area
		facing = door_faces
		doorstep = door
		front = door + door_faces


## Stamps the lot on the grid and returns where it went, or null if it fits nowhere. on_square: its doorstep must
## face the square (the inn's).
static func pack(
		grid: QuadrantGrid, layout: VillageLayout, lot_id: String, on_square: bool, rng: RandomNumberGenerator
) -> Placed:
	var fronts: Array[Vector2i] = layout.square_cells() if on_square else layout.street_cells()
	var best: Array[Placed] = []
	var best_variants: Array[VillageLots.Variant] = []
	var best_score := -1
	for variant: VillageLots.Variant in VillageLots.variants(lot_id):
		for front in fronts:
			var doorstep := front - variant.facing
			if not grid.contains(doorstep) or grid.at(doorstep) != QuadrantGrid.GRASS or layout.taken.has(doorstep):
				continue
			var origin := doorstep - variant.doorstep
			var rect := Rect2i(origin, variant.size())
			if not _fits(grid, layout, variant, rect):
				continue
			var score := _snugness(grid, layout, rect)
			if score > best_score:
				best_score = score
				best.clear()
				best_variants.clear()
			if score == best_score:
				best.append(Placed.new(lot_id, variant.kind, rect, variant.facing, doorstep))
				best_variants.append(variant)
	if best.is_empty():
		return null
	var pick := rng.randi_range(0, best.size() - 1)
	_stamp(grid, layout, best_variants[pick], best[pick].rect)
	return best[pick]


static func _fits(grid: QuadrantGrid, layout: VillageLayout, variant: VillageLots.Variant, rect: Rect2i) -> bool:
	if not layout.lot_area().encloses(rect):
		return false
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if grid.at(cell) != QuadrantGrid.GRASS or layout.taken.has(cell):
				return false
			if BUILDING_LETTERS.contains(variant.rows[y - rect.position.y][x - rect.position.x]) \
					and _touches_a_building(grid, rect, cell):
				return false
	return true


## Whether another building stands in one of the eight cells around a building cell.
static func _touches_a_building(grid: QuadrantGrid, own: Rect2i, cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var next := cell + Vector2i(dx, dy)
			if not own.has_point(next) and grid.contains(next) and BUILDING_LETTERS.contains(grid.at(next)):
				return true
	return false


## How tightly a lot sits: the cells all round it that are the palisade, another lot or a street.
static func _snugness(grid: QuadrantGrid, layout: VillageLayout, rect: Rect2i) -> int:
	var score := 0
	for next in _cells_round(rect):
		if layout.is_street(next):
			score += SNUG_STREET
		elif not grid.contains(next) or grid.at(next) == Village.PALISADE or layout.taken.has(next):
			score += SNUG_NEIGHBOUR
	return score


static func _cells_round(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(rect.position.x, rect.end.x):
		cells.append(Vector2i(x, rect.position.y - 1))
		cells.append(Vector2i(x, rect.end.y))
	for y in range(rect.position.y, rect.end.y):
		cells.append(Vector2i(rect.position.x - 1, y))
		cells.append(Vector2i(rect.end.x, y))
	return cells


## Draws the lot. Only the inn keeps its doorstep marked: the other lots' doorsteps are plain ground.
static func _stamp(
		grid: QuadrantGrid, layout: VillageLayout, variant: VillageLots.Variant, rect: Rect2i
) -> void:
	for y in rect.size.y:
		for x in rect.size.x:
			var cell := rect.position + Vector2i(x, y)
			var symbol := variant.rows[y][x]
			if symbol == Village.DOORSTEP and variant.kind != Village.Kind.INN:
				symbol = QuadrantGrid.GRASS
			grid.put(cell, symbol)
			layout.taken[cell] = true
