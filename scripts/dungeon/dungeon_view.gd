class_name DungeonView
extends Node2D
## Draws a DungeonMap and gives its walls, doors and deep water collision. Owns no game rules.

const TILE_SIZE := 32
## Built floors are flagstones that alternate between two shades (the branch's, see BranchLook), so
## distances read at a glance; each stone is tinted a little differently (see DungeonDecor) and set in
## grout. Cave floors are bare earth or rock: blotchy, speckled, no grout.
const STONE_TINT := 0.035
const GROUT_WIDTH := 1.5
const EARTH_SPECK_COLOR := Color(0, 0, 0, 0.18)
const EARTH_SPECKS := 3
## Columns and trees stand on the floor, with a shadow at their foot (rock fills its whole cell instead).
const PILLAR_SHADOW_COLOR := Color(0, 0, 0, 0.35)
const PILLAR_SHADOW_RADIUS := 13.0
const BEVEL_LIGHT := Color(1, 1, 1, 0.08)
const BEVEL_DARK := Color(0, 0, 0, 0.18)
const CRACK_COLOR := Color(0.16, 0.14, 0.18, 0.45)
## The warm pool of light on the floor below each torch (see DungeonDecor.torch_light), at its brightest.
const TORCH_LIGHT_COLOR := Color(1.0, 0.68, 0.32, 0.22)
const WALL_COLOR := Color(0.1, 0.09, 0.12)
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
const STAIRS_COLOR := Color(0.95, 0.75, 0.3)
const STAIRS_STEPS := 4

var _map: DungeonMap
var _look := BranchLook.dungeon()
var _doors := {}  # Vector2i -> Door


static func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


static func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / TILE_SIZE).floor())


func show_map(map: DungeonMap, look := BranchLook.dungeon()) -> void:
	_map = map
	_look = look
	_build_colliders(wall_cells(), WALL_LAYER)
	_build_colliders(_map.cells_with(DungeonMap.Terrain.WATER), WATER_LAYER)
	_build_doors()
	add_child(LiquidView.new(_map.cells_with(DungeonMap.Terrain.WATER), WATER_COLOR, WATER_SHINE_COLOR, WATER_SPEED))
	add_child(LiquidView.new(_map.cells_with(DungeonMap.Terrain.LAVA), LAVA_COLOR, LAVA_SHINE_COLOR, LAVA_SPEED))
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
		_draw_ground(cell)
	for cell in wall_cells():
		draw_rect(_tile_rect(cell), WALL_COLOR)
	if _look.pillar_style != BranchLook.PillarStyle.ROCK:
		for cell in DungeonDecor.pillar_cells(_map, wall_cells()):
			_draw_ground(cell)
			draw_circle(cell_center(cell), PILLAR_SHADOW_RADIUS, PILLAR_SHADOW_COLOR)
	var torches: Array[Vector2i] = []
	if _look.torches:
		torches = DungeonDecor.torch_cells(_map, wall_cells())
	var light := DungeonDecor.torch_light(_map, torches)
	for cell: Vector2i in light:
		draw_rect(_tile_rect(cell), Color(TORCH_LIGHT_COLOR, TORCH_LIGHT_COLOR.a * light[cell]))
	if _map.exit_cell != DungeonMap.NO_CELL:
		_draw_stairs(_tile_rect(_map.exit_cell))


func _draw_ground(cell: Vector2i) -> void:
	if _look.flagstones:
		_draw_flagstone(cell)
	else:
		_draw_earth(cell)


func _draw_flagstone(cell: Vector2i) -> void:
	var tile := _tile_rect(cell)
	draw_rect(tile, _look.grout_color)
	var base := _look.floor_color if (cell.x + cell.y) % 2 == 0 else _look.floor_alt_color
	var tint := DungeonDecor.tint(cell) * STONE_TINT
	var stone := tile.grow(-GROUT_WIDTH)
	draw_rect(stone, Color(base.r + tint, base.g + tint, base.b + tint))
	draw_line(stone.position, Vector2(stone.end.x, stone.position.y), BEVEL_LIGHT, 1.0)
	draw_line(stone.position, Vector2(stone.position.x, stone.end.y), BEVEL_LIGHT, 1.0)
	draw_line(Vector2(stone.position.x, stone.end.y), stone.end, BEVEL_DARK, 1.0)
	draw_line(Vector2(stone.end.x, stone.position.y), stone.end, BEVEL_DARK, 1.0)
	var crack := DungeonDecor.crack(cell)
	if not crack.is_empty():
		var points := PackedVector2Array()
		for point in crack:
			points.append(stone.position + point * stone.size)
		draw_polyline(points, CRACK_COLOR, 1.0)


## Bare ground: the two colours mixed in soft blotches (each cell blends its neighbours' noise), with a few
## specks of grit.
func _draw_earth(cell: Vector2i) -> void:
	var blotch := DungeonDecor.noise(cell, 12)
	for step in DungeonDecor.NEIGHBOURS_4:
		blotch += DungeonDecor.noise(cell + step, 12)
	var tile := _tile_rect(cell)
	draw_rect(tile, _look.floor_color.lerp(_look.floor_alt_color, blotch / 5.0))
	for i in EARTH_SPECKS:
		var speck := Vector2(DungeonDecor.noise(cell, 13 + i), DungeonDecor.noise(cell, 23 + i)) * (TILE_SIZE - 3)
		draw_rect(Rect2(tile.position + speck, Vector2(2, 2)), EARTH_SPECK_COLOR)


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
