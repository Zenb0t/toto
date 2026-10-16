class_name AimGesture
extends RefCounted
## Brawl Stars style aiming on a button: a quick tap means "auto-aim",
## dragging past the dead zone aims manually, and releasing fires.
## How far the finger is dragged is the aim's strength: 0 just past the dead zone, 1 at full distance.
## Weapons that aim at a spot (like a lobbed fireball) use it as the distance.


## What the player asked for when they let go of the button.
class Release:
	var is_auto: bool
	var direction: Vector2
	var strength: float

	func _init(auto: bool, aim_direction: Vector2, aim_strength: float) -> void:
		is_auto = auto
		direction = aim_direction
		strength = aim_strength


var _dead_zone: float
var _origin := Vector2.ZERO
var _finger := Vector2.ZERO
var _active := false
var _full_strength_distance := 100.0


func _init(dead_zone_pixels: float) -> void:
	_dead_zone = dead_zone_pixels


## full_strength_distance: how far from the origin the finger must go for full strength.
func begin(origin: Vector2, full_strength_distance := 100.0) -> void:
	_origin = origin
	_full_strength_distance = full_strength_distance
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


## 0 while inside the dead zone, rising to 1 at full strength distance.
func strength() -> float:
	if not is_manual():
		return 0.0
	var travel := _full_strength_distance - _dead_zone
	if travel <= 0.0:
		return 1.0
	return clampf((_origin.distance_to(_finger) - _dead_zone) / travel, 0.0, 1.0)


func release() -> Release:
	var result := Release.new(not is_manual(), direction(), strength())
	_active = false
	return result
