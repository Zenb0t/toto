class_name TouchStick
extends Control
## Floating joystick: put a thumb anywhere inside this control and the stick appears under it.
## While idle it shows a faint hint at its resting spot.

signal strength_changed(strength: Vector2)

const DEFAULT_RADIUS := 95.0
const NO_TOUCH := -1
const BASE_COLOR := Color(1, 1, 1, 0.12)
const KNOB_COLOR := Color(1, 1, 1, 0.45)

## How far the thumb travels for full speed. Also the drawn size of the stick.
var radius := DEFAULT_RADIUS:
	set(value):
		radius = value
		queue_redraw()
## Where the idle hint is drawn, in this control's local coordinates.
var rest_center := Vector2.ZERO:
	set(value):
		rest_center = value
		queue_redraw()

## Off, the stick is hidden and ignores touches (another way of playing is in use).
var accepts_touch := true:
	set(value):
		accepts_touch = value
		visible = value
		set_process_input(value)
		if not value:
			_forget_touch()

var _touch_index := NO_TOUCH
var _origin := Vector2.ZERO
var _finger := Vector2.ZERO


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func current_strength() -> Vector2:
	if _touch_index == NO_TOUCH:
		return Vector2.ZERO
	return StickMath.strength(_origin, _finger, radius)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_forget_touch()


func _forget_touch() -> void:
	if _touch_index == NO_TOUCH:
		return
	_touch_index = NO_TOUCH
	strength_changed.emit(Vector2.ZERO)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_finger = event.position
		strength_changed.emit(current_strength())
		queue_redraw()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_index == NO_TOUCH and get_global_rect().has_point(event.position):
		_touch_index = event.index
		_origin = event.position
		_finger = event.position
		get_viewport().set_input_as_handled()
		queue_redraw()
	elif not event.pressed and event.index == _touch_index:
		_touch_index = NO_TOUCH
		strength_changed.emit(Vector2.ZERO)
		queue_redraw()


func _draw() -> void:
	if _touch_index == NO_TOUCH:
		draw_circle(rest_center, radius, BASE_COLOR)
		return
	var base := _origin - global_position
	draw_circle(base, radius, BASE_COLOR)
	draw_circle(base + current_strength() * radius, radius * 0.45, KNOB_COLOR)
