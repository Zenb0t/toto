class_name InnRest
extends RefCounted
## One rest at the inn: the hero sits for the profile's rest_seconds, then is healed to the profile's ceiling (full
## health). Moving or being hit cancels it (when the profile says moving does), and a new rest can begin at once:
## there is no ambush and no limit. Time only moves when tick() is called. Pure: whether the monsters around allow it
## is MonstersAround's rule, asked before begin(); the game carries out the healing and shows the rest.

enum Step { NONE, CANCELLED, COMPLETED }

var profile: RestProfile
var _seconds_left := 0.0
var _resting := false


func _init(rest_profile := RestProfile.inn()) -> void:
	profile = rest_profile


func is_resting() -> bool:
	return _resting


## Sits down. False when already resting.
func begin() -> bool:
	if _resting:
		return false
	_resting = true
	_seconds_left = profile.rest_seconds
	return true


## How much of the rest is done, 0..1 (0 when not resting).
func progress() -> float:
	if not _resting:
		return 0.0
	return 1.0 - _seconds_left / maxf(profile.rest_seconds, 0.001)


## A hit (or anything else that ends the rest). True when it was resting.
func interrupt() -> bool:
	var was_resting := _resting
	_resting = false
	return was_resting


## Moves time on. hero_moving cancels the rest when the profile says moving does. Returns how the rest ended
## during this step, if it did.
func tick(delta: float, hero_moving: bool) -> Step:
	if not _resting:
		return Step.NONE
	if hero_moving and profile.cancels_on_move:
		_resting = false
		return Step.CANCELLED
	_seconds_left = maxf(_seconds_left - delta, 0.0)
	if _seconds_left <= 0.0:
		_resting = false
		return Step.COMPLETED
	return Step.NONE


## The health points a finished rest restores a hero with this health.
func heal_for(health: int, max_health: int) -> int:
	return maxi(profile.heal_ceiling(max_health) - health, 0)
