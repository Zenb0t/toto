class_name QuadrantRoads
extends RefCounted
## The generation step after the set pieces: dirt roads (QuadrantGrid.ROAD, `r` on the map) from the village's gates to
## some of the quadrant's exits, landmarks to follow across a big map. The seed picks which exits get one (the road
## leaves by the village gate on the same side). A road is 3 cells wide, and it wanders: its middle line is the cheapest
## way over the plains where the cost of a cell follows seeded low-frequency noise (QuadrantRecipe.road_bend), so it
## bends gently instead of running ruler-straight, and it goes round whatever is in the way.
## It keeps to open grass. Groves, boulders, ponds and the village are never crossed, and neither is a set piece (the
## crypt entrance, camps, campfires...): every piece other than the village is avoided with its apron and one more cell,
## so a road never touches one. Roads only recolour grass, so they change nothing about what can be walked on or seen,
## and nothing is placed on them afterwards. Two roads may run along or cross each other.
## All the roads are routed before any is drawn; if one can't be, nothing is drawn and the caller makes the map again.
## Pure: the caller passes the random number generator.

## How wide a road is, in cells.
const WIDTH := 3
## A road keeps this many cells off every set piece other than the village, beyond the piece's own apron.
const PIECE_GAP := 1
## The size, in cells, of the bends the noise gives a road (its frequency is the inverse).
const BEND_SIZE := 16.0


## Draws the roads and returns true, or draws nothing and returns false if one of them has no way through.
static func lay(
		grid: QuadrantGrid, recipe: QuadrantRecipe, placements: Array[SetPiecePlacer.Placement],
		rng: RandomNumberGenerator
) -> bool:
	var sides := _pick_sides(recipe.road_count, rng)
	if sides.is_empty():
		return true
	var open := _open_centres(grid, placements)
	var route := AStarGrid2D.new()
	route.region = Rect2i(Vector2i.ZERO, grid.size)
	route.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	route.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	route.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	route.update()
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 1.0 / BEND_SIZE
	for y in grid.size.y:
		for x in grid.size.x:
			var cell := Vector2i(x, y)
			route.set_point_solid(cell, not open.has(cell))
			route.set_point_weight_scale(cell, 1.0 + recipe.road_bend * (noise.get_noise_2dv(Vector2(cell)) + 1.0) / 2.0)
	var village := _village_of(placements)
	var roads: Array[Vector2i] = []
	for side in sides:
		var from_gate := village.origin + VillagePalisade.outside_cell(village.piece.size(), side)
		var to_exit := QuadrantExits.front_cell(recipe, side)
		var way := route.get_id_path(from_gate + side, to_exit - side)
		if way.is_empty():
			return false
		roads.append(from_gate)
		roads.append_array(way)
		roads.append(to_exit)
	for centre in roads:
		_paint(grid, centre)
	return true


## The cells a road's middle line may stand on: open grass all round it, the road's width over, and clear of the pieces.
static func _open_centres(grid: QuadrantGrid, placements: Array[SetPiecePlacer.Placement]) -> Dictionary:
	var avoided: Array[Rect2i] = []
	for placement in placements:
		if not placement.piece.at_center:
			avoided.append(placement.rect().grow(placement.piece.apron + PIECE_GAP))
	var reach := WIDTH / 2
	var open := {}
	for y in range(reach, grid.size.y - reach):
		for x in range(reach, grid.size.x - reach):
			var centre := Vector2i(x, y)
			if _is_open_all_round(grid, Rect2i(centre - Vector2i.ONE * reach, Vector2i.ONE * WIDTH), avoided):
				open[centre] = true
	return open


static func _is_open_all_round(grid: QuadrantGrid, footprint: Rect2i, avoided: Array[Rect2i]) -> bool:
	for area in avoided:
		if area.intersects(footprint):
			return false
	for y in range(footprint.position.y, footprint.end.y):
		for x in range(footprint.position.x, footprint.end.x):
			if grid.at(Vector2i(x, y)) != QuadrantGrid.GRASS:
				return false
	return true


## The road's width round a cell of its middle line, on grass only (the gate and the barricade stay as they are).
static func _paint(grid: QuadrantGrid, centre: Vector2i) -> void:
	var reach := WIDTH / 2
	for y in range(centre.y - reach, centre.y + reach + 1):
		for x in range(centre.x - reach, centre.x + reach + 1):
			var cell := Vector2i(x, y)
			if grid.contains(cell) and grid.at(cell) == QuadrantGrid.GRASS:
				grid.put(cell, QuadrantGrid.ROAD)


## Which sides get a road: that many of the four, picked by the seed (a shuffle).
static func _pick_sides(count: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var sides: Array[Vector2i] = QuadrantExits.SIDES.duplicate()
	for i in range(sides.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := sides[i]
		sides[i] = sides[j]
		sides[j] = swap
	return sides.slice(0, clampi(count, 0, sides.size()))


static func _village_of(placements: Array[SetPiecePlacer.Placement]) -> SetPiecePlacer.Placement:
	for placement in placements:
		if placement.piece.at_center:
			return placement
	return null
