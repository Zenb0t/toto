class_name Projectile
extends Area2D
## Flies a Shot straight until it hits something or runs out of range.
## A plain shot damages what it hits; an explosive shot bursts into an Explosion instead.
## A lobbed shot arcs over everything and bursts (or leaves its poison cloud) where it lands;
## a burning blast also leaves fire on the ground.
## A piercing shot passes through foes, hitting each once; a bouncing one glances off walls; a pulling one
## drags the first foe it hits back to where it was fired from; a chaining one jumps from the foe it hits to the
## next nearest one.
## On the 2D plane (the floor) it draws only its shadow; the 3D view draws the shot itself, height() up.

## How high a lob arcs, relative to how far it travels, and never higher than LOB_MAX_HEIGHT.
const LOB_HEIGHT_PER_DISTANCE := 0.35
const LOB_MAX_HEIGHT := 90.0
const SHADOW_COLOR := Color(0, 0, 0, 0.35)
## Physics layers (see the actor scenes): what a straight shot can bump into.
const WALL_LAYER_BIT := 1
const PLAYER_LAYER_BIT := 2
const ENEMY_LAYER_BIT := 4

var _shot: Shot
var _time_left := 0.0
var _spent := false
var _bounces_left := 0
var _chains_left := 0
var _last_step := Vector2.ZERO
var _already_hit := {}  # foe instance id -> true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Must be called before the projectile is added to the tree.
func launch(shot: Shot) -> void:
	_shot = shot
	position = shot.origin
	_time_left = shot.lifetime()
	_bounces_left = shot.bounces
	_chains_left = shot.chains
	if shot.lobbed:
		collision_mask = 0
	else:
		collision_mask = WALL_LAYER_BIT | (PLAYER_LAYER_BIT if shot.hurts_player else ENEMY_LAYER_BIT)


func shot() -> Shot:
	return _shot


## How high above its shadow the shot is, in pixels: zero for straight shots.
func height() -> float:
	return _lob_height() if _shot.lobbed else 0.0


func _physics_process(delta: float) -> void:
	_last_step = _shot.direction * _shot.speed * delta
	position += _last_step
	_time_left -= delta
	if _time_left <= 0.0:
		_finish()
	elif _shot.lobbed:
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _shot.size * 0.8, SHADOW_COLOR)


## Height above the ground along a parabola: zero at launch and landing, highest halfway.
func _lob_height() -> float:
	var lifetime := _shot.lifetime()
	var progress := 1.0 - _time_left / lifetime if lifetime > 0.0 else 1.0
	var peak := minf(_shot.travel_range * LOB_HEIGHT_PER_DISTANCE, LOB_MAX_HEIGHT)
	return 4.0 * peak * progress * (1.0 - progress)


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		_hit_wall()
		return
	if _spent or _already_hit.has(body.get_instance_id()):
		return
	_already_hit[body.get_instance_id()] = true
	if _shot.pulls and body.has_method("pull_toward"):
		body.pull_toward(_shot.origin)
	elif not _shot.explodes():
		body.take_damage(_shot.damage, _shot.source)
	if _chains_left > 0 and _chain_from(body):
		return
	if not _shot.pierces:
		_finish()


## Sends the shot on from the foe it just hit to the nearest foe in reach that it hasn't hit yet. Returns
## whether there was one.
func _chain_from(hit: Node2D) -> bool:
	var foes: Array[Node2D] = []
	var positions: Array[Vector2] = []
	for foe: Node2D in get_tree().get_nodes_in_group(Player.GROUP if _shot.hurts_player else Enemy.GROUP):
		if not _already_hit.has(foe.get_instance_id()):
			foes.append(foe)
			positions.append(foe.global_position)
	var next := AutoAim.nearest_index(hit.global_position, positions, _shot.chain_range)
	if next == AutoAim.NO_TARGET:
		return false
	_chains_left -= 1
	global_position = hit.global_position
	_shot.direction = global_position.direction_to(positions[next])
	_time_left = _shot.chain_range / _shot.speed
	return true


## Glances off the wall while it has bounces left, otherwise stops there.
func _hit_wall() -> void:
	if _bounces_left <= 0:
		_finish()
		return
	var query := PhysicsRayQueryParameters2D.create(
		global_position - _last_step * 2.0, global_position + _shot.direction * _shot.size * 2.0, WALL_LAYER_BIT)
	var contact := get_world_2d().direct_space_state.intersect_ray(query)
	var normal: Vector2 = contact.normal if not contact.is_empty() else -_shot.direction
	_bounces_left -= 1
	_shot.direction = _shot.direction.bounce(normal).normalized()
	if not contact.is_empty():
		global_position = contact.position + normal * (_shot.size + 2.0)


## A shot can touch a wall and an enemy in the same frame: only the first contact counts.
func _finish() -> void:
	if _spent:
		return
	_spent = true
	if _shot.explodes():
		var explosion := Explosion.new(_shot.blast_radius, _shot.damage, _shot.color, _shot.source)
		explosion.position = position
		get_parent().add_child.call_deferred(explosion)
	if _shot.leaves_burning_ground():
		var fire := BurningGround.new(_shot.blast_radius, _shot.burn_damage, _shot.burn_seconds)
		fire.source = _shot.source
		fire.position = position
		get_parent().add_child.call_deferred(fire)
	if _shot.leaves_cloud():
		var cloud := PoisonCloud.new(_shot.cloud_radius, _shot.damage, _shot.cloud_seconds, _shot.hurts_player, _shot.first_tick_delay)
		cloud.source = _shot.source
		cloud.position = position
		get_parent().add_child.call_deferred(cloud)
	queue_free()
