class_name Ammo
extends RefCounted
## Brawl Stars style ammo: a few charges, one spent per attack, reloading one at a time while not full.
## Attacking throws away the charge being reloaded: firing again in quick succession costs that progress.

var capacity: int
## Seconds to reload one charge.
var reload_seconds: float
var _charges: int
## How far into reloading the next charge, in seconds.
var _reloading := 0.0


func _init(max_charges: int, seconds_per_charge: float) -> void:
	capacity = maxi(max_charges, 1)
	reload_seconds = maxf(seconds_per_charge, 0.0)
	_charges = capacity


func charges() -> int:
	return _charges


func is_full() -> bool:
	return _charges >= capacity


## Spends a charge and returns true, or returns false when empty. The charge being reloaded starts over.
func try_spend() -> bool:
	if _charges <= 0:
		return false
	_charges -= 1
	_reloading = 0.0
	return true


func tick(delta: float) -> void:
	if is_full():
		_reloading = 0.0
		return
	if reload_seconds <= 0.0:
		_charges = capacity
		return
	_reloading += delta
	while _reloading >= reload_seconds and not is_full():
		_reloading -= reload_seconds
		_charges += 1
	if is_full():
		_reloading = 0.0


## The charges, counting the one reloading as a fraction (2.5 = two ready, the third half reloaded).
func level() -> float:
	if is_full() or reload_seconds <= 0.0:
		return float(_charges)
	return _charges + _reloading / reload_seconds


## How full each charge's segment of an ammo bar is, 0..1, first to last.
func segment_fills() -> Array[float]:
	var fills: Array[float] = []
	for index in capacity:
		fills.append(clampf(level() - index, 0.0, 1.0))
	return fills
