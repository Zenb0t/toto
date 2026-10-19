class_name FogView
extends Node2D
## Draws the fog of war over the dungeon: unexplored cells hidden, explored ones out of view dimmed.
## The fog is a tiny picture with one pixel per cell, stretched over the map with smooth filtering, so its
## edges fade across a cell instead of stepping from tile to tile.

## Matches the background, so unexplored parts of the map simply aren't there yet.
const UNKNOWN_COLOR := Color(0.05, 0.04, 0.07)
const REMEMBERED_ALPHA := 0.6

var _cells: Array[Vector2i] = []
var _is_drawn := {}  # Vector2i -> true, for the cells in _cells
var _image: Image
var _texture: ImageTexture


## map_size: the map's size in cells. cells: every cell that is drawn at all (floors, doors, walls next
## to them); everything else stays hidden.
func _init(map_size: Vector2i, cells: Array[Vector2i]) -> void:
	_cells = cells
	for cell in cells:
		_is_drawn[cell] = true
	z_index = 10
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_image = Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	_image.fill(UNKNOWN_COLOR)
	_texture = ImageTexture.create_from_image(_image)


## Covers every drawn cell as the exploration says (after entering a map, or restoring what was seen).
func show_exploration(exploration: Exploration) -> void:
	_show_cells(exploration, _cells)


## Covers again only the cells the exploration's last look changed (see Exploration.changed_cells).
func show_changes(exploration: Exploration) -> void:
	var cells: Array[Vector2i] = []
	for cell in exploration.changed_cells():
		if _is_drawn.has(cell):
			cells.append(cell)
	_show_cells(exploration, cells)


func _show_cells(exploration: Exploration, cells: Array[Vector2i]) -> void:
	for cell in cells:
		_image.set_pixelv(cell, Color(UNKNOWN_COLOR, _alpha(exploration, cell)))
	_texture.update(_image)
	queue_redraw()


## How much fog covers a cell: all of it unexplored, some of it out of sight, none in view.
func fog_at(cell: Vector2i) -> float:
	return _image.get_pixelv(cell).a


func _alpha(exploration: Exploration, cell: Vector2i) -> float:
	if not exploration.is_seen(cell):
		return 1.0
	return 0.0 if exploration.is_visible(cell) else REMEMBERED_ALPHA


func _draw() -> void:
	draw_texture_rect(_texture, Rect2(Vector2.ZERO, Vector2(_image.get_size()) * DungeonView.TILE_SIZE), false)
