class_name QuadrantGenerator
extends RefCounted
## Builds a quadrant as an ASCII map (the format DungeonMapParser reads) from a recipe and a seed, in small steps:
##   ground → border → exits → the village → reserve set-piece spots → fill the camps → place set pieces → roads → validate
## A step that breaks a rule (no spot for a piece, a cut-off exit, too little open ground) doesn't fail the map:
## the whole thing is made again with the next random numbers. The same recipe and seed always give the same map.
## If every try fails (a recipe asking for the impossible), the last resort is the same quadrant without groves,
## boulders and ponds. If that breaks a rule too (a small plains with no room for its camps or no corner for its ruin),
## it is the same without the camps and campfires, then without the ruin, then without both; a ruin with no corner
## anywhere beside the village is given up after the first try, not after every one. If even that breaks a rule
## (a set piece that fits nowhere at the tuned size, say), it is the default recipe without them, so a tuning never
## leaves the world without a map.

## How many times the steps run before the last resort.
const MAX_ATTEMPTS := 40
## The rule a try breaks when the ruin has no corner anywhere beside the village: trying again can't help, so the
## generator goes straight to the last resort (see QuadrantRecipe.without_ruin).
const NO_CORNER_FOR_THE_RUIN := "no corner for the ruin"

## The rule that broke on the latest try that failed, for tests and bug reports ("" if no try failed).
var last_broken_rule := ""
## How many tries the last map took (1 when the first held).
var attempts := 0
## The village of the latest try, for tests and bug reports: how many times it was drawn, what it gave up to fit.
var last_village: VillageGenerator.Result


func generate(recipe: QuadrantRecipe, seed_value: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	last_broken_rule = ""
	attempts = 0
	for _attempt in MAX_ATTEMPTS:
		attempts += 1
		var grid := _try(recipe, rng)
		if grid != null:
			return grid.ascii()
		if last_broken_rule == NO_CORNER_FOR_THE_RUIN:
			break
	attempts += 1
	var plain := recipe.without_obstacles()
	if last_broken_rule == NO_CORNER_FOR_THE_RUIN:
		plain = plain.without_ruin()
	var fallback := _try(plain, rng)
	if fallback == null:
		fallback = _try(plain.without_camps(), rng)
	if fallback == null:
		fallback = _try(plain.without_ruin(), rng)
	if fallback == null:
		fallback = _try(plain.without_camps().without_ruin(), rng)
	if fallback == null:
		push_warning("Quadrant '%s' breaks a rule even without obstacles (%s): made by the default recipe instead"
			% [recipe.id, last_broken_rule])
		fallback = _try(QuadrantRecipe.new().without_obstacles(), rng)
	if fallback == null:
		push_error("Quadrant '%s' breaks a rule even without obstacles: %s" % [recipe.id, last_broken_rule])
		return ""
	return fallback.ascii()


## One run of the steps: the grid, or null if a rule broke.
func _try(recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> QuadrantGrid:
	var grid := QuadrantGrid.new(recipe.size())
	QuadrantGround.lay(grid, recipe, rng)
	QuadrantBorder.raise(grid, recipe)
	QuadrantExits.cut(grid, recipe)
	last_village = VillageGenerator.new().generate(recipe.village_size(), recipe.village_prop_share, rng)
	var pieces: Array[SetPiece] = [SetPieces.village(last_village)]
	if recipe.has_ruin:
		pieces.append(SetPieces.ruin(Ruins.draw(recipe, rng)))
	pieces.append_array(recipe.set_pieces())
	var keep_clear := QuadrantExits.cleared_areas(recipe)
	var placements := SetPiecePlacer.reserve(recipe, pieces, keep_clear, rng)
	if placements.size() < pieces.size():
		var unplaced := pieces[placements.size()]
		var ruin_never_fits := unplaced.id == Ruins.ID \
			and not SetPiecePlacer.fits_anywhere(recipe, unplaced, keep_clear, placements)
		last_broken_rule = NO_CORNER_FOR_THE_RUIN if ruin_never_fits else "no spot for a set piece"
		return null
	placements = CampCrews.dress(recipe, placements, rng)
	for placement in placements:
		SetPiecePlacer.stamp(grid, placement)
	QuadrantGround.seal_pockets(grid, grid.find(QuadrantGrid.START))
	if not QuadrantRoads.lay(grid, recipe, placements, rng):
		last_broken_rule = "no road to an exit"
		return null
	var broken := QuadrantRules.broken_rule(grid, recipe, placements)
	if broken != "":
		last_broken_rule = broken
		return null
	return grid
