class_name Explosion
extends Node2D
## Damages every enemy and player within its radius the moment it appears, then fades out.
## It doesn't care who threw it: standing in your own blast hurts.

const FADE_SECONDS := 0.25

var _radius: float
var _damage: int
var _color: Color
var _time_left := FADE_SECONDS
var _source: String


## source: who threw it (see Shot.source).
func _init(radius: float, damage: int, color: Color, source := "") -> void:
	_radius = radius
	_damage = damage
	_color = color
	_source = source


func _ready() -> void:
	_hurt_group(Enemy.GROUP)
	_hurt_group(Player.GROUP)


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
	queue_redraw()


## Bodies are hit when the blast touches their edge, not only their centre.
func _hurt_group(group: StringName) -> void:
	for body: Node2D in get_tree().get_nodes_in_group(group):
		if HitShapes.in_circle(global_position, _radius + body.body_radius(), body.global_position):
			body.take_damage(_damage, _source)


func _draw() -> void:
	var fade := clampf(_time_left / FADE_SECONDS, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius, Color(_color, 0.45 * fade))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, Color(_color, 0.9 * fade), 3.0, true)
