class_name QuadrantGrid
extends RefCounted
## The cells of a quadrant while it is being made: one symbol of the map format (see DungeonMapParser) per cell.
## The generation steps (ground, border, exits, set pieces...) read and write it; it knows no rules of its own,
## only where cells are and what can be walked. Pure.

const GRASS := "."
const GROVE := "T"
const BOULDER := "B"
const BARRICADE := "="
const WALL := "#"
const DEEP_WATER := "~"
const SHALLOW_WATER := ","
const START := "P"
const CRYPT_ENTRANCE := ">"
const NEIGHBOURS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## Symbols nobody can walk on.
const SOLID := [GROVE, BOULDER, BARRICADE, WALL, DEEP_WATER]

var size: Vector2i
var _symbols: PackedStringArray


func _init(grid_size: Vector2i, fill := GRASS) -> void:
	size = grid_size
	_symbols = PackedStringArray()
	_symbols.resize(size.x * size.y)
	_symbols.fill(fill)


func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func at(cell: Vector2i) -> String:
	return _symbols[cell.y * size.x + cell.x]


func put(cell: Vector2i, symbol: String) -> void:
	_symbols[cell.y * size.x + cell.x] = symbol


## Writes a symbol on every cell of a rectangle (the part inside the grid).
func fill_rect(area: Rect2i, symbol: String) -> void:
	for y in range(maxi(area.position.y, 0), mini(area.end.y, size.y)):
		for x in range(maxi(area.position.x, 0), mini(area.end.x, size.x)):
			put(Vector2i(x, y), symbol)


func is_walkable(cell: Vector2i) -> bool:
	return contains(cell) and at(cell) not in SOLID


## The middle cell, where the hero starts.
func center() -> Vector2i:
	return size / 2


## Every cell that can be walked on and reached from `from` without leaving walkable cells (side by side).
func reachable_from(from: Vector2i) -> Dictionary:
	var reached := {}
	if not is_walkable(from):
		return reached
	reached[from] = true
	var frontier: Array[Vector2i] = [from]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in NEIGHBOURS:
			var next := cell + step
			if is_walkable(next) and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	return reached


## How many cells inside `area` can be walked on.
func walkable_in(area: Rect2i) -> int:
	var count := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if is_walkable(Vector2i(x, y)):
				count += 1
	return count


## The grid as the ASCII map the parser reads.
func ascii() -> String:
	var rows := PackedStringArray()
	for y in size.y:
		rows.append("".join(_symbols.slice(y * size.x, (y + 1) * size.x)))
	return "\n".join(rows)
