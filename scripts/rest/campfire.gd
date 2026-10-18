class_name Campfire
extends RefCounted
## One campfire's state: unlit, burning, embers, unlit again.
##
##   UNLIT ──light()──▶ BURNING ──after burn_seconds──▶ EMBERS ──after embers_seconds──▶ UNLIT
##
## While it burns, a hero standing in its light heals up to the profile's ceiling (a share of their maximum
## health), at the profile's rate. Stepping out of the light pauses the healing; a hit or an attack (interrupt())
## ends it for this lighting, though the fire burns on. Time only moves when tick() is called, which is how a
## campfire's countdowns run only while the hero is on its map. Pure: the game carries out the healing and shows
## the fire.

enum State { UNLIT, BURNING, EMBERS }

var profile: RestProfile
var state := State.UNLIT
var _seconds_left := 0.0
var _healing_ended := false
## Healing worked out but not yet whole health points.
var _heal_carry := 0.0


## A campfire as it was left: restored from a record (see MapRecord.campfire_at) with the time it had left.
func _init(rest_profile := RestProfile.campfire(), start := State.UNLIT, seconds_left := 0.0) -> void:
	profile = rest_profile
	state = start
	_seconds_left = maxf(seconds_left, 0.0) if start != State.UNLIT else 0.0


func can_light() -> bool:
	return state == State.UNLIT


## Lights it, if it is unlit. False when it is burning or in embers.
func light() -> bool:
	if not can_light():
		return false
	state = State.BURNING
	_seconds_left = profile.burn_seconds
	_healing_ended = false
	_heal_carry = 0.0
	return true


## Seconds until the state changes: the burn left, or the embers' countdown (0 when unlit).
func seconds_left() -> float:
	return _seconds_left


## A hit or an attack: the hero's healing at this lighting ends (the fire burns on).
func interrupt() -> void:
	_healing_ended = true


func is_healing_ended() -> bool:
	return _healing_ended


## Moves time on and returns the whole health points healed meanwhile: only while it burns, the healing has not
## been ended, and the hero is in the light (hero_in_light), and never past the profile's ceiling for max_health.
func tick(delta: float, hero_in_light: bool, health: int, max_health: int) -> int:
	var healed := 0
	if state == State.BURNING:
		if hero_in_light and not _healing_ended:
			healed = _heal(minf(delta, _seconds_left), health, max_health)
		_seconds_left = maxf(_seconds_left - delta, 0.0)
		if _seconds_left <= 0.0:
			state = State.EMBERS
			_seconds_left = profile.embers_seconds
			_healing_ended = true
	elif state == State.EMBERS:
		_seconds_left = maxf(_seconds_left - delta, 0.0)
	if state == State.EMBERS and _seconds_left <= 0.0:
		state = State.UNLIT
	return healed


func _heal(seconds: float, health: int, max_health: int) -> int:
	var room := profile.heal_ceiling(max_health) - health
	if room <= 0:
		_heal_carry = 0.0
		return 0
	_heal_carry += seconds * profile.heal_per_second
	var whole := mini(floori(_heal_carry), room)
	_heal_carry -= whole
	return whole
