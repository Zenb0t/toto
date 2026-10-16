class_name Utility
extends Item
## What the second button does: on a cooldown, it turns an aim direction into an effect on its user.


## Default knob shared by every utility.
func knobs() -> Array[Knob]:
	return [Knob.new("cooldown", "Cooldown (s)", 0.2, 20.0, 0.1)]


func activate(_direction: Vector2) -> UtilityEffect:
	return UtilityEffect.new()
