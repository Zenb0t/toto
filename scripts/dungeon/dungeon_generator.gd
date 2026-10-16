class_name DungeonGenerator
extends RefCounted
## Builds a connected room-and-corridor dungeon. Same seed always yields the same layout.

const MIN_ROOM_SIDE := 5
const MAX_ROOM_SIDE := 9

var _grid_size: Vector2i
var _room_attempts: int


func _init(grid_size := Vector2i(48, 32), room_attempts := 14) -> void:
	_grid_size = grid_size
	_room_attempts = room_attempts


func generate(seed_value: int) -> DungeonLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var flags := PackedByteArray()
	flags.resize(_grid_size.x * _grid_size.y)
	var rooms: Array[Rect2i] = []

	for _attempt in _room_attempts:
		var candidate := _random_room(rng)
		if _overlaps_any(candidate, rooms):
			continue
		if not rooms.is_empty():
			var previous_room: Rect2i = rooms.back()
			var previous_center := previous_room.get_center()
			for cell in _corridor_cells(previous_center, candidate.get_center()):
				flags[_index_of(cell)] = 1
		for cell in _room_cells(candidate):
			flags[_index_of(cell)] = 1
		rooms.append(candidate)

	return DungeonLayout.new(_grid_size, flags, rooms)


func _random_room(rng: RandomNumberGenerator) -> Rect2i:
	var width := rng.randi_range(MIN_ROOM_SIDE, MAX_ROOM_SIDE)
	var height := rng.randi_range(MIN_ROOM_SIDE, MAX_ROOM_SIDE)
	# Keep a one-cell wall border around the whole map.
	var x := rng.randi_range(1, _grid_size.x - width - 1)
	var y := rng.randi_range(1, _grid_size.y - height - 1)
	return Rect2i(x, y, width, height)


func _overlaps_any(candidate: Rect2i, rooms: Array[Rect2i]) -> bool:
	var padded := candidate.grow(1)
	return rooms.any(func(existing: Rect2i) -> bool: return padded.intersects(existing))


func _room_cells(room: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			cells.append(Vector2i(x, y))
	return cells


## L-shaped path: horizontal first, then vertical.
func _corridor_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var step_x := signi(to.x - from.x)
	var x := from.x
	while x != to.x:
		cells.append(Vector2i(x, from.y))
		x += step_x
	var step_y := signi(to.y - from.y)
	var y := from.y
	while y != to.y:
		cells.append(Vector2i(to.x, y))
		y += step_y
	cells.append(to)
	return cells


func _index_of(cell: Vector2i) -> int:
	return cell.y * _grid_size.x + cell.x
