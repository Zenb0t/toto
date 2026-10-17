class_name AimButton
extends Control
## Round action button with Brawl Stars style aiming: tap for auto-aim, drag to aim, release to fire.
## It floats like the move stick: a touch anywhere in its catch zone (a circle around it, larger than the
## button) grabs it, the button jumps under the finger, and the aim is measured from where the finger landed.
## Where catch zones overlap, the nearest button takes the touch.

## direction is zero while the finger is still inside the dead zone; strength is how far it was dragged (0..1).
signal aim_changed(direction: Vector2, strength: float)
signal aim_released(release: AimGesture.Release)
## A drag that was aiming came back into the dead zone: letting go now cancels. Worth a buzz.
signal returned_to_dead_zone

## How far the finger must move before a press counts as manual aim instead of a tap, in viewport pixels.
const DEFAULT_DEAD_ZONE := 32.0
## The attack button's is a little larger, so a slightly sloppy tap still auto-aims.
const ATTACK_DEAD_ZONE := 36.0
## How far around the button a touch still grabs it, as a multiple of the button's radius.
const DEFAULT_CATCH_SCALE := 1.6
## How far past the button a drag keeps adding strength (full strength), as a multiple of its radius. The
## button's edge is half strength (see AimGesture).
const DEFAULT_DRAG_REACH := 2.5
## Every aim button is in this group, so overlapping catch zones can be settled.
const GROUP := &"aim_buttons"
const CATCH_ZONE_COLOR := Color(1, 1, 1, 0.05)
## The knob while letting go would cancel.
const CANCEL_KNOB_COLOR := Color(0.6, 0.6, 0.6, 0.7)
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

var drag_reach := DEFAULT_DRAG_REACH
## On-screen controls that keep their own touches (the minimap, the Map button), even inside the catch zone.
var blockers: Array[Control] = []
var catch_scale := DEFAULT_CATCH_SCALE:
	set(value):
		catch_scale = value
		queue_redraw()

var dead_zone := DEFAULT_DEAD_ZONE:
	set(value):
		dead_zone = value
		_gesture = AimGesture.new(value)

var _gesture := AimGesture.new(DEFAULT_DEAD_ZONE)
var _touch_index := NO_TOUCH
var _cooldown_ratio := 0.0
## Where the finger landed, in this control's coordinates: the button is drawn there while held.
var _touch_origin := Vector2.ZERO


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	add_to_group(GROUP)


## 1.0 = just used, 0.0 = ready. Drawn as a dark sweep over the button.
func set_cooldown_ratio(ratio: float) -> void:
	if not is_equal_approx(ratio, _cooldown_ratio):
		_cooldown_ratio = ratio
		queue_redraw()


func _process(delta: float) -> void:
	_gesture.tick(delta)


## Whether a finger is on the button, and for how long (weapons that charge).
func is_held() -> bool:
	return _gesture.is_active()


func held_seconds() -> float:
	return _gesture.held_seconds()


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
		var was_aiming := _gesture.is_manual()
		_gesture.move_to(event.position)
		if was_aiming and not _gesture.is_manual():
			returned_to_dead_zone.emit()
		aim_changed.emit(_gesture.direction(), _gesture.strength())
		queue_redraw()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _touch_index == NO_TOUCH and _claims(event.position):
		_touch_index = event.index
		_touch_origin = event.position - global_position
		_gesture.begin(event.position, _radius(), _radius() * drag_reach)
		aim_changed.emit(Vector2.ZERO, 0.0)
		get_viewport().set_input_as_handled()
		queue_redraw()
	elif not event.pressed and event.index == _touch_index:
		_touch_index = NO_TOUCH
		aim_released.emit(_gesture.release())
		queue_redraw()


func _draw() -> void:
	var rest := size / 2.0
	var radius := _radius()
	var center := _touch_origin if _gesture.is_active() else rest
	draw_circle(rest, radius * catch_scale, CATCH_ZONE_COLOR)
	draw_circle(center, radius, Color(color, 0.35 if _gesture.is_active() else 0.5))
	if _cooldown_ratio > 0.0:
		var sweep := TAU * _cooldown_ratio
		draw_arc(center, radius * 0.5, -PI / 2.0, -PI / 2.0 + sweep, 32, Color(0, 0, 0, 0.6), radius, true)
	var knob_reach := lerpf(MIN_KNOB_TRAVEL, KNOB_TRAVEL, _gesture.strength())
	var knob := center + _gesture.direction() * radius * knob_reach
	draw_circle(knob, radius * 0.35, CANCEL_KNOB_COLOR if _gesture.will_cancel() else Color(color, 0.9))
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


func _catch_radius() -> float:
	return _radius() * catch_scale


## Whether a new touch is this button's: inside its catch zone, closer to it than to any other aim button
## whose zone it is also in, and not on a control that keeps its touches.
func _claims(point: Vector2) -> bool:
	if TouchZones.is_kept_by(point, blockers):
		return false
	var rivals: Array[AimButton] = []
	var centers: Array[Vector2] = []
	var radii: Array[float] = []
	for each: AimButton in get_tree().get_nodes_in_group(GROUP):
		if each.accepts_touch and each.is_visible_in_tree():
			rivals.append(each)
			centers.append(each._global_center())
			radii.append(each._catch_radius())
	var owner := TouchZones.owner_of(point, centers, radii)
	return owner != TouchZones.NONE and rivals[owner] == self
