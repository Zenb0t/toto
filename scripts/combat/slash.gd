class_name Slash
extends RefCounted
## One melee swing. The blade sweeps from one edge of the arc to the other over sweep_seconds,
## hitting each foe within reach once as it passes.

var origin: Vector2
var direction: Vector2
var reach: float
var arc_degrees: float
var damage: int
var color: Color
var sweep_seconds := 0.0
## An enemy's swing hurts the player; the player's hurts enemies.
var hurts_player := false


func _init(from: Vector2, toward: Vector2, slash_reach: float, arc: float, slash_damage: int, slash_color: Color) -> void:
	origin = from
	direction = toward.normalized()
	reach = slash_reach
	arc_degrees = arc
	damage = slash_damage
	color = slash_color
