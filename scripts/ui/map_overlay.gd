class_name MapOverlay
extends Control
## The whole map on screen: the minimap's picture, cropped to what has been explored and enlarged to fill the
## screen over a dimmed backdrop. A tap, a
## click, Esc or M closes it. It only reports that it closed; the composition root decides about pausing.

signal closed

const BACKDROP_COLOR := Color(0.03, 0.02, 0.05, 0.9)
## Empty space kept around the map, in pixels.
const MARGIN := 40
## Cells of empty space kept around the explored part.
const BORDER_CELLS := 2
## However little is explored, a cell is never drawn bigger than this, so a lone room doesn't turn into blocks.
const MAX_CELL_PIXELS := 12
const HINT := "Tap to close"
const HINT_SIZE := 18

var _picture := TextureRect.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)
	var hint := Label.new()
	hint.text = HINT
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.add_theme_font_size_override("font_size", HINT_SIZE)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(hint)
	hide()


## The biggest whole number of pixels per cell (1 to MAX_CELL_PIXELS) that keeps a map of map_size inside
## available. Whole numbers keep every cell the same crisp square.
static func scale_for(map_size: Vector2i, available: Vector2) -> int:
	return clampi(floori(minf(available.x / map_size.x, available.y / map_size.y)), 1, MAX_CELL_PIXELS)


func open(map: DungeonMap, exploration: Exploration, player_cell: Vector2i) -> void:
	var screen := get_viewport_rect().size
	var explored := _explored_part(MinimapPainter.paint(map, exploration, player_cell))
	var cell_pixels := scale_for(explored.get_size(), screen - Vector2.ONE * 2.0 * MARGIN)
	_picture.texture = ImageTexture.create_from_image(explored)
	_picture.size = Vector2(explored.get_size() * cell_pixels)
	_picture.position = ((screen - _picture.size) / 2.0).floor()
	show()


## The picture cut down to what has been painted, with a little room around it.
static func _explored_part(painted: Image) -> Image:
	var area := painted.get_used_rect().grow(BORDER_CELLS).intersection(Rect2i(Vector2i.ZERO, painted.get_size()))
	return painted.get_region(area)


func close() -> void:
	hide()
	closed.emit()


## Esc and M close it before anything else (the pause menu included) can react.
func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"toggle_minimap")):
		close()
		get_viewport().set_input_as_handled()


## Touches reach here as clicks too (Godot copies one into the other).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
		accept_event()
