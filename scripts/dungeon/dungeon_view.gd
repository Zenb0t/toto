class_name DungeonView
extends Node2D
## Draws a DungeonMap and gives its walls, doors and deep water collision. Owns no game rules.

const TILE_SIZE := 32
## Floor tiles alternate between two shades, so distances read at a glance.
const FLOOR_COLOR := Color(0.36, 0.33, 0.4)
const FLOOR_ALT_COLOR := Color(0.32, 0.29, 0.36)
const WALL_COLOR := Color(0.1, 0.09, 0.12)
const WALL_LAYER := 1
## Deep water stops bodies (on this layer) but not shots (which only collide with walls and their targets).
const WATER_LAYER := 5
const WATER_COLOR := Color(0.16, 0.3, 0.55)
const WATER_RIPPLE_COLOR := Color(0.35, 0.55, 0.85, 0.5)
const LAVA_COLOR := Color(0.75, 0.25, 0.08)
const LAVA_GLOW_COLOR := Color(1.0, 0.6, 0.15, 0.6)
const LOOT_MARK_COLOR := Color(1, 1, 1, 0.08)
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
	_build_colliders(wall_cells(), WALL_LAYER)
	_build_colliders(_map.cells_with(DungeonMap.Terrain.WATER), WATER_LAYER)
	_build_doors()
	queue_redraw()


## Every cell this view draws: open cells and the walls around them.
func drawn_cells() -> Array[Vector2i]:
	var cells := _map.open_cells()
	cells.append_array(wall_cells())
	return cells


func is_door_closed(cell: Vector2i) -> bool:
	return _doors.has(cell) and _doors[cell].is_closed()


func set_room_closed(room: int, closed: bool) -> void:
	for cell in _map.doors_of_room(room):
		_doors[cell].set_closed(closed)


func _draw() -> void:
	if _map == null:
		return
	for cell in _map.open_cells():
		draw_rect(_tile_rect(cell), FLOOR_COLOR if (cell.x + cell.y) % 2 == 0 else FLOOR_ALT_COLOR)
	for cell in _map.cells_with(DungeonMap.Terrain.WATER):
		_draw_liquid(_tile_rect(cell), WATER_COLOR, WATER_RIPPLE_COLOR)
	for cell in _map.cells_with(DungeonMap.Terrain.LAVA):
		_draw_liquid(_tile_rect(cell), LAVA_COLOR, LAVA_GLOW_COLOR)
	for cell in wall_cells():
		draw_rect(_tile_rect(cell), WALL_COLOR)
	if _map.exit_cell != DungeonMap.NO_CELL:
		_draw_stairs(_tile_rect(_map.exit_cell))


## A flat colour with a short highlight, so liquid reads differently from floor even without art.
func _draw_liquid(tile: Rect2, base: Color, highlight: Color) -> void:
	draw_rect(tile, base)
	var y := tile.position.y + tile.size.y * 0.4
	draw_line(Vector2(tile.position.x + 6.0, y), Vector2(tile.end.x - 10.0, y), highlight, 2.0)


## Steps shrinking toward the bottom, so the exit reads as a way down.
func _draw_stairs(tile: Rect2) -> void:
	var step_height := tile.size.y / STAIRS_STEPS
	for i in STAIRS_STEPS:
		var inset := tile.size.x * 0.1 * i
		var step := Rect2(tile.position.x + inset, tile.position.y + i * step_height,
			tile.size.x - inset * 2.0, step_height - 2.0)
		draw_rect(step, Color(STAIRS_COLOR, 1.0 - i * 0.2))


func _build_colliders(cells: Array[Vector2i], layer: int) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1 << (layer - 1)
	body.collision_mask = 0
	for cell in cells:
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


## The walls next to open cells: the only ones anyone can see or touch.
func wall_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in _map.size.y:
		for x in _map.size.x:
			var cell := Vector2i(x, y)
			if not _map.is_open(cell) and _has_open_neighbour(cell):
				cells.append(cell)
	return cells


func _has_open_neighbour(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _map.is_open(cell + Vector2i(dx, dy)):
				return true
	return false


func _tile_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
