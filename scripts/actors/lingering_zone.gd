class_name LingeringZone
extends Node2D
## A patch of ground that keeps hurting whoever stands in it, tick after tick, until it runs out. Subclasses
## say who it hurts, when it ticks and how it looks; `source` is who made it (see Shot.source).

var _radius: float
var _damage: int
var _seconds: float
## Who threw it (see Shot.source).
var source := ""
var _elapsed := 0.0
var _clock: TickClock


func _init(radius: float, damage: int, seconds: float, clock: TickClock) -> void:
	_radius = radius
	_damage = damage
	_seconds = seconds
	_clock = clock


## The groups ("player", "enemy") whose members this zone hurts.
func _target_groups() -> Array[StringName]:
	return []


## Draws the zone; `left` runs from 1 (just made) down to 0 (gone).
func _draw_zone(_left: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	_elapsed += delta
	for tick in _clock.advance(delta):
		_hurt_bodies_inside()
	if _elapsed >= _seconds:
		queue_free()
	queue_redraw()


func _hurt_bodies_inside() -> void:
	for group in _target_groups():
		for body: Node2D in get_tree().get_nodes_in_group(group):
			if HitShapes.in_circle(global_position, _radius + body.body_radius(), body.global_position):
				body.take_damage(_damage, source)


func _draw() -> void:
	_draw_zone(clampf(1.0 - _elapsed / _seconds, 0.0, 1.0))
