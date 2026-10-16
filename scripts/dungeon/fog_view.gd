class_name FogView
extends Node2D
## Draws the fog of war over the dungeon: unexplored cells hidden, explored ones out of view dimmed.

## Matches the background, so unexplored parts of the map simply aren't there yet.
const UNKNOWN_COLOR := Color(0.05, 0.04, 0.07)
const REMEMBERED_COLOR := Color(0.05, 0.04, 0.07, 0.6)

var _cells: Array[Vector2i] = []
var _exploration: Exploration


## cells: every cell that is drawn at all (floors, doors, walls next to them).
func _init(cells: Array[Vector2i]) -> void:
	_cells = cells
	z_index = 10


func show_exploration(exploration: Exploration) -> void:
	_exploration = exploration
	queue_redraw()


func _draw() -> void:
	if _exploration == null:
		return
	for cell in _cells:
		if not _exploration.is_seen(cell):
			draw_rect(_tile_rect(cell), UNKNOWN_COLOR)
		elif not _exploration.is_visible(cell):
			draw_rect(_tile_rect(cell), REMEMBERED_COLOR)


func _tile_rect(cell: Vector2i) -> Rect2:
	var size := Vector2.ONE * DungeonView.TILE_SIZE
	return Rect2(Vector2(cell) * size, size)
