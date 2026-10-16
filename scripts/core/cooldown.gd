class_name Cooldown
extends RefCounted
## A reusable "can I do this again yet?" timer driven by the caller's delta.

var duration: float
var _remaining := 0.0


func _init(duration_seconds: float) -> void:
	assert(duration_seconds >= 0.0, "duration must not be negative")
	duration = duration_seconds


func tick(delta: float) -> void:
	_remaining = maxf(_remaining - delta, 0.0)


func is_ready() -> bool:
	return _remaining == 0.0


## Starts the cooldown and returns true if it was ready, otherwise does nothing.
func try_trigger() -> bool:
	if not is_ready():
		return false
	_remaining = duration
	return true
