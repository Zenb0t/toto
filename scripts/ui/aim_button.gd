class_name AimButton
extends Control
## Round action button with Brawl Stars style aiming: tap for auto-aim, drag to aim, release to fire.

## direction is zero while the finger is still inside the dead zone; strength is how far it was dragged (0..1).
signal aim_changed(direction: Vector2, strength: float)
signal aim_released(release: AimGesture.Release)

## How far the finger must move before a press counts as manual aim instead of a tap, in viewport pixels.
const DEFAULT_DEAD_ZONE := 32.0
const NO_TOUCH := -1
const KNOB_TRAVEL := 0.6  ## How far the knob moves at full strength, relative to the button radius.
const MIN_KNOB_TRAVEL := 0.25  ## Where the knob sits just past the dead zone, so aiming is always visible.
const MIN_FONT_SIZE := 14
const FONT_SIZE_PER_RADIUS := 0.2
const LABEL_COLOR := Color(1, 1, 1, 0.85)
const HINT_COLOR := Color(1, 1, 1, 0.6)
const HINT_FONT_SCALE := 0.75

## Set from the equipped item.
@export var label := "":
	set(value):
		label = value
		queue_redraw()
@export var color := Color(1.0, 0.8, 0.3):
	set(value):
		color = value
		queue_redraw()
## A small line under the label, such as the key that does the same thing.
var hint := "":
	set(value):
		hint = value
		queue_redraw()
## Off, the button ignores touches (another way of playing is in use) but still shows the item and its cooldown.
var accepts_touch := true:
	set(value):
		accepts_touch = value
		set_process_input(value)
		if not value:
			_forget_touch()

var dead_zone := DEFAULT_DEAD_ZONE:
	set(value):
		dead_zone = value
		_gesture = AimGesture.new(value)

var _gesture := AimGesture.new(DEFAULT_DEAD_ZONE)
var _touch_index := NO_TOUCH
var _cooldown_ratio := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


## 1.0 = just used, 0.0 = ready. Drawn as a dark sweep over the button.
func set_cooldown_ratio(ratio: float) -> void:
	if not is_equal_approx(ratio, _cooldown_ratio):
		_cooldown_ratio = ratio
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_forget_touch()


## Lets go of a press without firing (the game paused under the finger, or touch was turned off).
func _forget_touch() -> void:
	if _touch_index == NO_TOUCH:
		return
	_touch_index = NO_TOUCH
	_gesture.cancel()
	aim_changed.emit(Vector2.ZERO, 0.0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_gesture.move_to(event.position)
		aim_changed.emit(_gesture.direction(), _gesture.strength())
		queue_redraw()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_index == NO_TOUCH and _contains(event.position):
		_touch_index = event.index
		_gesture.begin(_global_center(), _radius())
		aim_changed.emit(Vector2.ZERO, 0.0)
		get_viewport().set_input_as_handled()
		queue_redraw()
	elif not event.pressed and event.index == _touch_index:
		_touch_index = NO_TOUCH
		aim_released.emit(_gesture.release())
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := _radius()
	draw_circle(center, radius, Color(color, 0.35 if _gesture.is_active() else 0.5))
	if _cooldown_ratio > 0.0:
		var sweep := TAU * _cooldown_ratio
		draw_arc(center, radius * 0.5, -PI / 2.0, -PI / 2.0 + sweep, 32, Color(0, 0, 0, 0.6), radius, true)
	var knob_reach := lerpf(MIN_KNOB_TRAVEL, KNOB_TRAVEL, _gesture.strength())
	var knob := center + _gesture.direction() * radius * knob_reach
	draw_circle(knob, radius * 0.35, Color(color, 0.9))
	var font := ThemeDB.fallback_font
	var font_size := maxi(MIN_FONT_SIZE, roundi(radius * FONT_SIZE_PER_RADIUS))
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var baseline := center + Vector2(-text_size.x / 2.0, text_size.y * 0.35)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, LABEL_COLOR)
	if hint != "":
		var hint_size := roundi(font_size * HINT_FONT_SCALE)
		var hint_width := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_CENTER, -1, hint_size).x
		var hint_baseline := center + Vector2(-hint_width / 2.0, text_size.y * 0.35 + font_size * 1.1)
		draw_string(font, hint_baseline, hint, HORIZONTAL_ALIGNMENT_CENTER, -1, hint_size, HINT_COLOR)


func _radius() -> float:
	return minf(size.x, size.y) / 2.0


func _global_center() -> Vector2:
	return global_position + size / 2.0


func _contains(point: Vector2) -> bool:
	return point.distance_to(_global_center()) <= _radius()
