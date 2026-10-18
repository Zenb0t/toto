class_name QuadrantGenerator
extends RefCounted
## Builds a quadrant as an ASCII map (the format DungeonMapParser reads) from a recipe and a seed, in small steps:
##   ground → border → exits → reserve set-piece spots → place set pieces → validate
## A step that breaks a rule (no spot for a piece, a cut-off exit, too little open ground) doesn't fail the map:
## the whole thing is made again with the next random numbers. The same recipe and seed always give the same map.
## If every try fails (a recipe asking for the impossible), the last resort is the same quadrant without groves,
## boulders and ponds, which cannot break the rules.

## How many times the steps run before the last resort.
const MAX_ATTEMPTS := 40

## The rule that broke on the latest try that failed, for tests and bug reports ("" if no try failed).
var last_broken_rule := ""
## How many tries the last map took (1 when the first held).
var attempts := 0


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
	attempts += 1
	var fallback := _try(recipe.without_obstacles(), rng)
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
	var placements := SetPiecePlacer.reserve(recipe, recipe.set_pieces(), QuadrantExits.cleared_areas(recipe), rng)
	if placements.size() < recipe.set_pieces().size():
		last_broken_rule = "no spot for a set piece"
		return null
	for placement in placements:
		SetPiecePlacer.stamp(grid, placement)
	QuadrantGround.seal_pockets(grid, recipe.center())
	var broken := QuadrantRules.broken_rule(grid, recipe, placements)
	if broken != "":
		last_broken_rule = broken
		return null
	return grid
