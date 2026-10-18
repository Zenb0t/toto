class_name VillageLayout
extends RefCounted
## Where the village's ground is while it is being made: the streets, the square and which cells the lots have
## taken. The lot packer reads and fills it; the grid holds the symbols. Plain data.

var size: Vector2i
## The 9x9 open space the streets lead to.
var square: Rect2i
## The three-wide streets from the gates to the square.
var streets: Array[Rect2i] = []
## Cells a lot has taken (its building, its doorstep row and what stands by it).
var taken := {}  # Vector2i -> true

var _square_cells: Array[Vector2i] = []
var _street_cells: Array[Vector2i] = []


func _init(village_size: Vector2i) -> void:
	size = village_size


func is_square(cell: Vector2i) -> bool:
	return square.has_point(cell)


func is_street(cell: Vector2i) -> bool:
	if is_square(cell):
		return true
	for street in streets:
		if street.has_point(cell):
			return true
	return false


## Where lots may stand: inside the palisade, with a cell of room along it.
func lot_area() -> Rect2i:
	return Rect2i(Vector2i(2, 2), size - Vector2i(4, 4))


## The cells of the square.
func square_cells() -> Array[Vector2i]:
	if _square_cells.is_empty():
		_square_cells = _cells_of([square])
	return _square_cells


## The cells of the streets and the square: where a doorstep may open.
func street_cells() -> Array[Vector2i]:
	if _street_cells.is_empty():
		var areas: Array[Rect2i] = [square]
		areas.append_array(streets)
		_street_cells = _cells_of(areas)
	return _street_cells


func _cells_of(areas: Array[Rect2i]) -> Array[Vector2i]:
	var cells := {}
	for area in areas:
		for y in range(area.position.y, area.end.y):
			for x in range(area.position.x, area.end.x):
				cells[Vector2i(x, y)] = true
	var result: Array[Vector2i] = []
	result.assign(cells.keys())
	return result
