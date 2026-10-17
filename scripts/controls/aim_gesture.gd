class_name AimGesture
extends RefCounted
## Brawl Stars style aiming on a button: a quick tap means "auto-aim",
## dragging past the dead zone aims manually, and releasing fires. Dragging back into the dead zone after
## aiming and letting go there cancels: nothing fires.
## How far the finger is dragged is the aim's strength: 0 just past the dead zone, 1 at full distance.
## Weapons that aim at a spot (like a lobbed fireball) use it as the distance.


## What the player asked for when they let go of the button.
class Release:
	var is_auto: bool
	var direction: Vector2
	var strength: float
	## The player aimed, then brought the finger back to the middle: they changed their mind.
	var is_cancelled: bool

	func _init(auto: bool, aim_direction: Vector2, aim_strength: float, cancelled := false) -> void:
		is_auto = auto
		direction = aim_direction
		strength = aim_strength
		is_cancelled = cancelled


var _dead_zone: float
var _origin := Vector2.ZERO
var _finger := Vector2.ZERO
var _active := false
## Whether this press has left the dead zone at some point.
var _has_aimed := false
var _full_strength_distance := 100.0


func _init(dead_zone_pixels: float) -> void:
	_dead_zone = dead_zone_pixels


## full_strength_distance: how far from the origin the finger must go for full strength.
func begin(origin: Vector2, full_strength_distance := 100.0) -> void:
	_origin = origin
	_full_strength_distance = full_strength_distance
	_finger = origin
	_active = true
	_has_aimed = false


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


## 0 while inside the dead zone, rising to 1 at full strength distance.
func strength() -> float:
	if not is_manual():
		return 0.0
	var travel := _full_strength_distance - _dead_zone
	if travel <= 0.0:
		return 1.0
	return clampf((_origin.distance_to(_finger) - _dead_zone) / travel, 0.0, 1.0)


## A tap auto-aims, a drag fires where it points, and a drag brought back to the middle cancels.
func release() -> Release:
	var cancelled := will_cancel()
	var result := Release.new(not is_manual() and not cancelled, direction(), strength(), cancelled)
	_active = false
	return result
