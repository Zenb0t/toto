class_name PlainsWoods
extends RefCounted
## The trees of the plains, in three kinds:
##   woods     one in each wood zone (see PlainsZones): a round wood whose edge wanders with seeded noise
##   edge      single trees scattered just outside every wood and the forest border, thinning out with distance,
##             so the land doesn't stop at a hard line of trees
##   lone      a few trees standing alone in the open, evenly spread
## Each wood is rounded off (GroveSmoothing) before the single trees go in. Pure: the caller passes the random numbers.

## How much a wood's edge wanders in and out, as a share of its radius.
const EDGE_WOBBLE := 0.35
## About how many cells across the edge's bumps are.
const WOBBLE_SIZE := 7.0
const SMOOTHING_PASSES := 2
## Single trees at a wood's edge: about this far apart, out to this many cells from it, and the chance of one
## right beside the wood (it falls off to nothing at the far end).
const EDGE_TREE_SPACING := 2.5
const EDGE_DEPTH := 3
const EDGE_TREE_CHANCE := 0.6
## Lone trees stand at least this far apart, and this far from any wood.
const LONE_TREE_SPACING := 7.0
const LONE_TREE_CLEARANCE := 4


## The woods, rounded off. Each fills about `recipe.wood_reach` of its zone's room (less by the border).
static func raise_woods(
		grid: QuadrantGrid, recipe: QuadrantRecipe, zones: Array[PlainsZones.Zone], rng: RandomNumberGenerator
) -> void:
	var wobble := FastNoiseLite.new()
	wobble.seed = rng.randi()
	wobble.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	wobble.frequency = 1.0 / WOBBLE_SIZE
	var inside := recipe.interior()
	for zone in PlainsZones.of_kind(zones, PlainsZones.Kind.WOOD):
		var radius := PlainsZones.wood_radius(zone, recipe)
		var extent := ceili(radius * (1.0 + EDGE_WOBBLE))
		for dy in range(-extent, extent + 1):
			for dx in range(-extent, extent + 1):
				var cell := zone.center + Vector2i(dx, dy)
				var edge := radius * (1.0 + EDGE_WOBBLE * wobble.get_noise_2dv(Vector2(cell)))
				if inside.has_point(cell) and Vector2(dx, dy).length() <= edge:
					grid.put(cell, QuadrantGrid.GROVE)
		var around := Rect2i(zone.center - Vector2i.ONE * extent, Vector2i.ONE * (extent * 2 + 1)).grow(1)
		GroveSmoothing.smooth(grid, around.intersection(inside), SMOOTHING_PASSES)


## Single trees round every wood and along the inside of the forest border.
static func scatter_edge_trees(grid: QuadrantGrid, recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> void:
	var near_trees := _distances_to_trees(grid, recipe.interior(), EDGE_DEPTH)
	for cell in PoissonDisc.sample(recipe.interior(), EDGE_TREE_SPACING, rng):
		if grid.at(cell) != QuadrantGrid.GRASS or not near_trees.has(cell):
			continue
		var chance := EDGE_TREE_CHANCE * (1.0 - float(near_trees[cell] - 1) / EDGE_DEPTH)
		if rng.randf() < chance:
			grid.put(cell, QuadrantGrid.GROVE)


## `recipe.lone_tree_count` trees out in the open (fewer if the open ground has no room for them all).
static func plant_lone_trees(grid: QuadrantGrid, recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> void:
	var near_trees := _distances_to_trees(grid, recipe.interior(), LONE_TREE_CLEARANCE)
	var spots := PoissonDisc.sample(recipe.interior(), LONE_TREE_SPACING, rng).filter(
		func(cell: Vector2i) -> bool: return grid.at(cell) == QuadrantGrid.GRASS and not near_trees.has(cell))
	_shuffle(spots, rng)
	for cell: Vector2i in spots.slice(0, recipe.lone_tree_count):
		grid.put(cell, QuadrantGrid.GROVE)


## For every cell of `area` within `limit` cells of a tree (counted the way a king moves), how far the nearest
## tree is. One sweep outward from all the trees at once.
static func _distances_to_trees(grid: QuadrantGrid, area: Rect2i, limit: int) -> Dictionary:
	var distances := {}  # Vector2i -> int
	var frontier: Array[Vector2i] = []
	for y in range(area.position.y - 1, area.end.y + 1):
		for x in range(area.position.x - 1, area.end.x + 1):
			var cell := Vector2i(x, y)
			if grid.contains(cell) and grid.at(cell) == QuadrantGrid.GROVE:
				frontier.append(cell)
	for ring in range(1, limit + 1):
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var next := cell + Vector2i(dx, dy)
					if area.has_point(next) and not distances.has(next) and grid.at(next) != QuadrantGrid.GROVE:
						distances[next] = ring
						next_frontier.append(next)
		frontier = next_frontier
	return distances


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held: Variant = items[i]
		items[i] = items[j]
		items[j] = held
