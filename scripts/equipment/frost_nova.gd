class_name FrostNova
extends Utility
## Like Dungeon Crawl's Ozocubu's Refrigeration, in a small burst: hurts every enemy around you and slows
## them (movement and attacks) for a while. Aiming doesn't matter; holding the button shows the area.

var radius := 110.0
var damage := 1
## Slowed enemies act at this fraction of their speed.
var slow_multiplier := 0.5
var slow_seconds := 2.5


func _init() -> void:
	id = "frost_nova"
	display_name = "Frost Nova"
	description = "Chills every enemy around you: a little damage, and they slow down."
	button_label = "FROST"
	color = Color(0.6, 0.9, 1.0)
	cooldown = 6.0


func knobs() -> Array[Knob]:
	var result: Array[Knob] = [
		Knob.new("radius", "Radius", 40, 300, 5),
		Knob.new("damage", "Damage", 0, 5, 1),
		Knob.new("slow_multiplier", "Slowed speed (x)", 0.1, 1.0, 0.05),
		Knob.new("slow_seconds", "Slow time (s)", 0.5, 8.0, 0.1),
	]
	result.append_array(super.knobs())
	return result


func activate(_direction: Vector2) -> UtilityEffect:
	return UtilityEffect.burst(Nova.new(radius, damage, slow_multiplier, slow_seconds, color))


func aim_range() -> float:
	return radius


## The area around the user (a line of no length, ending in the burst's circle).
func aim_shape() -> AimShape:
	return AimShape.line(0.0, radius)
