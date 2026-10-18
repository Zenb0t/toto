class_name QuadrantRules
extends RefCounted
## The last generation step: checks a made quadrant against the rules a quadrant must keep. It changes nothing; it
## names the first rule that is broken (so a generator that retries, and a test that fails, can say why), or
## returns "" when all hold. Pure.


static func broken_rule(
		grid: QuadrantGrid, recipe: QuadrantRecipe, placements: Array[SetPiecePlacer.Placement]
) -> String:
	var area := recipe.interior()
	var share := float(grid.walkable_in(area)) / (area.size.x * area.size.y)
	if share < recipe.min_walkable_share:
		return "only %d%% of the ground can be walked on" % roundi(share * 100.0)
	var start := recipe.center()
	if grid.at(start) != QuadrantGrid.START:
		return "the hero's start is not in the middle"
	var reached := grid.reachable_from(start)
	for side in QuadrantExits.SIDES:
		if not reached.has(QuadrantExits.front_cell(recipe, side)):
			return "the exit on side %s can't be reached" % side
		for cell in QuadrantExits.barricade_cells(recipe, side):
			if grid.at(cell) != QuadrantGrid.BARRICADE:
				return "the exit on side %s is not barricaded" % side
	for placement in placements:
		if not reached.has(placement.anchor_cell()):
			return "the %s can't be reached" % placement.piece.id
	var ring_cells := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if Vector2(x - start.x, y - start.y).length() <= recipe.safe_ring and not grid.is_walkable(Vector2i(x, y)):
				ring_cells += 1
	if ring_cells > 0:
		return "the ring around the start is not clear"
	return ""
