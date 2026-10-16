class_name PickupArea
extends Area2D
## A spot on the floor that notices the player stepping on and off it. Walls and enemies don't touch it.

signal player_entered
signal player_exited

## The player's physics layer (see player.tscn).
const PLAYER_LAYER := 2

var radius: float


func _init(pickup_radius: float) -> void:
	radius = pickup_radius
	collision_layer = 0
	collision_mask = 1 << (PLAYER_LAYER - 1)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = pickup_radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered.emit()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_exited.emit()
