class_name Projectile
extends Area2D
## Flies straight until it hits something. Damages anything that can take damage.

const SPEED := 520.0
const DAMAGE := 1
const LIFETIME := 1.2
const RADIUS := 5.0
const COLOR := Color(1.0, 0.9, 0.4)

var _direction := Vector2.RIGHT
var _time_left := LIFETIME


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Must be called before the projectile is added to the tree.
func launch(origin: Vector2, direction: Vector2) -> void:
	position = origin
	_direction = direction.normalized()


func _physics_process(delta: float) -> void:
	position += _direction * SPEED * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	queue_free()
