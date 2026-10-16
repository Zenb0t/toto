class_name Explosion
extends Node2D
## Damages every enemy within its radius the moment it appears, then fades out.

const FADE_SECONDS := 0.25

var _radius: float
var _damage: int
var _color: Color
var _time_left := FADE_SECONDS


func _init(radius: float, damage: int, color: Color) -> void:
	_radius = radius
	_damage = damage
	_color = color


func _ready() -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group(Enemy.GROUP):
		if HitShapes.in_circle(global_position, _radius + Enemy.RADIUS, enemy.global_position):
			enemy.take_damage(_damage)


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := clampf(_time_left / FADE_SECONDS, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius, Color(_color, 0.45 * fade))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, Color(_color, 0.9 * fade), 3.0, true)
