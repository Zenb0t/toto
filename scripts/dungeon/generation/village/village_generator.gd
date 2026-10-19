class_name VillageGenerator
extends RefCounted
## Draws the village, in the map format, from a size and a random number generator, in small steps:
##   palisade → streets → lots (the inn first, facing the square; then one or two of the smithy, market and church;
##   then three to five houses) → house colours → props → rules
## A seed whose lots don't fit is tried again 20 times; then the plan gets smaller (fewer houses, down to 3, then no
## market) and, if even that doesn't fit, the village grows. So it never fails. The same size, share and random
## numbers always give the same village.
## The drawing is stamped into the plains' middle by the set-piece placer (see SetPieces.village).

## How many times a plan is tried at one size.
const TRIES := 20
const MIN_HOUSES := 3
const MAX_HOUSES := 5
## A village that couldn't fit its plan grows by this much on each axis, until it does.
const GROWTH := 2
const MAX_GROWTHS := 20


## What was made and what it took.
class Result:
	extends RefCounted
	var rows: PackedStringArray
	var size: Vector2i
	## The lots that fit, with where they stand.
	var lots: Array[VillageLotPacker.Placed] = []
	## How many times the steps ran in all.
	var attempts := 0
	## What was given up to make it fit, in order: "fewer houses", "no market", "bigger village" ("" when nothing was).
	var fallbacks: Array[String] = []
	## The cell the hero starts on, in front of the inn's doorstep.
	var start: Vector2i

	func ascii() -> String:
		return "\n".join(rows)


## The broken rule of the latest try that failed, for tests ("" if none did).
var last_broken_rule := ""
var _lot_gap := VillageLotPacker.DEFAULT_GAP


## lot_gap: the least number of open cells between two buildings (see VillageLotPacker).
func generate(
		size: Vector2i, prop_share: float, rng: RandomNumberGenerator, lot_gap := VillageLotPacker.DEFAULT_GAP
) -> Result:
	_lot_gap = lot_gap
	var result := Result.new()
	var plan := _plan(rng)
	var village_size := size
	# 1. The plan as drawn up, at the size asked for.
	if _try_plan(result, village_size, plan, prop_share, rng):
		return result
	# 2. Fewer houses, down to the least.
	while _count(plan, VillageLots.HOUSES) > MIN_HOUSES:
		_remove_one_of(plan, VillageLots.HOUSES)
		_note(result, "fewer houses")
		if _try_plan(result, village_size, plan, prop_share, rng):
			return result
	# 3. No market.
	if plan.has("market"):
		plan.erase("market")
		_note(result, "no market")
		if _try_plan(result, village_size, plan, prop_share, rng):
			return result
	# 4. A bigger village.
	for _growth in MAX_GROWTHS:
		village_size += Vector2i.ONE * GROWTH
		_note(result, "bigger village")
		if _try_plan(result, village_size, plan, prop_share, rng):
			return result
	push_error("A village of %s fits nothing: made without lots" % village_size)
	return _without_lots(result, village_size)


## The lots to place, in order: the inn, one or two specials, three to five houses.
func _plan(rng: RandomNumberGenerator) -> Array[String]:
	var plan: Array[String] = [VillageLots.INN]
	var specials := VillageLots.SPECIALS.duplicate()
	_shuffle(specials, rng)
	plan.append_array(specials.slice(0, rng.randi_range(1, 2)))
	for _house in rng.randi_range(MIN_HOUSES, MAX_HOUSES):
		plan.append(VillageLots.HOUSES[rng.randi_range(0, VillageLots.HOUSES.size() - 1)])
	return plan


func _try_plan(
		result: Result, size: Vector2i, plan: Array[String], prop_share: float, rng: RandomNumberGenerator
) -> bool:
	for _try in TRIES:
		result.attempts += 1
		var grid := _try_once(result, size, plan, prop_share, rng)
		if grid != null:
			result.size = size
			result.rows = PackedStringArray(grid.ascii().split("\n"))
			return true
	return false


## One run of the steps: the finished grid, or null if a lot fitted nowhere or a rule broke.
func _try_once(
		result: Result, size: Vector2i, plan: Array[String], prop_share: float, rng: RandomNumberGenerator
) -> QuadrantGrid:
	var grid := QuadrantGrid.new(size)
	VillagePalisade.raise(grid)
	var layout := VillageStreets.lay(grid, rng)
	var lots: Array[VillageLotPacker.Placed] = []
	for lot_id in plan:
		var placed := VillageLotPacker.pack(grid, layout, lot_id, lot_id == VillageLots.INN, rng, _lot_gap)
		if placed == null:
			last_broken_rule = "no room for the %s" % lot_id
			return null
		lots.append(placed)
	_colour_houses(grid, lots, rng)
	VillageProps.scatter(grid, layout, prop_share, rng)
	var inn := lots[0]
	grid.put(inn.front, QuadrantGrid.START)
	var broken := VillageRules.broken_rule(grid, layout, lots)
	if broken != "":
		last_broken_rule = broken
		return null
	result.lots = lots
	result.start = inn.front
	return grid


## Every house gets a colour, the four in a random order so a village shows as many as it has houses (up to four).
func _colour_houses(grid: QuadrantGrid, lots: Array[VillageLotPacker.Placed], rng: RandomNumberGenerator) -> void:
	var colours: Array = range(Village.HOUSE_COLORS)
	_shuffle(colours, rng)
	var next := 0
	for lot in lots:
		if lot.kind != Village.Kind.HOUSE:
			continue
		var letter := Village.letter_of(Village.Kind.HOUSE, colours[next % colours.size()])
		next += 1
		for y in range(lot.rect.position.y, lot.rect.end.y):
			for x in range(lot.rect.position.x, lot.rect.end.x):
				if grid.at(Vector2i(x, y)) == VillageLots.HOUSE_WALL:
					grid.put(Vector2i(x, y), letter)


## The last resort, which should never be needed: the palisade, the streets and a start in the square.
func _without_lots(result: Result, size: Vector2i) -> Result:
	var grid := QuadrantGrid.new(size)
	VillagePalisade.raise(grid)
	var layout := VillageStreets.lay(grid, RandomNumberGenerator.new())
	result.size = size
	result.start = layout.square.position
	grid.put(result.start, QuadrantGrid.START)
	result.rows = PackedStringArray(grid.ascii().split("\n"))
	return result


static func _count(plan: Array[String], designs: Array[String]) -> int:
	var count := 0
	for lot_id in plan:
		if lot_id in designs:
			count += 1
	return count


static func _remove_one_of(plan: Array[String], designs: Array[String]) -> void:
	for i in range(plan.size() - 1, -1, -1):
		if plan[i] in designs:
			plan.remove_at(i)
			return


static func _note(result: Result, fallback: String) -> void:
	if result.fallbacks.is_empty() or result.fallbacks[-1] != fallback:
		result.fallbacks.append(fallback)


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept = items[i]
		items[i] = items[j]
		items[j] = kept
