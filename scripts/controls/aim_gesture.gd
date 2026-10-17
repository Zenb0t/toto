class_name AimGesture
extends RefCounted
## Brawl Stars style aiming on a button: a quick tap means "auto-aim",
## dragging past the dead zone aims manually, and releasing fires. Dragging back into the dead zone after
## aiming and letting go there cancels: nothing fires.
## How far the finger is dragged is the aim's strength. Like Brawl Stars' throwers, the drag isn't held to the
## button: from the dead zone to the button's edge covers the first half (0 to 0.5), and dragging on past the
## edge covers the rest, up to full strength at the full reach. Weapons that aim at a spot (like a lobbed
## fireball) use it as the distance, so fine aiming up close and long throws both fit under a thumb.


## The strength of a drag that ends right on the button's edge.
const BUTTON_EDGE_STRENGTH := 0.5


## What the player asked for when they let go of the button.
class Release:
	var is_auto: bool
	var direction: Vector2
	var strength: float
	## The player aimed, then brought the finger back to the middle: they changed their mind.
	var is_cancelled: bool
	## How long the button was held, for weapons that charge (see Charge).
	var held_seconds: float

	func _init(
			auto: bool, aim_direction: Vector2, aim_strength: float, cancelled := false, held := 0.0) -> void:
		is_auto = auto
		direction = aim_direction
		strength = aim_strength
		is_cancelled = cancelled
		held_seconds = held


var _dead_zone: float
var _origin := Vector2.ZERO
var _finger := Vector2.ZERO
var _active := false
## Whether this press has left the dead zone at some point.
var _has_aimed := false
var _held_seconds := 0.0
var _button_radius := 100.0
var _full_reach := 200.0


func _init(dead_zone_pixels: float) -> void:
	_dead_zone = dead_zone_pixels


## button_radius: how far the drag goes to reach half strength (the button's edge). full_reach: how far for full
## strength; below the button's radius it is the button's radius (no drag past the edge).
func begin(origin: Vector2, button_radius := 100.0, full_reach := 200.0) -> void:
	_origin = origin
	_button_radius = button_radius
	_full_reach = maxf(full_reach, button_radius)
	_finger = origin
	_active = true
	_has_aimed = false
	_held_seconds = 0.0


## Moves time on: the press has been held this much longer.
func tick(delta: float) -> void:
	if _active:
		_held_seconds += delta


## How long the current press has been held.
func held_seconds() -> float:
	return _held_seconds


func move_to(finger: Vector2) -> void:
	_finger = finger
	if is_manual():
		_has_aimed = true


func is_active() -> bool:
	return _active


func is_manual() -> bool:
	return _active and _origin.distance_to(_finger) > _dead_zone


## True while letting go would cancel: the finger aimed, then came back into the dead zone.
func will_cancel() -> bool:
	return _active and _has_aimed and not is_manual()


## Normalized aim direction, or zero while inside the dead zone.
func direction() -> Vector2:
	return (_finger - _origin).normalized() if is_manual() else Vector2.ZERO


## Forget the press without firing (e.g. the game paused under the finger).
func cancel() -> void:
	_active = false
	_finger = _origin


## 0 while inside the dead zone, BUTTON_EDGE_STRENGTH at the button's edge, 1 at the full reach.
func strength() -> float:
	if not is_manual():
		return 0.0
	var distance := _origin.distance_to(_finger)
	if distance < _button_radius:
		return BUTTON_EDGE_STRENGTH * _share(distance, _dead_zone, _button_radius)
	return lerpf(BUTTON_EDGE_STRENGTH, 1.0, _share(distance, _button_radius, _full_reach))


## How far value is from start to end, 0..1. A span with no length counts as already crossed.
static func _share(value: float, start: float, end: float) -> float:
	if end <= start:
		return 1.0
	return clampf((value - start) / (end - start), 0.0, 1.0)


## A tap auto-aims, a drag fires where it points, and a drag brought back to the middle cancels.
func release() -> Release:
	var cancelled := will_cancel()
	var result := Release.new(not is_manual() and not cancelled, direction(), strength(), cancelled, _held_seconds)
	_active = false
	return result
