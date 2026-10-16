class_name PoisonCloud
extends Node2D
## A lingering cloud of poison (Dungeon Crawl's Mephitic Cloud): every foe inside it takes damage at
## intervals until it dissipates. The player's clouds hurt enemies; enemies' clouds hurt the player.

const TICK_SECONDS := 0.6
const COLOR := Color(0.55, 0.85, 0.3)
const PUFFS := 7

var _radius: float
var _damage: int
var _seconds: float
var _hurts_player: bool
var _elapsed := 0.0
var _until_tick := 0.0


func _init(radius: float, damage: int, seconds: float, hurts_player: bool) -> void:
	_radius = radius
	_damage = damage
	_seconds = seconds
	_hurts_player = hurts_player


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_until_tick -= delta
	if _until_tick <= 0.0:
		_until_tick = TICK_SECONDS
		_hurt_foes_inside()
	if _elapsed >= _seconds:
		queue_free()
	queue_redraw()


func _hurt_foes_inside() -> void:
	var foes := Player.GROUP if _hurts_player else Enemy.GROUP
	for foe: Node2D in get_tree().get_nodes_in_group(foes):
		if HitShapes.in_circle(global_position, _radius + foe.body_radius(), foe.global_position):
			foe.take_damage(_damage)


## Puffs that drift around the middle and thin out as the cloud dissipates.
func _draw() -> void:
	var left := clampf(1.0 - _elapsed / _seconds, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius, Color(COLOR, 0.18 * left))
	for i in PUFFS:
		var angle := TAU * i / PUFFS + _elapsed * 0.6
		var center := Vector2.from_angle(angle) * _radius * (0.45 + 0.1 * sin(_elapsed * 2.0 + i))
		draw_circle(center, _radius * 0.42, Color(COLOR, 0.16 * left))
