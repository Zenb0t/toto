class_name VillageStreets
extends RefCounted
## The second step of the village, before any lot: the streets. A plus of three-wide streets runs from the four
## gates to a 9x9 square with the well in the middle. The seed moves the square a little off the middle (so the
## streets don't always cross at the same spot) and the lots are packed along what is left. Pure: the caller
## passes the random number generator.

const WIDTH := 3
const SQUARE_SIDE := 9
## How far the seed may move the square off the middle of the village, on each axis.
const MAX_OFFSET := 2
const WELL_SIDE := 3


static func lay(grid: QuadrantGrid, rng: RandomNumberGenerator) -> VillageLayout:
	var layout := VillageLayout.new(grid.size)
	var middle := grid.size / 2
	var centre := middle + Vector2i(rng.randi_range(-MAX_OFFSET, MAX_OFFSET), rng.randi_range(-MAX_OFFSET, MAX_OFFSET))
	layout.square = Rect2i(centre - Vector2i.ONE * (SQUARE_SIDE / 2), Vector2i.ONE * SQUARE_SIDE)
	var half := WIDTH / 2
	layout.streets = [
		Rect2i(middle.x - half, 1, WIDTH, layout.square.position.y - 1),
		Rect2i(middle.x - half, layout.square.end.y, WIDTH, grid.size.y - 1 - layout.square.end.y),
		Rect2i(1, middle.y - half, layout.square.position.x - 1, WIDTH),
		Rect2i(layout.square.end.x, middle.y - half, grid.size.x - 1 - layout.square.end.x, WIDTH),
	]
	for street in layout.streets:
		grid.fill_rect(street, Village.STREET)
	grid.fill_rect(layout.square, Village.STREET)
	grid.fill_rect(Rect2i(centre - Vector2i.ONE * (WELL_SIDE / 2), Vector2i.ONE * WELL_SIDE), Village.WELL)
	return layout
