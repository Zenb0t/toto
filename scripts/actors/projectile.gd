class_name Projectile
extends Area2D
## Flies a Shot straight until it hits something or runs out of range.
## A plain shot damages what it hits; an explosive shot bursts into an Explosion instead.
## A lobbed shot arcs over everything and bursts where it lands.

## How high a lob arcs, relative to how far it travels, and never higher than LOB_MAX_HEIGHT.
const LOB_HEIGHT_PER_DISTANCE := 0.35
const LOB_MAX_HEIGHT := 90.0
const SHADOW_COLOR := Color(0, 0, 0, 0.35)
## Physics layers (see the actor scenes): what a straight shot can bump into.
const WALL_LAYER_BIT := 1
const PLAYER_LAYER_BIT := 2
const ENEMY_LAYER_BIT := 4

var _shot: Shot
var _time_left := 0.0
var _spent := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Must be called before the projectile is added to the tree.
func launch(shot: Shot) -> void:
	_shot = shot
	position = shot.origin
	_time_left = shot.lifetime()
	if shot.lobbed:
		collision_mask = 0
	else:
		collision_mask = WALL_LAYER_BIT | (PLAYER_LAYER_BIT if shot.hurts_player else ENEMY_LAYER_BIT)


func _physics_process(delta: float) -> void:
	position += _shot.direction * _shot.speed * delta
	_time_left -= delta
	if _time_left <= 0.0:
		_finish()
	elif _shot.lobbed:
		queue_redraw()


func _draw() -> void:
	if not _shot.lobbed:
		draw_circle(Vector2.ZERO, _shot.size, _shot.color)
		return
	draw_circle(Vector2.ZERO, _shot.size * 0.8, SHADOW_COLOR)
	draw_circle(Vector2(0, -_lob_height()), _shot.size, _shot.color)


## Height above the ground along a parabola: zero at launch and landing, highest halfway.
func _lob_height() -> float:
	var lifetime := _shot.lifetime()
	var progress := 1.0 - _time_left / lifetime if lifetime > 0.0 else 1.0
	var peak := minf(_shot.travel_range * LOB_HEIGHT_PER_DISTANCE, LOB_MAX_HEIGHT)
	return 4.0 * peak * progress * (1.0 - progress)


func _on_body_entered(body: Node2D) -> void:
	if not _shot.explodes() and body.has_method("take_damage"):
		body.take_damage(_shot.damage)
	_finish()


## A shot can touch a wall and an enemy in the same frame: only the first contact counts.
func _finish() -> void:
	if _spent:
		return
	_spent = true
	if _shot.explodes():
		var explosion := Explosion.new(_shot.blast_radius, _shot.damage, _shot.color)
		explosion.position = position
		get_parent().add_child.call_deferred(explosion)
	queue_free()
