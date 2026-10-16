class_name DungeonLayout
extends RefCounted
## Read-only result of dungeon generation: which grid cells are floor, and where the rooms are.

var size: Vector2i
var rooms: Array[Rect2i]
var _floor_flags: PackedByteArray


func _init(grid_size: Vector2i, floor_flags: PackedByteArray, room_rects: Array[Rect2i]) -> void:
	assert(floor_flags.size() == grid_size.x * grid_size.y, "flags must cover the whole grid")
	size = grid_size
	_floor_flags = floor_flags
	rooms = room_rects


func is_floor(cell: Vector2i) -> bool:
	if not _is_inside(cell):
		return false
	return _floor_flags[cell.y * size.x + cell.x] == 1


func floor_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			if is_floor(Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


func room_center(room_index: int) -> Vector2i:
	return rooms[room_index].get_center()


func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y
