class_name SetPiece
extends RefCounted
## A hand-made piece to stamp into a quadrant (the crypt entrance now; camps, campfires, the ruin and the village
## later), written in the map format. The placer (SetPiecePlacer) finds it a spot by these rules and stamps it.
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


func _init(
		piece_id: String, drawing: PackedStringArray, anchor: String, outward := 0.0, clear_margin := 2,
		in_the_middle := false) -> void:
	id = piece_id
	rows = drawing
	anchor_symbol = anchor
	min_outward = outward
	apron = clear_margin
	at_center = in_the_middle


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
