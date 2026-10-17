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
var _first_tick_delay: float
var _hurts_player: bool
## Who threw it (see Shot.source).
var source := ""
var _elapsed := 0.0
var _ticks_dealt := 0
var _ticks_total: int


func _init(radius: float, damage: int, seconds: float, hurts_player: bool, first_tick_delay := 0.0) -> void:
	_radius = radius
	_damage = damage
	_seconds = seconds
	_hurts_player = hurts_player
	_first_tick_delay = first_tick_delay
	# Ticks at first_tick_delay, then every TICK_SECONDS up to and including the moment the cloud ends, each once.
	_ticks_total = maxi(0, floori((seconds - first_tick_delay) / TICK_SECONDS + 0.001) + 1)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _ticks_dealt < _ticks_total and _elapsed >= _first_tick_delay + _ticks_dealt * TICK_SECONDS:
		_ticks_dealt += 1
		_hurt_foes_inside()
	if _elapsed >= _seconds:
		queue_free()
	queue_redraw()


func _hurt_foes_inside() -> void:
	var foes := Player.GROUP if _hurts_player else Enemy.GROUP
	for foe: Node2D in get_tree().get_nodes_in_group(foes):
		if HitShapes.in_circle(global_position, _radius + foe.body_radius(), foe.global_position):
			foe.take_damage(_damage, source)


## Puffs that drift around the middle and thin out as the cloud dissipates.
func _draw() -> void:
	var left := clampf(1.0 - _elapsed / _seconds, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius, Color(COLOR, 0.18 * left))
	for i in PUFFS:
		var angle := TAU * i / PUFFS + _elapsed * 0.6
		var center := Vector2.from_angle(angle) * _radius * (0.45 + 0.1 * sin(_elapsed * 2.0 + i))
		draw_circle(center, _radius * 0.42, Color(COLOR, 0.16 * left))
