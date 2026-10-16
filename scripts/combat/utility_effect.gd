class_name UtilityEffect
extends RefCounted
## What using a utility does to its user, for the user to carry out. Fields left at zero do nothing.

var dash_direction := Vector2.ZERO
var dash_speed := 0.0
var dash_seconds := 0.0
## Seconds during which the user takes no damage.
var shield_seconds := 0.0
var heal_amount := 0


static func dash(direction: Vector2, speed: float, seconds: float) -> UtilityEffect:
	var effect := UtilityEffect.new()
	effect.dash_direction = direction.normalized()
	effect.dash_speed = speed
	effect.dash_seconds = seconds
	return effect


static func shield(seconds: float) -> UtilityEffect:
	var effect := UtilityEffect.new()
	effect.shield_seconds = seconds
	return effect


static func heal(amount: int) -> UtilityEffect:
	var effect := UtilityEffect.new()
	effect.heal_amount = amount
	return effect
