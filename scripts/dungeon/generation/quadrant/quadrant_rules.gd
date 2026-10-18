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
	var start := grid.find(QuadrantGrid.START)
	var village := _village_of(placements)
	if village == null:
		return "there is no village"
	if start == QuadrantGrid.NO_CELL or not village.rect().has_point(start):
		return "the hero's start is not in the village"
	var reached := grid.reachable_from(start)
	for side in QuadrantExits.SIDES:
		if not reached.has(QuadrantExits.front_cell(recipe, side)):
			return "the exit on side %s can't be reached" % side
		for cell in QuadrantExits.barricade_cells(recipe, side):
			if grid.at(cell) != QuadrantGrid.BARRICADE:
				return "the exit on side %s is not barricaded" % side
		if not reached.has(village.origin + VillagePalisade.outside_cell(village.piece.size(), side)):
			return "the village gate on side %s doesn't open onto the plains" % side
	for placement in placements:
		if not reached.has(placement.anchor_cell()):
			return "the %s can't be reached" % placement.piece.id
	return ""


static func _village_of(placements: Array[SetPiecePlacer.Placement]) -> SetPiecePlacer.Placement:
	for placement in placements:
		if placement.piece.at_center:
			return placement
	return null
