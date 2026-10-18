class_name QuadrantGround
extends RefCounted
## The first generation step of a quadrant: the ground. Grass everywhere, seeded-noise tree groves, boulders
## and ponds (deep water with a shallow shore), then the middle kept clear for the village. Pure: the
## caller passes the random number generator.

const NOISE_OCTAVES := 2
## How rough a pond's edge is: its radius varies by this share, following noise.
const POND_WOBBLE := 0.35
const SHORE_WIDTH := 1.5
## Ponds stay this far from the border and from the village.
const POND_MARGIN := 3
const PLACEMENT_TRIES := 20


static func lay(grid: QuadrantGrid, recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> void:
	_raise_groves(grid, recipe, rng)
	_scatter_boulders(grid, recipe, rng)
	_dig_ponds(grid, recipe, rng)
	_clear_village_spot(grid, recipe)


## Turns walkable cells that can't be reached from `from` into groves, so no pocket of ground is cut off by the
## trees, ponds and boulders around it.
static func seal_pockets(grid: QuadrantGrid, from: Vector2i) -> void:
	var reached := grid.reachable_from(from)
	for y in grid.size.y:
		for x in grid.size.x:
			var cell := Vector2i(x, y)
			if grid.is_walkable(cell) and not reached.has(cell):
				grid.put(cell, QuadrantGrid.GROVE)


## Groves are where seeded noise is highest: the threshold is picked so exactly the recipe's share of the cells
## inside the border is grove, however the noise falls.
static func _raise_groves(grid: QuadrantGrid, recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> void:
	var area := recipe.interior()
	if recipe.grove_share <= 0.0:
		return
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 1.0 / maxf(recipe.grove_size, 1.0)
	noise.fractal_octaves = NOISE_OCTAVES
	var values: Array[float] = []
	var cells: Array[Vector2i] = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			cells.append(Vector2i(x, y))
			values.append(noise.get_noise_2d(x, y))
	var sorted := values.duplicate()
	sorted.sort()
	var cutoff: float = sorted[clampi(floori(sorted.size() * (1.0 - recipe.grove_share)), 0, sorted.size() - 1)]
	for i in cells.size():
		if values[i] >= cutoff:
			grid.put(cells[i], QuadrantGrid.GROVE)


static func _scatter_boulders(grid: QuadrantGrid, recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> void:
	var area := recipe.interior()
	for _i in recipe.boulder_count:
		var cell := Vector2i(
			rng.randi_range(area.position.x, area.end.x - 1), rng.randi_range(area.position.y, area.end.y - 1))
		if grid.at(cell) == QuadrantGrid.GRASS:
			grid.put(cell, QuadrantGrid.BOULDER)


static func _dig_ponds(grid: QuadrantGrid, recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> void:
	var shape := FastNoiseLite.new()
	shape.seed = rng.randi()
	shape.frequency = 0.3
	for _i in recipe.pond_count:
		var radius := rng.randi_range(mini(recipe.pond_radius_min, recipe.pond_radius_max), recipe.pond_radius_max)
		var reach := radius + ceili(SHORE_WIDTH) + POND_MARGIN
		var room := recipe.interior().grow(-reach)
		if room.size.x <= 0 or room.size.y <= 0:
			continue
		for _try in PLACEMENT_TRIES:
			var middle := Vector2i(
				rng.randi_range(room.position.x, room.end.x - 1), rng.randi_range(room.position.y, room.end.y - 1))
			if Vector2(middle - recipe.center()).length() > recipe.village_radius() + reach:
				_fill_pond(grid, middle, radius, shape)
				break


static func _fill_pond(grid: QuadrantGrid, middle: Vector2i, radius: int, shape: FastNoiseLite) -> void:
	var extent := radius + ceili(SHORE_WIDTH) + 1
	for dy in range(-extent, extent + 1):
		for dx in range(-extent, extent + 1):
			var cell := middle + Vector2i(dx, dy)
			var edge := radius * (1.0 + POND_WOBBLE * shape.get_noise_2dv(Vector2(cell)))
			var distance := Vector2(dx, dy).length()
			if distance <= edge:
				grid.put(cell, QuadrantGrid.DEEP_WATER)
			elif distance <= edge + SHORE_WIDTH:
				grid.put(cell, QuadrantGrid.SHALLOW_WATER)


## The ground the village will stand on, and the grass round it, as open grass.
static func _clear_village_spot(grid: QuadrantGrid, recipe: QuadrantRecipe) -> void:
	var village := Rect2i(recipe.center() - recipe.village_size() / 2, recipe.village_size())
	grid.fill_rect(village.grow(SetPieces.VILLAGE_APRON).intersection(recipe.interior()), QuadrantGrid.GRASS)
