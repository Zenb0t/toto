class_name Shot
extends RefCounted
## One projectile a weapon fires: where it starts, where it goes, and how it behaves.

const DEFAULT_SIZE := 5.0
const DEFAULT_COLOR := Color(1.0, 0.9, 0.4)

var origin: Vector2
var direction: Vector2
var speed: float
var damage: int
var travel_range: float
## Above zero, the shot explodes on impact (or at the end of its range) and damages every enemy in the blast.
var blast_radius := 0.0
var size := DEFAULT_SIZE
var color := DEFAULT_COLOR


func _init(from: Vector2, toward: Vector2, shot_speed: float, shot_damage: int, shot_range: float) -> void:
	origin = from
	direction = toward.normalized()
	speed = shot_speed
	damage = shot_damage
	travel_range = shot_range


## How long the shot flies before fading out.
func lifetime() -> float:
	return travel_range / speed


func explodes() -> bool:
	return blast_radius > 0.0
