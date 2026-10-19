class_name FloorChunk
extends Node2D
## One square piece of something drawn on the floor (the ground, a liquid). Each piece is its own canvas item, so
## the renderer skips the pieces outside the part of the plane on screen instead of drawing the whole map every
## frame (see GroundView). What it draws is up to paint.

## How wide a piece is, in cells: small enough that most of a big map is skipped, big enough to keep the pieces
## few.
const CELLS := 16

var _cells: Array[Vector2i] = []
var _paint: Callable


## paint: Callable(canvas: CanvasItem, cells: Array[Vector2i]), called to draw the piece's cells onto it.
func _init(cells: Array[Vector2i], paint: Callable) -> void:
	_cells = cells
	_paint = paint


func cells() -> Array[Vector2i]:
	return _cells.duplicate()


func _draw() -> void:
	_paint.call(self, _cells)


## The cells grouped into square pieces size cells wide, in the order the pieces first come up.
static func split(cells: Array[Vector2i], size := CELLS) -> Array[Array]:
	var pieces := {}  # Vector2i (which piece) -> Array[Vector2i]
	for cell in cells:
		var key := Vector2i(floori(float(cell.x) / size), floori(float(cell.y) / size))
		if not pieces.has(key):
			var piece: Array[Vector2i] = []
			pieces[key] = piece
		pieces[key].append(cell)
	var result: Array[Array] = []
	result.assign(pieces.values())
	return result
