class_name Utility
extends Item
## What the movement and skill buttons do: on a cooldown, a utility turns an aim into an effect on its user.

## Which button holds it. The hero carries one of each: a movement (Dash, Blink) and a skill (Shield, Frost Nova,
## Lesser Beckoning).
enum Slot { MOVEMENT, SKILL }

## Seconds between uses.
var cooldown := 0.8
var slot := Slot.SKILL


## Default knob shared by every utility.
func knobs() -> Array[Knob]:
	return [Knob.new("cooldown", "Cooldown (s)", 0.2, 20.0, 0.1)]


## strength (0..1) is how far the aim was dragged, for utilities that aim at a spot (a blink).
func activate(_direction: Vector2, _strength := 1.0) -> UtilityEffect:
	return UtilityEffect.new()


## Whether it moves its user at once to a spot (see BlinkLanding), so the preview shows where they would land.
func hops() -> bool:
	return false
