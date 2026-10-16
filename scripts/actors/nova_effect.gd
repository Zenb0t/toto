class_name NovaEffect
extends Node2D
## Carries out a Nova: hurts and slows every foe it touches the moment it appears, then a ring spreads
## out on the floor and fades.

const SPREAD_SECONDS := 0.3
const RING_WIDTH := 4.0

var _nova: Nova
var _elapsed := 0.0


func _init(nova: Nova) -> void:
	_nova = nova
	position = nova.origin


func _ready() -> void:
	var foes := Player.GROUP if _nova.hurts_player else Enemy.GROUP
	for foe: Node2D in get_tree().get_nodes_in_group(foes):
		if HitShapes.in_circle(global_position, _nova.radius + foe.body_radius(), foe.global_position):
			foe.take_damage(_nova.damage)
			if foe.has_method("slow"):
				foe.slow(_nova.slow_multiplier, _nova.slow_seconds)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= SPREAD_SECONDS:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_elapsed / SPREAD_SECONDS, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _nova.radius, Color(_nova.color, 0.3 * (1.0 - progress)))
	draw_arc(Vector2.ZERO, _nova.radius * progress, 0.0, TAU, 48, Color(_nova.color, 1.0 - progress), RING_WIDTH, true)
