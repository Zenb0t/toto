class_name Nova
extends RefCounted
## A burst centred on its user: hurts every foe within radius once, and slows them for a while.

var origin := Vector2.ZERO
var radius: float
var damage: int
## Foes hit act at this fraction of their speed (1 = not slowed)...
var slow_multiplier: float
## ...for this long.
var slow_seconds: float
var color: Color
## An enemy's burst would hurt the player; the player's hurts enemies.
var hurts_player := false


func _init(burst_radius: float, burst_damage: int, slowed_to: float, slow_time: float, burst_color: Color) -> void:
	radius = burst_radius
	damage = burst_damage
	slow_multiplier = slowed_to
	slow_seconds = slow_time
	color = burst_color
