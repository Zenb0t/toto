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
## A lobbed shot arcs over walls and enemies and only bursts where it lands (at the end of its range).
var lobbed := false
## Enemies' shots hurt the player; the player's hurt enemies. (A blast hurts everyone either way.)
var hurts_player := false
## Who or what let it out, as a death message would name it ("an orc wizard", "your own Fireball").
var source := ""
## A piercing shot passes through whoever it hits (hitting each once) and only stops at walls.
var pierces := false
## How many times the shot bounces off walls before it stops.
var bounces := 0
## Above zero, where the shot ends a poison cloud lingers for this long (see PoisonCloud).
var cloud_seconds := 0.0
var cloud_radius := 0.0
## A pulling shot drags the first foe it hits back to where it was fired from.
var pulls := false
## Seconds after the attack before this shot sets off, from wherever its attacker stands by then (a flurry).
var delay := 0.0
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


func leaves_cloud() -> bool:
	return cloud_seconds > 0.0
