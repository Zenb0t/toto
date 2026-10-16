class_name Shot
extends RefCounted
## One projectile a weapon fires: where it starts, where it goes, and how it behaves.

var origin: Vector2
var direction: Vector2
var speed: float
var damage: int
var travel_range: float


func _init(from: Vector2, toward: Vector2, shot_speed: float, shot_damage: int, shot_range: float) -> void:
	origin = from
	direction = toward.normalized()
	speed = shot_speed
	damage = shot_damage
	travel_range = shot_range


## How long the shot flies before fading out.
func lifetime() -> float:
	return travel_range / speed
