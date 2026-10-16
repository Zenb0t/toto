class_name Door
extends StaticBody2D
## A doorway that becomes a wall while its room is locked.

const OPEN_COLOR := Color(0.3, 0.25, 0.22)
const CLOSED_COLOR := Color(0.8, 0.5, 0.25)

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
	draw_rect(Rect2(-half, -half, _tile_size, _tile_size), CLOSED_COLOR if _closed else OPEN_COLOR)
