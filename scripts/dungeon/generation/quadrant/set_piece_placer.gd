class_name SetPiecePlacer
extends RefCounted
## The one place that puts hand-made set pieces into a quadrant (see SetPiece): first it reserves a spot for each
## piece by its rules (inside the border, out of the way of the exits, as far out as the piece wants, no farther from
## the middle than it allows, clear of the pieces before it and as far from them as their spacing rules say; the
## village goes in the middle, and comes first, so every other piece keeps off it and its margin), then it stamps each
## piece on its spot and clears the ground around it. The ruin uses the same two calls. Pure.


## A piece and the spot reserved for it.
class Placement:
	extends RefCounted
	var piece: SetPiece
	## The cell of the quadrant where the piece's top left corner goes.
	var origin: Vector2i

	func _init(placed: SetPiece, at: Vector2i) -> void:
		piece = placed
		origin = at

	func rect() -> Rect2i:
		return Rect2i(origin, piece.size())

	## The cell of the quadrant the piece's anchor lands on.
	func anchor_cell() -> Vector2i:
		return origin + piece.anchor_offset()


const TRIES := 200


## A spot for each piece, in order, or fewer placements than pieces if one finds no spot (the caller then
## generates again with the next random numbers). keep_clear: areas no piece may touch (the exits').
static func reserve(
		recipe: QuadrantRecipe, pieces: Array[SetPiece], keep_clear: Array[Rect2i], rng: RandomNumberGenerator
) -> Array[Placement]:
	var placements: Array[Placement] = []
	for piece in pieces:
		var placement := _find_spot(recipe, piece, keep_clear, placements, rng)
		if placement == null:
			return placements
		placements.append(placement)
	return placements


## Draws the piece on its spot, over whatever is there, after clearing its apron to open ground.
static func stamp(grid: QuadrantGrid, placement: Placement) -> void:
	grid.fill_rect(placement.rect().grow(placement.piece.apron), QuadrantGrid.GRASS)
	for y in placement.piece.rows.size():
		for x in placement.piece.rows[y].length():
			grid.put(placement.origin + Vector2i(x, y), placement.piece.rows[y][x])


## Whether the piece has any spot at all beside the pieces already placed, trying every spot rather than a random few:
## when it has none, no number of tries will find one (the caller can give the piece up at once).
static func fits_anywhere(
		recipe: QuadrantRecipe, piece: SetPiece, keep_clear: Array[Rect2i], placed: Array[Placement]
) -> bool:
	var inside := recipe.interior().grow(-1)
	var most := inside.end - piece.size() - Vector2i.ONE * piece.apron
	var least := inside.position + Vector2i.ONE * piece.apron
	for y in range(least.y, most.y + 1):
		for x in range(least.x, most.x + 1):
			if _is_allowed(recipe, Placement.new(piece, Vector2i(x, y)), keep_clear, placed):
				return true
	return false


static func _find_spot(
		recipe: QuadrantRecipe, piece: SetPiece, keep_clear: Array[Rect2i], placed: Array[Placement],
		rng: RandomNumberGenerator
) -> Placement:
	var piece_size := piece.size()
	var inside := recipe.interior().grow(-1)
	if piece.at_center:
		var middle := Placement.new(piece, recipe.center() - piece_size / 2)
		var fits := inside.encloses(middle.rect().grow(piece.apron))
		return middle if fits and _is_allowed(recipe, middle, keep_clear, placed) else null
	var most := inside.end - piece_size - Vector2i.ONE * piece.apron
	var least := inside.position + Vector2i.ONE * piece.apron
	if most.x < least.x or most.y < least.y:
		return null
	for _try in TRIES:
		var origin := Vector2i(rng.randi_range(least.x, most.x), rng.randi_range(least.y, most.y))
		var candidate := Placement.new(piece, origin)
		if _is_allowed(recipe, candidate, keep_clear, placed):
			return candidate
	return null


static func _is_allowed(
		recipe: QuadrantRecipe, candidate: Placement, keep_clear: Array[Rect2i], placed: Array[Placement]
) -> bool:
	if not candidate.piece.at_center and recipe.outward(candidate.anchor_cell()) < candidate.piece.min_outward:
		return false
	var centre := Vector2(recipe.center())
	var limit := candidate.piece.max_from_centre
	if limit > 0.0 and centre.distance_to(Vector2(candidate.anchor_cell())) > limit:
		return false
	if candidate.piece.corner_share > 0.0:
		var out := recipe.outward_by_axis(candidate.anchor_cell())
		if minf(out.x, out.y) < candidate.piece.corner_share:
			return false
	var footprint := candidate.rect().grow(candidate.piece.apron)
	for area in keep_clear:
		if area.intersects(footprint):
			return false
	for other in placed:
		if other.rect().grow(other.piece.apron).intersects(footprint):
			return false
		if candidate.piece.must_differ_in_corner_from(other.piece) \
				and recipe.corner_of(candidate.anchor_cell()) == recipe.corner_of(other.anchor_cell()):
			return false
		var apart := candidate.piece.least_distance_to(other.piece)
		if Vector2(candidate.anchor_cell()).distance_to(Vector2(other.anchor_cell())) < apart:
			return false
	return true

