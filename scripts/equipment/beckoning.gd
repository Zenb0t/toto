class_name Beckoning
extends Utility
## Dungeon Crawl's Lesser Beckoning, thrown like Gene's magic hand in Brawl Stars: a quick bolt that drags
## the first enemy it touches back to where it was cast, interrupting whatever it was about to do.

var shot_speed := 700.0
var shot_range := 320.0


func _init() -> void:
	id = "beckoning"
	display_name = "Lesser Beckoning"
	description = "Pulls the first enemy it hits to you."
	button_label = "BECKON"
	color = Color(0.95, 0.6, 0.95)
	cooldown = 5.0


func knobs() -> Array[Knob]:
	var result: Array[Knob] = [
		Knob.new("shot_speed", "Shot speed", 200, 1500, 10),
		Knob.new("shot_range", "Range", 100, 800, 10),
	]
	result.append_array(super.knobs())
	return result


## The shot starts at its user, who sets its origin (see Player).
func activate(direction: Vector2) -> UtilityEffect:
	var shot := Shot.new(Vector2.ZERO, direction, shot_speed, 0, shot_range)
	shot.pulls = true
	shot.size = 6.0
	shot.color = color
	var effect := UtilityEffect.new()
	effect.attacks = [shot]
	return effect


func aim_range() -> float:
	return shot_range


func aim_shape() -> AimShape:
	return AimShape.line(shot_range)
