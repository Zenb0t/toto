class_name Blink
extends Utility
## Like Dungeon Crawl's scroll of blinking: an instant hop where you aim. Walls and water stop it short;
## enemies don't, so it gets you out of a corner.

var distance := 140.0


func _init() -> void:
	id = "blink"
	display_name = "Blink"
	description = "Jump instantly where you aim, past enemies."
	button_label = "BLINK"
	color = Color(0.85, 0.5, 1.0)
	cooldown = 4.0


func knobs() -> Array[Knob]:
	var result: Array[Knob] = [Knob.new("distance", "Distance", 40, 400, 10)]
	result.append_array(super.knobs())
	return result


func activate(direction: Vector2) -> UtilityEffect:
	return UtilityEffect.blink(direction.normalized() * distance)


func aim_range() -> float:
	return distance


func aim_shape() -> AimShape:
	return AimShape.line(distance)
