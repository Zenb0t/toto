class_name Slash
extends RefCounted
## One melee swing: everything within reach and inside the arc gets hit once.

var origin: Vector2
var direction: Vector2
var reach: float
var arc_degrees: float
var damage: int
var color: Color


func _init(from: Vector2, toward: Vector2, slash_reach: float, arc: float, slash_damage: int, slash_color: Color) -> void:
	origin = from
	direction = toward.normalized()
	reach = slash_reach
	arc_degrees = arc
	damage = slash_damage
	color = slash_color
