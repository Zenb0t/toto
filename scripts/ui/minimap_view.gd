class_name MinimapView
extends Control
## The minimap on screen: the painter's picture, enlarged without smoothing so each cell stays a crisp square,
## over a dark backing. Draws no rules of its own; the composition root says when to refresh.

const PIXELS_PER_CELL := 2
const BACKING_COLOR := Color(0, 0, 0, 0.45)
## Top left, under the help line.
const MARGIN := Vector2(16, 72)

var _picture := TextureRect.new()


func _init() -> void:
	position = MARGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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


func show_map(map: DungeonMap, exploration: Exploration, player_cell: Vector2i) -> void:
	_picture.texture = ImageTexture.create_from_image(MinimapPainter.paint(map, exploration, player_cell))
	size = Vector2(map.size * PIXELS_PER_CELL)
