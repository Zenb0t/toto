class_name VillageLotPacker
extends RefCounted
## The third step of the village: puts a lot on the ground left by the streets. A lot stands with its doorstep right
## beside a street (or, for the inn, the square), turned to face it and maybe mirrored; it keeps off the palisade,
## the streets and the other lots, and keeps a gap of open ground between its building and every other one. Of all
## the ways it can stand it takes one of those farthest from the lots already there (up to SPREAD_ENOUGH cells),
## and of those one of the snuggest (backed onto the palisade, along the streets), so the lots spread out along the
## streets instead of bunching up round the square. Pure: the caller passes the random number generator.

const BUILDING_LETTERS := "HICSM"
## Lots this many cells apart or more count as spread out enough: farther doesn't score better.
const SPREAD_ENOUGH := 8
## A cell next to the palisade counts double a cell next to a street.
const SNUG_PALISADE := 2
const SNUG_STREET := 1
## The least gap between two buildings unless told otherwise: one open cell, so no two ever touch.
const DEFAULT_GAP := 1


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
## face the square (the inn's). gap: the least number of open cells between its building and any other.
static func pack(
		grid: QuadrantGrid, layout: VillageLayout, lot_id: String, on_square: bool, rng: RandomNumberGenerator,
		gap := DEFAULT_GAP
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
			if not _fits(grid, layout, variant, rect, gap):
				continue
			var score := mini(_gap_to_lots(layout, rect), SPREAD_ENOUGH) * 1000 + _snugness(grid, layout, rect)
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


static func _fits(
		grid: QuadrantGrid, layout: VillageLayout, variant: VillageLots.Variant, rect: Rect2i, gap: int
) -> bool:
	if not layout.lot_area().encloses(rect):
		return false
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if grid.at(cell) != QuadrantGrid.GRASS or layout.taken.has(cell):
				return false
			if BUILDING_LETTERS.contains(variant.rows[y - rect.position.y][x - rect.position.x]) \
					and _has_a_building_near(grid, rect, cell, gap):
				return false
	return true


## Whether another building stands within `gap` cells of a building cell (counted the way a king moves).
static func _has_a_building_near(grid: QuadrantGrid, own: Rect2i, cell: Vector2i, gap: int) -> bool:
	for dy in range(-gap, gap + 1):
		for dx in range(-gap, gap + 1):
			var next := cell + Vector2i(dx, dy)
			if not own.has_point(next) and grid.contains(next) and BUILDING_LETTERS.contains(grid.at(next)):
				return true
	return false


## How many cells lie between a rectangle and the nearest lot already placed (SPREAD_ENOUGH when there is none).
static func _gap_to_lots(layout: VillageLayout, rect: Rect2i) -> int:
	var nearest := SPREAD_ENOUGH
	for other in layout.lot_rects:
		var across := maxi(maxi(other.position.x - rect.end.x, rect.position.x - other.end.x), 0)
		var down := maxi(maxi(other.position.y - rect.end.y, rect.position.y - other.end.y), 0)
		nearest = mini(nearest, maxi(across, down))
	return nearest


## How tightly a lot sits: the cells all round it that are the palisade or a street.
static func _snugness(grid: QuadrantGrid, layout: VillageLayout, rect: Rect2i) -> int:
	var score := 0
	for next in _cells_round(rect):
		if layout.is_street(next):
			score += SNUG_STREET
		elif not grid.contains(next) or grid.at(next) == Village.PALISADE:
			score += SNUG_PALISADE
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
	layout.lot_rects.append(rect)
