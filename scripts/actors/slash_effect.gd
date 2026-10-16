class_name SlashEffect
extends Node2D
## Performs a Slash: hits every enemy inside the arc the moment it appears, then shows the swing briefly.

const FADE_SECONDS := 0.15
const ARC_POINTS := 24

var _slash: Slash
var _time_left := FADE_SECONDS


func _init(slash: Slash) -> void:
	_slash = slash
	position = slash.origin


func _ready() -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group(Enemy.GROUP):
		var reach := _slash.reach + Enemy.RADIUS
		if HitShapes.in_arc(_slash.origin, _slash.direction, reach, _slash.arc_degrees, enemy.global_position):
			enemy.take_damage(_slash.damage)


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := clampf(_time_left / FADE_SECONDS, 0.0, 1.0)
	draw_colored_polygon(
		ArcPolygon.wedge(_slash.direction, _slash.reach, _slash.arc_degrees, ARC_POINTS),
		Color(_slash.color, 0.5 * fade))
