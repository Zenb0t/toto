class_name AimGesture
extends RefCounted
## Brawl Stars style aiming on a button: a quick tap means "auto-aim",
## dragging past the dead zone aims manually, and releasing fires.


## What the player asked for when they let go of the button.
class Release:
	var is_auto: bool
	var direction: Vector2

	func _init(auto: bool, aim_direction: Vector2) -> void:
		is_auto = auto
		direction = aim_direction


var _dead_zone: float
var _origin := Vector2.ZERO
var _finger := Vector2.ZERO
var _active := false


func _init(dead_zone_pixels: float) -> void:
	_dead_zone = dead_zone_pixels


func begin(origin: Vector2) -> void:
	_origin = origin
	_finger = origin
	_active = true


func move_to(finger: Vector2) -> void:
	_finger = finger


func is_active() -> bool:
	return _active


func is_manual() -> bool:
	return _active and _origin.distance_to(_finger) > _dead_zone


## Normalized aim direction, or zero while inside the dead zone.
func direction() -> Vector2:
	return (_finger - _origin).normalized() if is_manual() else Vector2.ZERO


## Forget the press without firing (e.g. the game paused under the finger).
func cancel() -> void:
	_active = false
	_finger = _origin


func release() -> Release:
	var result := Release.new(not is_manual(), direction())
	_active = false
	return result
