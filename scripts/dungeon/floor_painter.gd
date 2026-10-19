class_name FloorPainter
extends RefCounted
## How the floor of a map looks, cell by cell: built floors are flagstones that alternate between two shades (the
## branch's, see BranchLook), so distances read at a glance; each stone is tinted a little differently (see
## DungeonDecor) and set in grout. Cave floors are bare earth or rock: blotchy, speckled, no grout. Walls are
## dark; columns and trees stand on the floor with a shadow at their foot; the ground under a wood's trees is grass in
## the canopy's shade; torches warm the floor below them.
##
## paint() draws any set of cells onto a canvas, so the floor can be split into pieces that are each drawn (and
## skipped when off screen) on their own (see FloorChunk). It paints in layers, all of one kind of shape at a
## time (rectangles, then cracks, shadows, light, stairs), because a renderer draws a run of the same kind of
## shape at once. Nothing a cell paints reaches outside it, so the layers look the same as painting each cell in
## turn.

const STONE_TINT := 0.035
const GROUT_WIDTH := 1.5
const EARTH_SPECK_COLOR := Color(0, 0, 0, 0.18)
const PILLAR_SHADOW_COLOR := Color(0, 0, 0, 0.35)
const PILLAR_SHADOW_RADIUS := 13.0
const BEVEL_LIGHT := Color(1, 1, 1, 0.08)
const BEVEL_DARK := Color(0, 0, 0, 0.18)
## The bevels along a stone's edges are this thick, in pixels.
const BEVEL_WIDTH := 1.0
const CRACK_COLOR := Color(0.16, 0.14, 0.18, 0.45)
## The warm pool of light on the floor below each torch (see DungeonDecor.torch_light), at its brightest.
const TORCH_LIGHT_COLOR := Color(1.0, 0.68, 0.32, 0.22)
const WALL_COLOR := Color(0.1, 0.09, 0.12)
## The shade over the ground under a wood's trees.
const WOOD_SHADE_COLOR := Color(0, 0.05, 0, 0.45)
const STAIRS_COLOR := Color(0.95, 0.75, 0.3)
const STAIRS_UP_COLOR := Color(0.8, 0.84, 0.9)
const STAIRS_STEPS := 4
const SPECK_SIZE := Vector2(2, 2)

var _map: DungeonMap
var _look: BranchLook
var _pillars := {}  # Vector2i -> true: columns and trees, which stand on ground (rock pillars are walls)
var _light := {}  # Vector2i -> warmth (0 to 1) of the torch light on it


## wall_cells: the walls drawn (those next to open cells, see DungeonView.wall_cells).
func _init(map: DungeonMap, look: BranchLook, wall_cells: Array[Vector2i]) -> void:
	_map = map
	_look = look
	if look.pillar_style != BranchLook.PillarStyle.ROCK:
		for cell in DungeonDecor.pillar_cells(map, wall_cells):
			_pillars[cell] = true
	if look.torches:
		_light = DungeonDecor.torch_light(map, DungeonDecor.torch_cells(map, wall_cells))


## Draws these cells of the floor (open cells and walls) onto the canvas.
func paint(canvas: CanvasItem, cells: Array[Vector2i]) -> void:
	for cell in cells:
		_paint_base(canvas, cell)
	for cell in cells:
		if _map.blocker_at(cell) == DungeonMap.Blocker.GROVE:
			canvas.draw_rect(_tile_rect(cell), WOOD_SHADE_COLOR)
	for cell in cells:
		if _shows_flagstone(cell):
			_paint_crack(canvas, cell)
	for cell in cells:
		if _pillars.has(cell):
			canvas.draw_circle(DungeonView.cell_center(cell), PILLAR_SHADOW_RADIUS, PILLAR_SHADOW_COLOR)
	for cell in cells:
		if _light.has(cell):
			canvas.draw_rect(_tile_rect(cell), Color(TORCH_LIGHT_COLOR, TORCH_LIGHT_COLOR.a * _light[cell]))
	for cell in cells:
		if cell == _map.exit_cell:
			_paint_stairs(canvas, _tile_rect(cell), STAIRS_COLOR, true)
		elif cell == _map.stairs_up_cell:
			_paint_stairs(canvas, _tile_rect(cell), STAIRS_UP_COLOR, false)


## The ground of an open cell, of a pillar's cell and under a village piece or a tree (its model stands on it); a
## dark block for any other wall.
func _paint_base(canvas: CanvasItem, cell: Vector2i) -> void:
	if not _stands_on_ground(cell):
		canvas.draw_rect(_tile_rect(cell), WALL_COLOR)
	elif _map.terrain_at(cell) == DungeonMap.Terrain.PATH:
		_paint_dirt(canvas, cell, _look.street_color, _look.street_alt_color)
	elif _map.terrain_at(cell) == DungeonMap.Terrain.ROAD:
		_paint_dirt(canvas, cell, _look.road_color, _look.road_alt_color)
	elif _look.flagstones:
		_paint_flagstone(canvas, cell)
	else:
		_paint_earth(canvas, cell)


func _stands_on_ground(cell: Vector2i) -> bool:
	return _map.is_open(cell) or _pillars.has(cell) or _map.blocker_at(cell) in DungeonMap.VILLAGE_BLOCKERS \
		or _map.blocker_at(cell) == DungeonMap.Blocker.GROVE


func _shows_flagstone(cell: Vector2i) -> bool:
	return _look.flagstones and _stands_on_ground(cell) \
		and _map.terrain_at(cell) != DungeonMap.Terrain.PATH and _map.terrain_at(cell) != DungeonMap.Terrain.ROAD


## A stone in grout, lit along its top and left edges and shaded along the others.
func _paint_flagstone(canvas: CanvasItem, cell: Vector2i) -> void:
	var tile := _tile_rect(cell)
	canvas.draw_rect(tile, _look.grout_color)
	var base := _look.floor_color if (cell.x + cell.y) % 2 == 0 else _look.floor_alt_color
	var tint := DungeonDecor.tint(cell) * STONE_TINT
	var stone := _stone_rect(tile)
	canvas.draw_rect(stone, Color(base.r + tint, base.g + tint, base.b + tint))
	var half := BEVEL_WIDTH / 2.0
	canvas.draw_rect(Rect2(stone.position.x, stone.position.y - half, stone.size.x, BEVEL_WIDTH), BEVEL_LIGHT)
	canvas.draw_rect(Rect2(stone.position.x - half, stone.position.y, BEVEL_WIDTH, stone.size.y), BEVEL_LIGHT)
	canvas.draw_rect(Rect2(stone.position.x, stone.end.y - half, stone.size.x, BEVEL_WIDTH), BEVEL_DARK)
	canvas.draw_rect(Rect2(stone.end.x - half, stone.position.y, BEVEL_WIDTH, stone.size.y), BEVEL_DARK)


func _paint_crack(canvas: CanvasItem, cell: Vector2i) -> void:
	var crack := DungeonDecor.crack(cell)
	if crack.is_empty():
		return
	var stone := _stone_rect(_tile_rect(cell))
	var points := PackedVector2Array()
	for point in crack:
		points.append(stone.position + point * stone.size)
	canvas.draw_polyline(points, CRACK_COLOR, 1.0)


## Beaten earth (the village's streets and square) or a dirt road across the plains: two shades in blotches,
## with a pebble.
func _paint_dirt(canvas: CanvasItem, cell: Vector2i, color: Color, alt_color: Color) -> void:
	var tile := _tile_rect(cell)
	canvas.draw_rect(tile, color.lerp(alt_color, DungeonDecor.noise(cell, 12)))
	var speck := Vector2(DungeonDecor.noise(cell, 13), DungeonDecor.noise(cell, 23)) * (DungeonView.TILE_SIZE - 3)
	canvas.draw_rect(Rect2(tile.position + speck, SPECK_SIZE), EARTH_SPECK_COLOR)


## Bare ground: the two colours mixed in soft blotches (each cell blends its neighbours' noise), with a few
## specks of grit.
func _paint_earth(canvas: CanvasItem, cell: Vector2i) -> void:
	var blotch := DungeonDecor.noise(cell, 12)
	for step in DungeonDecor.NEIGHBOURS_4:
		blotch += DungeonDecor.noise(cell + step, 12)
	var tile := _tile_rect(cell)
	canvas.draw_rect(tile, _look.floor_color.lerp(_look.floor_alt_color, blotch / 5.0))
	for i in _look.ground_specks:
		var speck := Vector2(DungeonDecor.noise(cell, 13 + i), DungeonDecor.noise(cell, 23 + i)) * (DungeonView.TILE_SIZE - 3)
		canvas.draw_rect(Rect2(tile.position + speck, SPECK_SIZE), EARTH_SPECK_COLOR)


## Steps shrinking toward the bottom (going down) or toward the top (going up), fading as they go.
static func _paint_stairs(canvas: CanvasItem, tile: Rect2, color: Color, going_down: bool) -> void:
	var step_height := tile.size.y / STAIRS_STEPS
	for i in STAIRS_STEPS:
		var row := i if going_down else STAIRS_STEPS - 1 - i
		var inset := tile.size.x * 0.1 * i
		var step := Rect2(tile.position.x + inset, tile.position.y + row * step_height,
			tile.size.x - inset * 2.0, step_height - 2.0)
		canvas.draw_rect(step, Color(color, 1.0 - i * 0.2))


static func _stone_rect(tile: Rect2) -> Rect2:
	return tile.grow(-GROUT_WIDTH)


static func _tile_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * DungeonView.TILE_SIZE, Vector2(DungeonView.TILE_SIZE, DungeonView.TILE_SIZE))
