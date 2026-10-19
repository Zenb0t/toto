extends GutTest
## The trees of the plains: round woods in their zones, single trees thinning out from every wood's edge, and a
## few lone trees out in the open.

const SEEDS := 6

var _recipe := QuadrantRecipe.plains()


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## A plains' ground with only its woods.
func _woods(seed_value: int) -> Array:
	var rng := _rng(seed_value)
	var grid := QuadrantGrid.new(_recipe.size())
	var zones := PlainsZones.plan(_recipe, rng)
	PlainsWoods.raise_woods(grid, _recipe, zones, rng)
	return [grid, zones]


func _trees_in(grid: QuadrantGrid, area: Rect2i) -> int:
	var count := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if grid.at(Vector2i(x, y)) == QuadrantGrid.GROVE:
				count += 1
	return count


func test_each_wood_zone_holds_a_wood_round_its_middle() -> void:
	for seed_value in SEEDS:
		var made := _woods(seed_value)
		var grid: QuadrantGrid = made[0]
		for zone in PlainsZones.of_kind(made[1], PlainsZones.Kind.WOOD):
			assert_eq(grid.at(zone.center), QuadrantGrid.GROVE, "seed %d" % seed_value)


func test_meadows_hold_no_wood() -> void:
	for seed_value in SEEDS:
		var made := _woods(seed_value)
		var grid: QuadrantGrid = made[0]
		for zone in PlainsZones.of_kind(made[1], PlainsZones.Kind.MEADOW):
			var middle := Rect2i(zone.center, Vector2i.ZERO).grow(2)
			assert_eq(_trees_in(grid, middle), 0, "seed %d" % seed_value)


func test_single_trees_stand_only_near_a_wood() -> void:
	var made := _woods(1)
	var grid: QuadrantGrid = made[0]
	var before := grid.ascii()

	PlainsWoods.scatter_edge_trees(grid, _recipe, _rng(1))

	var after := grid.ascii()
	var width := grid.size.x + 1  # each row ends in a newline
	var added := 0
	for i in after.length():
		if after[i] == QuadrantGrid.GROVE and before[i] != QuadrantGrid.GROVE:
			added += 1
			var cell := Vector2i(i % width, i / width)
			var near := Rect2i(cell, Vector2i.ONE).grow(PlainsWoods.EDGE_DEPTH)
			var trees_near := 0
			for y in range(near.position.y, near.end.y):
				for x in range(near.position.x, near.end.x):
					if before[y * width + x] == QuadrantGrid.GROVE:
						trees_near += 1
			assert_gt(trees_near, 0, "the tree at %s stands by a wood" % cell)
	assert_gt(added, 0)


func test_the_recipe_sets_how_many_lone_trees_stand_in_the_open() -> void:
	var grid := QuadrantGrid.new(_recipe.size())

	PlainsWoods.plant_lone_trees(grid, _recipe, _rng(2))

	assert_eq(_trees_in(grid, _recipe.interior()), _recipe.lone_tree_count)


func test_lone_trees_stand_apart() -> void:
	var grid := QuadrantGrid.new(_recipe.size())
	PlainsWoods.plant_lone_trees(grid, _recipe, _rng(3))
	var trees: Array[Vector2i] = []
	for y in grid.size.y:
		for x in grid.size.x:
			if grid.at(Vector2i(x, y)) == QuadrantGrid.GROVE:
				trees.append(Vector2i(x, y))

	for tree in trees:
		for other in trees:
			if other != tree:
				assert_gt(Vector2(tree).distance_to(Vector2(other)), PlainsWoods.LONE_TREE_SPACING - 2.0)
