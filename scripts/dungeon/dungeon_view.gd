class_name DungeonView
extends Node2D
## Draws a DungeonLayout and gives its walls collision. Pure presentation: owns no game rules.

const TILE_SIZE := 32
const FLOOR_COLOR := Color(0.23, 0.21, 0.26)
const WALL_COLOR := Color(0.1, 0.09, 0.12)
const WALL_LAYER := 1

var _layout: DungeonLayout


static func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


func show_layout(layout: DungeonLayout) -> void:
	_layout = layout
	_build_wall_colliders()
	queue_redraw()


func _draw() -> void:
	if _layout == null:
		return
	for cell in _layout.floor_cells():
		draw_rect(_tile_rect(cell), FLOOR_COLOR)
	for cell in _wall_cells_touching_floor():
		draw_rect(_tile_rect(cell), WALL_COLOR)


func _build_wall_colliders() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1 << (WALL_LAYER - 1)
	body.collision_mask = 0
	for cell in _wall_cells_touching_floor():
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(TILE_SIZE, TILE_SIZE)
		shape.shape = rectangle
		shape.position = cell_center(cell)
		body.add_child(shape)
	add_child(body)


func _wall_cells_touching_floor() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in _layout.size.y:
		for x in _layout.size.x:
			var cell := Vector2i(x, y)
			if not _layout.is_floor(cell) and _has_floor_neighbour(cell):
				cells.append(cell)
	return cells


func _has_floor_neighbour(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _layout.is_floor(cell + Vector2i(dx, dy)):
				return true
	return false


func _tile_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
