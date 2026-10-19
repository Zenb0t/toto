class_name MinimapView
extends Control
## The minimap on screen: the painter's picture, enlarged without smoothing so each cell stays a crisp square,
## over a dark backing. Draws no rules of its own; the composition root says when to refresh. Tapping it
## asks to see the whole map.

signal pressed

const PIXELS_PER_CELL := 2
const BACKING_COLOR := Color(0, 0, 0, 0.45)
## Top left, under the help line and the button that shows or hides it.
const MARGIN := Vector2(16, 122)

var _picture := TextureRect.new()
## The picture shown, kept so a step only repaints the cells that changed.
var _image: Image
var _texture: ImageTexture
var _player_cell := DungeonMap.NO_CELL


func _init() -> void:
	position = MARGIN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backing := ColorRect.new()
	backing.color = BACKING_COLOR
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backing)
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_picture)


## Paints the whole map (on entering it, or after restoring what was seen).
func show_map(map: DungeonMap, exploration: Exploration, player_cell: Vector2i) -> void:
	_image = MinimapPainter.paint(map, exploration, player_cell)
	_texture = ImageTexture.create_from_image(_image)
	_picture.texture = _texture
	_player_cell = player_cell
	size = Vector2(map.size * PIXELS_PER_CELL)


## Repaints only what the exploration's last look changed (see Exploration.changed_cells), and the player's
## old and new cells. The map must be the one show_map last painted.
func show_changes(map: DungeonMap, exploration: Exploration, player_cell: Vector2i) -> void:
	var cells := exploration.changed_cells()
	cells.append_array([_player_cell, player_cell])
	_player_cell = player_cell
	var area := Rect2i(Vector2i.ZERO, map.size)
	for cell in cells:
		if area.has_point(cell):
			_image.set_pixelv(cell, MinimapPainter.color_at(map, exploration, cell, player_cell))
	_texture.update(_image)


## The picture shown now (for tests).
func picture() -> Image:
	return _image


## Touches reach here as clicks too (Godot copies one into the other).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
