class_name SetPiece
extends RefCounted
## A hand-made piece to stamp into a quadrant (the village, the crypt entrance, camps and campfires; the ruin later),
## written in the map format. The placer (SetPiecePlacer) finds it a spot by these rules and stamps it.
## Plain data.

var id: String
## The drawing, one string per row, all the same width.
var rows: PackedStringArray
## The symbol of the piece's key cell (the crypt entrance's stairs): where the rules measure from, and what
## must be reachable.
var anchor_symbol: String
## How far out from the quadrant's middle the anchor must lie at least, 0 (the middle) to 1 (the border); see
## QuadrantRecipe.outward.
var min_outward := 0.0
## Cells around the piece cleared to plain ground, so it is never walled in by a grove.
var apron := 2
## The piece goes in the middle of the quadrant instead of a spot found for it (the village).
var at_center := false
## Which spacing group the piece belongs to (its id unless set; see spaced()).
var kind: String
## Least distance in cells between this piece's anchor and the anchor of any piece of a kind (kind -> cells).
## It counts both ways: the larger of the two pieces' rules holds.
var spacing := {}
## The anchor must lie within this many cells of the quadrant's middle (0: no limit).
var max_from_centre := 0.0


func _init(
		piece_id: String, drawing: PackedStringArray, anchor: String, outward := 0.0, clear_margin := 2,
		in_the_middle := false) -> void:
	id = piece_id
	rows = drawing
	anchor_symbol = anchor
	min_outward = outward
	apron = clear_margin
	at_center = in_the_middle
	kind = piece_id


## The same piece in a spacing group, keeping at least these distances (kind -> cells) from the pieces of
## other kinds. Returns itself, to chain on construction.
func spaced(group: String, apart: Dictionary) -> SetPiece:
	kind = group
	spacing = apart
	return self


## The same piece, kept within this many cells of the quadrant's middle. Returns itself.
func near_centre(cells: float) -> SetPiece:
	max_from_centre = cells
	return self


## A copy with another drawing of the same size (a camp with its monsters drawn in).
func with_rows(drawing: PackedStringArray) -> SetPiece:
	var copy := SetPiece.new(id, drawing, anchor_symbol, min_outward, apron, at_center)
	copy.kind = kind
	copy.spacing = spacing
	copy.max_from_centre = max_from_centre
	return copy


## How far from this piece's anchor the anchor of a piece of the other's kind must lie, at least, by either's rule.
func least_distance_to(other: SetPiece) -> float:
	return maxf(spacing.get(other.kind, 0.0), other.spacing.get(kind, 0.0))


func size() -> Vector2i:
	return Vector2i(rows[0].length(), rows.size())


## Where the anchor is inside the drawing.
func anchor_offset() -> Vector2i:
	for y in rows.size():
		var x := rows[y].find(anchor_symbol)
		if x >= 0:
			return Vector2i(x, y)
	push_error("Set piece '%s' has no '%s'" % [id, anchor_symbol])
	return Vector2i.ZERO
