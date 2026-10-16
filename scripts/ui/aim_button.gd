class_name AimButton
extends Control
## Round action button with Brawl Stars style aiming: tap for auto-aim, drag to aim, release to fire.

signal aim_changed(direction: Vector2)  ## Zero while the finger is still inside the dead zone.
signal aim_released(release: AimGesture.Release)

const DEAD_ZONE := 18.0
const NO_TOUCH := -1
const KNOB_TRAVEL := 0.6  ## How far the knob moves when aiming, relative to the button radius.
const MIN_FONT_SIZE := 14
const FONT_SIZE_PER_RADIUS := 0.2
const LABEL_COLOR := Color(1, 1, 1, 0.85)

## Set from the equipped item.
@export var label := "":
	set(value):
		label = value
		queue_redraw()
@export var color := Color(1.0, 0.8, 0.3):
	set(value):
		color = value
		queue_redraw()

var _gesture := AimGesture.new(DEAD_ZONE)
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
	if what == NOTIFICATION_PAUSED and _touch_index != NO_TOUCH:
		_touch_index = NO_TOUCH
		_gesture.cancel()
		aim_changed.emit(Vector2.ZERO)
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_gesture.move_to(event.position)
		aim_changed.emit(_gesture.direction())
		queue_redraw()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_index == NO_TOUCH and _contains(event.position):
		_touch_index = event.index
		_gesture.begin(_global_center())
		aim_changed.emit(Vector2.ZERO)
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
	var knob := center + _gesture.direction() * radius * KNOB_TRAVEL
	draw_circle(knob, radius * 0.35, Color(color, 0.9))
	var font := ThemeDB.fallback_font
	var font_size := maxi(MIN_FONT_SIZE, roundi(radius * FONT_SIZE_PER_RADIUS))
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var baseline := center + Vector2(-text_size.x / 2.0, text_size.y * 0.35)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, LABEL_COLOR)


func _radius() -> float:
	return minf(size.x, size.y) / 2.0


func _global_center() -> Vector2:
	return global_position + size / 2.0


func _contains(point: Vector2) -> bool:
	return point.distance_to(_global_center()) <= _radius()
