class_name SlashEffect
extends Node2D
## Performs a Slash: the blade sweeps across the arc and hits each foe within reach once, as it passes:
## enemies for the player's swings, the player for an enemy's. With an anchor (the swinger), the swing
## follows it while sweeping.

const FADE_SECONDS := 0.12
const ARC_POINTS := 24
## Angular width of the blade itself, so enemies right at a frame boundary aren't skipped.
const BLADE_DEGREES := 12.0
const TRAIL_ALPHA := 0.35
const BLADE_WIDTH := 5.0

var _slash: Slash
var _anchor: Node2D
var _elapsed := 0.0
var _swept_to: float  # Degrees relative to the aim, from -arc/2 to +arc/2.
var _already_hit := {}  # Foe instance id -> true


func _init(slash: Slash, anchor: Node2D = null) -> void:
	_slash = slash
	_anchor = anchor
	_swept_to = -slash.arc_degrees / 2.0
	position = slash.origin


func _physics_process(delta: float) -> void:
	if is_instance_valid(_anchor):
		position = _anchor.global_position
	_elapsed += delta
	var blade := _blade_angle()
	_hit_between(_swept_to, blade)
	_swept_to = blade
	if _elapsed >= _slash.sweep_seconds + FADE_SECONDS:
		queue_free()
	queue_redraw()


func _sweep_progress() -> float:
	return 1.0 if _slash.sweep_seconds <= 0.0 else clampf(_elapsed / _slash.sweep_seconds, 0.0, 1.0)


func _blade_angle() -> float:
	return lerpf(-_slash.arc_degrees / 2.0, _slash.arc_degrees / 2.0, _sweep_progress())


## Hits foes inside the slice of the arc the blade crossed since the last frame.
func _hit_between(from_degrees: float, to_degrees: float) -> void:
	var slice_direction := _slash.direction.rotated(deg_to_rad((from_degrees + to_degrees) / 2.0))
	var slice_width := to_degrees - from_degrees + BLADE_DEGREES
	var foes := Player.GROUP if _slash.hurts_player else Enemy.GROUP
	for foe: Node2D in get_tree().get_nodes_in_group(foes):
		if _already_hit.has(foe.get_instance_id()):
			continue
		if HitShapes.in_arc(global_position, slice_direction, _slash.reach + foe.body_radius(), slice_width, foe.global_position):
			_already_hit[foe.get_instance_id()] = true
			foe.take_damage(_slash.damage)


func _draw() -> void:
	var fade := 1.0
	if _elapsed > _slash.sweep_seconds:
		fade = clampf(1.0 - (_elapsed - _slash.sweep_seconds) / FADE_SECONDS, 0.0, 1.0)
	var start := -_slash.arc_degrees / 2.0
	var swept := _swept_to - start
	if swept > 0.0:
		var trail_direction := _slash.direction.rotated(deg_to_rad(start + swept / 2.0))
		draw_colored_polygon(
			ArcPolygon.wedge(trail_direction, _slash.reach, swept, ARC_POINTS), Color(_slash.color, TRAIL_ALPHA * fade))
	var blade_end := _slash.direction.rotated(deg_to_rad(_swept_to)) * _slash.reach
	draw_line(Vector2.ZERO, blade_end, Color(_slash.color, fade), BLADE_WIDTH, true)
