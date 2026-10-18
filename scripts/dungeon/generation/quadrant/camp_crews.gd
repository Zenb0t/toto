class_name CampCrews
extends RefCounted
## A generation step: who lives in each camp. The farther out a camp lies, the bigger and tougher its band: more
## monsters, goblins instead of kobolds, and goblin archers toward the edge. Camps are first reserved as open
## ground round a campfire (see SetPieces.camp); once their spots are known, dress() draws a band into each.
## Pure; the same spots and random numbers always give the same bands.

## Where the plains' toughness starts: a camp this far out (see QuadrantRecipe.outward) holds the easiest band.
const NEAR_OUTWARD := 0.3
## At the very edge, this share of a band (rounded down) shoots, always leaving at least one to fight close.
const ARCHER_SHARE_AT_EDGE := 0.5
## What each monster is worth when comparing bands.
const THREATS := {"k": 1, "g": 2, "a": 3}


## How tough a camp this far out is, 0 (nearest) to 1 (the edge).
static func toughness(outward: float) -> float:
	return clampf(inverse_lerp(NEAR_OUTWARD, 1.0, outward), 0.0, 1.0)


## How many monsters live in a camp this far out, between the recipe's least and most.
static func band_size(recipe: QuadrantRecipe, outward: float) -> int:
	var most := maxi(recipe.camp_size_min, recipe.camp_size_max)
	return clampi(roundi(lerpf(recipe.camp_size_min, most, toughness(outward))), recipe.camp_size_min, most)


## The map letters of a camp's monsters (see Bestiary), by how far out it lies.
static func band_letters(recipe: QuadrantRecipe, outward: float, rng: RandomNumberGenerator) -> Array[String]:
	var tough := toughness(outward)
	var size := mini(band_size(recipe, outward), SetPieces.CAMP_SLOTS.size())
	var archers := clampi(floori(tough * size * ARCHER_SHARE_AT_EDGE), 0, size - 1)
	var letters: Array[String] = []
	for _i in size - archers:
		letters.append("g" if rng.randf() < tough else "k")
	for _i in archers:
		letters.append("a")
	return letters


## How dangerous a band is: the sum of what its monsters are worth.
static func threat(letters: Array[String]) -> int:
	var total := 0
	for letter in letters:
		total += THREATS.get(letter, 1)
	return total


## The placements with every camp's ground replaced by the same ground with its band standing round the fire.
static func dress(
		recipe: QuadrantRecipe, placements: Array[SetPiecePlacer.Placement], rng: RandomNumberGenerator
) -> Array[SetPiecePlacer.Placement]:
	var dressed: Array[SetPiecePlacer.Placement] = []
	for placement in placements:
		if placement.piece.id != SetPieces.CAMP_ID:
			dressed.append(placement)
			continue
		var letters := band_letters(recipe, recipe.outward(placement.anchor_cell()), rng)
		dressed.append(SetPiecePlacer.Placement.new(_with_band(placement.piece, letters), placement.origin))
	return dressed


static func _with_band(camp: SetPiece, letters: Array[String]) -> SetPiece:
	var rows := Array(camp.rows)
	var fire := camp.anchor_offset()
	for i in letters.size():
		var cell: Vector2i = fire + SetPieces.CAMP_SLOTS[i]
		rows[cell.y] = rows[cell.y].substr(0, cell.x) + letters[i] + rows[cell.y].substr(cell.x + 1)
	return camp.with_rows(PackedStringArray(rows))
