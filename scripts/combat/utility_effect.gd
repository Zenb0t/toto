class_name UtilityEffect
extends RefCounted
## What using a utility or drinking a potion does to its user, for the user to carry out. Fields left at
## zero do nothing.

var dash_direction := Vector2.ZERO
var dash_speed := 0.0
var dash_seconds := 0.0
## Seconds during which the user takes no damage.
var shield_seconds := 0.0
var heal_amount := 0
## Moves the user at once toward the spot this far away, landing where a blink can (see BlinkLanding).
var blink_offset := Vector2.ZERO
## Attacks (like a Nova) the user lets out, centred on the user, for the world to carry out.
var attacks: Array = []
## For haste_seconds, the user moves haste_multiplier times faster.
var haste_multiplier := 1.0
var haste_seconds := 0.0
## For might_seconds, every attack of the user does might_bonus more damage.
var might_bonus := 0
var might_seconds := 0.0


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


static func haste(multiplier: float, seconds: float) -> UtilityEffect:
	var effect := UtilityEffect.new()
	effect.haste_multiplier = multiplier
	effect.haste_seconds = seconds
	return effect


static func might(bonus: int, seconds: float) -> UtilityEffect:
	var effect := UtilityEffect.new()
	effect.might_bonus = bonus
	effect.might_seconds = seconds
	return effect


static func blink(offset: Vector2) -> UtilityEffect:
	var effect := UtilityEffect.new()
	effect.blink_offset = offset
	return effect


static func burst(nova: Nova) -> UtilityEffect:
	var effect := UtilityEffect.new()
	effect.attacks = [nova]
	return effect
