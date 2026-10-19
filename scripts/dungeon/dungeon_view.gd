class_name DungeonView
extends Node2D
## Draws a DungeonMap and gives its walls, doors and deep water collision. Owns no game rules. The floor and the
## liquids are drawn in square pieces (FloorChunk), so only those near the camera are drawn each frame; how the
## floor looks is FloorPainter's.

const TILE_SIZE := 32
const WALL_LAYER := 1
## Deep water stops bodies (on this layer) but not shots (which only collide with walls and their targets).
const WATER_LAYER := 5
## Liquids move (see LiquidView): deep water slowly, lava more slowly still.
const WATER_COLOR := Color(0.12, 0.26, 0.5)
const WATER_SHINE_COLOR := Color(0.45, 0.7, 0.95)
const WATER_SPEED := 1.0
const LAVA_COLOR := Color(0.7, 0.18, 0.05)
const LAVA_SHINE_COLOR := Color(1.0, 0.75, 0.25)
const LAVA_SPEED := 0.45
## Shallow water lets the floor show through.
const SHALLOW_COLOR := Color(0.2, 0.42, 0.62, 0.55)
const SHALLOW_SHINE_COLOR := Color(0.55, 0.78, 0.95, 0.7)
const SHALLOW_SPEED := 0.8

var _map: DungeonMap
var _look := BranchLook.dungeon()
var _doors := {}  # Vector2i -> Door
var _walls: Array[Vector2i] = []
var _walls_found := false
## Kept here: the floor's pieces only hold a Callable to its paint(), which doesn't keep it alive.
var _floor_painter: FloorPainter


static func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


static func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / TILE_SIZE).floor())


func show_map(map: DungeonMap, look := BranchLook.dungeon()) -> void:
	_map = map
	_look = look
	_walls.clear()
	_walls_found = false
	_build_colliders(wall_cells(), WALL_LAYER)
	_build_colliders(_map.cells_with(DungeonMap.Terrain.WATER), WATER_LAYER)
	_floor_painter = FloorPainter.new(_map, _look, wall_cells())
	var ground: Array[FloorChunk] = []
	for cells: Array[Vector2i] in FloorChunk.split(drawn_cells()):
		ground.append(FloorChunk.new(cells, _floor_painter.paint))
	_add_pieces(ground)
	_add_pieces(LiquidView.pieces(_map.cells_with(DungeonMap.Terrain.WATER), WATER_COLOR, WATER_SHINE_COLOR, WATER_SPEED))
	_add_pieces(LiquidView.pieces(_map.cells_with(DungeonMap.Terrain.LAVA), LAVA_COLOR, LAVA_SHINE_COLOR, LAVA_SPEED))
	_add_pieces(LiquidView.pieces(
		_map.cells_with(DungeonMap.Terrain.SHALLOW), SHALLOW_COLOR, SHALLOW_SHINE_COLOR, SHALLOW_SPEED))
	_build_doors()


## Every cell this view draws: open cells, the walls around them, and the floor of every wood (trees stand on it).
func drawn_cells() -> Array[Vector2i]:
	var cells := _map.open_cells()
	cells.append_array(wall_cells())
	cells.append_array(_deep_wood_cells())
	return cells


## Grove cells too far into a wood to be walls (see wall_cells): their floor is drawn all the same.
func _deep_wood_cells() -> Array[Vector2i]:
	var walls := {}
	for cell in wall_cells():
		walls[cell] = true
	return _map.cells_with_blocker(DungeonMap.Blocker.GROVE).filter(
		func(cell: Vector2i) -> bool: return not walls.has(cell))


func is_door_closed(cell: Vector2i) -> bool:
	return _doors.has(cell) and _doors[cell].is_closed()


func set_room_closed(room: int, closed: bool) -> void:
	for cell in _map.doors_of_room(room):
		_doors[cell].set_closed(closed)


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


## The walls next to open cells: the only ones anyone can see or touch. Worked out once per map.
func wall_cells() -> Array[Vector2i]:
	if not _walls_found:
		for y in _map.size.y:
			for x in _map.size.x:
				var cell := Vector2i(x, y)
				if not _map.is_open(cell) and _has_open_neighbour(cell):
					_walls.append(cell)
		_walls_found = true
	return _walls


func _has_open_neighbour(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _map.is_open(cell + Vector2i(dx, dy)):
				return true
	return false


## The floor's pieces, in the order they are drawn: the ground, then each liquid (water, lava, shallows) over it.
func floor_pieces() -> Array[FloorChunk]:
	var pieces: Array[FloorChunk] = []
	for child in get_children():
		if child is FloorChunk:
			pieces.append(child)
	return pieces


func _add_pieces(pieces: Array[FloorChunk]) -> void:
	for piece: FloorChunk in pieces:
		add_child(piece)
