class_name Projectile
extends Area2D
## Flies straight until it hits something or runs out of range. Damages anything that can take damage.

const RADIUS := 5.0
const COLOR := Color(1.0, 0.9, 0.4)

var _velocity := Vector2.ZERO
var _damage := 0
var _time_left := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Must be called before the projectile is added to the tree.
func launch(shot: Shot) -> void:
	position = shot.origin
	_velocity = shot.direction * shot.speed
	_damage = shot.damage
	_time_left = shot.lifetime()


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	queue_free()
