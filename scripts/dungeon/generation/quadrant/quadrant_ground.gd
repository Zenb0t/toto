class_name QuadrantGround
extends RefCounted
## The first generation step of a quadrant: the ground. Open grass, split into zones (see PlainsZones): a few hold
## a wood or a pond, the rest are meadow. Then single trees at the woods' edges and alone in the open (see
## PlainsWoods), a few small piles of rocks out in the meadows, and the middle kept clear for the village. Pure: the
## caller passes the random number generator.

## How rough a pond's edge is: its radius varies by this share, following noise.
const POND_WOBBLE := 0.35
const SHORE_WIDTH := 1.5
## A pile of rocks holds this many boulders at least and at most, within this many cells of its middle.
const ROCKS_PER_PILE_MIN := 2
const ROCKS_PER_PILE_MAX := 5
const ROCK_PILE_RADIUS := 2


static func lay(grid: QuadrantGrid, recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> void:
	var zones := PlainsZones.plan(recipe, rng)
	PlainsWoods.raise_woods(grid, recipe, zones, rng)
	_dig_ponds(grid, recipe, zones, rng)
	PlainsWoods.scatter_edge_trees(grid, recipe, rng)
	PlainsWoods.plant_lone_trees(grid, recipe, rng)
	_pile_rocks(grid, recipe, zones, rng)
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


## One pond in the middle of each pond zone, as big as the recipe allows.
static func _dig_ponds(
		grid: QuadrantGrid, recipe: QuadrantRecipe, zones: Array[PlainsZones.Zone], rng: RandomNumberGenerator
) -> void:
	var shape := FastNoiseLite.new()
	shape.seed = rng.randi()
	shape.frequency = 0.3
	for zone in PlainsZones.of_kind(zones, PlainsZones.Kind.POND):
		var radius := rng.randi_range(mini(recipe.pond_radius_min, recipe.pond_radius_max), recipe.pond_radius_max)
		_fill_pond(grid, zone.center, radius, shape)


## `recipe.rock_pile_count` small piles of boulders, each near the middle of a meadow zone away from the village
## (fewer if there are fewer such meadows).
static func _pile_rocks(
		grid: QuadrantGrid, recipe: QuadrantRecipe, zones: Array[PlainsZones.Zone], rng: RandomNumberGenerator
) -> void:
	var meadows := PlainsZones.of_kind(zones, PlainsZones.Kind.MEADOW).filter(func(zone: PlainsZones.Zone) -> bool:
		return Vector2(zone.center - recipe.center()).length() > recipe.village_radius() + ROCK_PILE_RADIUS * 2)
	for zone: PlainsZones.Zone in meadows.slice(0, recipe.rock_pile_count):
		var middle := zone.center + Vector2i(
			rng.randi_range(-ROCK_PILE_RADIUS, ROCK_PILE_RADIUS), rng.randi_range(-ROCK_PILE_RADIUS, ROCK_PILE_RADIUS))
		for _rock in rng.randi_range(ROCKS_PER_PILE_MIN, ROCKS_PER_PILE_MAX):
			var cell := middle + Vector2i(
				rng.randi_range(-ROCK_PILE_RADIUS, ROCK_PILE_RADIUS), rng.randi_range(-ROCK_PILE_RADIUS, ROCK_PILE_RADIUS))
			if recipe.interior().has_point(cell) and grid.at(cell) == QuadrantGrid.GRASS:
				grid.put(cell, QuadrantGrid.BOULDER)


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
