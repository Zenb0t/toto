class_name Door
extends StaticBody2D
## A doorway that becomes a wall while its room is locked.

## An open doorway shows a wooden threshold on the floor; a closed door stands in the 3D view.
const THRESHOLD_COLOR := Color(0.42, 0.3, 0.2)
const PLANK_COLOR := Color(0.3, 0.2, 0.13)
const CLOSED_COLOR := Color(0.8, 0.5, 0.25)
const PLANKS := 4

var _tile_size: float
var _shape := CollisionShape2D.new()
var _closed := false


func _init(tile_size: float) -> void:
	_tile_size = tile_size
	collision_layer = 1
	collision_mask = 0
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(tile_size, tile_size)
	_shape.shape = rectangle
	_shape.disabled = true
	add_child(_shape)


func is_closed() -> bool:
	return _closed


func set_closed(closed: bool) -> void:
	_closed = closed
	# Physics state cannot change mid-callback, so defer it.
	_shape.set_deferred("disabled", not closed)
	queue_redraw()


func _draw() -> void:
	var half := _tile_size / 2.0
	var tile := Rect2(-half, -half, _tile_size, _tile_size)
	if _closed:
		draw_rect(tile, CLOSED_COLOR)
		return
	draw_rect(tile, THRESHOLD_COLOR)
	for i in range(1, PLANKS):
		var x := -half + _tile_size * i / PLANKS
		draw_line(Vector2(x, -half), Vector2(x, half), PLANK_COLOR, 1.5)
