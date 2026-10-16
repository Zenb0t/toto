class_name FloatingText
extends Label3D
## A short message that rises from a spot and shrinks away (a level up, later damage numbers). It stays
## opaque: partly transparent text renders muddy in the Compatibility renderer.

const RISE := 1.2
const SECONDS := 1.2
const START_HEIGHT := 1.8
const FONT_SIZE := 56
const PIXEL_SIZE := 0.01
## The share of its time at the end during which it shrinks away.
const SHRINK_SHARE := 0.25

var _elapsed := 0.0
var _start: Vector3


func _init(message: String, color: Color, at: Vector3) -> void:
	text = message
	modulate = color
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	font_size = FONT_SIZE
	pixel_size = PIXEL_SIZE
	outline_size = 14
	_start = at + Vector3(0, START_HEIGHT, 0)
	position = _start


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / SECONDS, 0.0, 1.0)
	position = _start + Vector3(0, RISE * progress, 0)
	scale = Vector3.ONE * clampf((1.0 - progress) / SHRINK_SHARE, 0.01, 1.0)
	if progress >= 1.0:
		queue_free()
