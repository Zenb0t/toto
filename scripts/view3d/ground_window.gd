class_name GroundWindow
extends RefCounted
## The part of the 2D plane that is rendered into the floor texture: a fixed-size window that follows the
## camera, so the texture stays small enough for a phone however big the map is.
## Pure math: where the window is, and how 2D points map onto its texture.

## Texture size in pixels.
var size: Vector2i
## Texture pixels per 2D pixel. Above 1 keeps lines sharp when the camera is close.
var scale: float
## The window's top-left corner on the 2D plane.
var origin := Vector2.ZERO


func _init(texture_size: Vector2i, pixel_scale: float) -> void:
	size = texture_size
	scale = pixel_scale


## Centres the window on a 2D point. The corner snaps to whole texture pixels, so lines on the floor
## don't shimmer as the window moves.
func center_on(point: Vector2) -> void:
	var corner_in_texels := (point * scale - Vector2(size) / 2.0).round()
	origin = corner_in_texels / scale


## How far the window reaches on the 2D plane.
func area() -> Rect2:
	return Rect2(origin, Vector2(size) / scale)


## The transform that draws the 2D plane into the texture.
func canvas_transform() -> Transform2D:
	return Transform2D(0.0, Vector2(scale, scale), 0.0, -origin * scale)
