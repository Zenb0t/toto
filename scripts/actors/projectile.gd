class_name Projectile
extends Area2D
## Flies a Shot straight until it hits something or runs out of range.
## A plain shot damages what it hits; an explosive shot bursts into an Explosion instead.

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


func _physics_process(delta: float) -> void:
	position += _shot.direction * _shot.speed * delta
	_time_left -= delta
	if _time_left <= 0.0:
		_finish()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _shot.size, _shot.color)


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
