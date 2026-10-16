class_name DungeonView
extends Node2D
## Draws a DungeonMap and gives its walls and doors collision. Owns no game rules.

const TILE_SIZE := 32
const FLOOR_COLOR := Color(0.23, 0.21, 0.26)
const WALL_COLOR := Color(0.1, 0.09, 0.12)
const WALL_LAYER := 1
const STAIRS_COLOR := Color(0.95, 0.75, 0.3)
const STAIRS_STEPS := 4

var _map: DungeonMap
var _doors := {}  # Vector2i -> Door


static func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


static func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / TILE_SIZE).floor())


func show_map(map: DungeonMap) -> void:
	_map = map
	_build_wall_colliders()
	_build_doors()
	queue_redraw()


func set_room_closed(room: int, closed: bool) -> void:
	for cell in _map.doors_of_room(room):
		_doors[cell].set_closed(closed)


func _draw() -> void:
	if _map == null:
		return
	for cell in _map.walkable_cells():
		draw_rect(_tile_rect(cell), FLOOR_COLOR)
	for cell in _wall_cells_touching_walkable():
		draw_rect(_tile_rect(cell), WALL_COLOR)
	if _map.exit_cell != DungeonMap.NO_CELL:
		_draw_stairs(_tile_rect(_map.exit_cell))


## Steps shrinking toward the bottom, so the exit reads as a way down.
func _draw_stairs(tile: Rect2) -> void:
	var step_height := tile.size.y / STAIRS_STEPS
	for i in STAIRS_STEPS:
		var inset := tile.size.x * 0.1 * i
		var step := Rect2(tile.position.x + inset, tile.position.y + i * step_height,
			tile.size.x - inset * 2.0, step_height - 2.0)
		draw_rect(step, Color(STAIRS_COLOR, 1.0 - i * 0.2))


func _build_wall_colliders() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1 << (WALL_LAYER - 1)
	body.collision_mask = 0
	for cell in _wall_cells_touching_walkable():
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(TILE_SIZE, TILE_SIZE)
		shape.shape = rectangle
		shape.position = cell_center(cell)
		body.add_child(shape)
	add_child(body)


func _build_doors() -> void:
	for cell in _map.door_cells():
		var door := Door.new(TILE_SIZE)
		door.position = cell_center(cell)
		add_child(door)
		_doors[cell] = door


func _wall_cells_touching_walkable() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in _map.size.y:
		for x in _map.size.x:
			var cell := Vector2i(x, y)
			if not _map.is_walkable(cell) and _has_walkable_neighbour(cell):
				cells.append(cell)
	return cells


func _has_walkable_neighbour(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _map.is_walkable(cell + Vector2i(dx, dy)):
				return true
	return false


func _tile_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
