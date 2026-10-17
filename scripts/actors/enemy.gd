class_name Enemy
extends CharacterBody2D
## An armed monster (see Bestiary): idles until told to chase, then fights its target with its weapon the way the weapon
## wants (see EnemyTactics). What it is doing is decided by its EnemyBrain (idle, hunt, position, wind up,
## recover); this node carries it out. Before each attack it stops and shows where the attack will go, and its
## aim stays put, so the player can see it coming and get out of the way.
## In a Squad, it takes turns to attack with the rest of its room and spreads out around the target.
## With navigation, an enemy that can't see its target walks around walls to find it, and only attacks
## through them with a weapon that lobs.

signal defeated(enemy: Enemy)
## The Shots and Slashes of one attack, for the world to carry out. They hurt the player.
signal attack_fired(attacks: Array)

## Every enemy is in this group, so area attacks can find them.
const GROUP := &"enemies"
const DEFAULT_MOVE_SPEED := 85.0
const DEFAULT_MAX_HEALTH := 300
## Every kind of enemy is this much tougher than the Bestiary lists it.
const DEFAULT_HEALTH_MULTIPLIER := 1.1
## Enemies hold one charge of ammo and reload it this many times slower than the player does with the same
## weapon...
const DEFAULT_COOLDOWN_MULTIPLIER := 1.1
## ...and wind up for this much longer, showing where the attack will go.
const DEFAULT_TELEGRAPH_SECONDS := 0.3
const RADIUS := 11.0
const BODY_COLOR := Color(0.9, 0.35, 0.3)
## The ring on the floor under the enemy (the body itself is in the 3D view).
const BASE_FILL_ALPHA := 0.25
const BASE_RING_WIDTH := 2.5
const SLOWED_COLOR := Color(0.6, 0.9, 1.0, 0.9)
const SLOWED_RING_GAP := 5.0
const TELEGRAPH_COLOR := Color(1.0, 0.3, 0.25, 0.3)
## How far from its ideal distance an enemy is still happy, relative to that distance.
const SLACK_SHARE := 0.25
## How often a path around walls is worked out again, as the target moves.
const REPATH_SECONDS := 0.4
## How close to a path point counts as reaching it, in pixels.
const WAYPOINT_REACHED := 6.0
## How fast a pulled enemy is dragged, and how far from the pull's point it stops.
const PULL_SPEED := 900.0
const PULL_STOP_GAP := 8.0

var health := Health.new(DEFAULT_MAX_HEALTH)
## What kind of monster this is. Set with become() before it joins the world.
var monster: Monster = Bestiary.by_id("bandit")
## Where it looks: at its target while fighting, where it is going otherwise, and along its aim while
## winding up an attack.
var facing := Vector2.DOWN
var move_speed := DEFAULT_MOVE_SPEED
## The share of its speed the ground allows (see DungeonMap.ground_speed), set by whoever knows the map.
var ground_speed := 1.0
## Optional: without it, the enemy always heads straight for its target.
var navigation: Pathfinder
var weapon: Weapon:
	get:
		return _wielder.weapon
## Optional: the room's team. Without one, the enemy attacks whenever it can and doesn't flank.
var squad: Squad
## How much it aims ahead of a moving target (see EnemyTactics.lead).
var lead_share := EnemyTactics.DEFAULT_LEAD_SHARE
## How long it steps aside after each attack (see EnemyBrain).
var recover_seconds: float:
	get:
		return _brain.recover_seconds
	set(value):
		_brain.recover_seconds = value

var _wielder := Wielder.new(Sword.new())
var _brain := EnemyBrain.new()
var _target: Node2D
var _strafe_sign := 1.0
var _path := PackedVector2Array()
var _repath_left := 0.0
var _pull_velocity := Vector2.ZERO
var _pull_time_left := 0.0
var _slow_multiplier := 1.0
var _slow_time_left := 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group(GROUP)
	# Neighbours circle in different directions, so a group spreads out instead of moving as a blob.
	_strafe_sign = 1.0 if get_instance_id() % 2 == 0 else -1.0
	health.died.connect(_on_died)


## Must be called before the enemy is added to the tree.
func set_max_health(max_health: int) -> void:
	health = Health.new(max_health)


## Makes this enemy a monster of a kind: its size, health (times health_multiplier) and weapon.
## Must be called before the enemy is added to the tree.
func become(kind: Monster, health_multiplier := 1.0) -> void:
	monster = kind
	set_max_health(maxi(1, roundi(kind.max_health * health_multiplier)))
	var body := CircleShape2D.new()
	body.radius = body_radius()
	$CollisionShape2D.shape = body


## How far from its centre attacks hit it.
func body_radius() -> float:
	return RADIUS * monster.size


func arm(new_weapon: Weapon) -> void:
	_wielder.equip(new_weapon)
	queue_redraw()


func chase(target: Node2D) -> void:
	_target = target


func take_damage(amount: int, _source := "") -> void:
	health.take_damage(amount)


## Acts at a fraction of its speed (moving, winding up, recovering) for a while.
func slow(multiplier: float, seconds: float) -> void:
	_slow_multiplier = multiplier
	_slow_time_left = maxf(_slow_time_left, seconds)


func is_slowed() -> bool:
	return _slow_time_left > 0.0


## Drags the enemy to just short of a point (Lesser Beckoning), cancelling the attack it was winding up.
func pull_toward(point: Vector2) -> void:
	var stop := point + point.direction_to(global_position) * (body_radius() + Player.RADIUS + PULL_STOP_GAP)
	var travel := stop - global_position
	_pull_velocity = travel.normalized() * PULL_SPEED
	_pull_time_left = travel.length() / PULL_SPEED
	_wielder.interrupt()


func is_being_pulled() -> bool:
	return _pull_time_left > 0.0


func _physics_process(delta: float) -> void:
	_slow_time_left = maxf(_slow_time_left - delta, 0.0)
	if is_being_pulled():
		_pull_time_left -= delta
		velocity = _pull_velocity
		move_and_slide()
		return
	# A slowed enemy's own clock runs slow: it moves, winds up and recovers at a fraction of its pace.
	var pace := _slow_multiplier if is_slowed() else 1.0
	_release(_wielder.advance(delta * pace, global_position))
	_repath_left -= delta
	_report_to_squad()
	var before := _brain.state
	_brain.update(delta * pace, _senses())
	if _brain.state != before:
		_on_state_changed(before, _brain.state)
	velocity = _movement() * move_speed * pace * ground_speed
	_update_facing()
	move_and_slide()
	queue_redraw()


func _senses() -> EnemyBrain.Senses:
	var senses := EnemyBrain.Senses.new()
	senses.has_target = is_instance_valid(_target)
	senses.winding_up = _wielder.is_winding_up()
	if senses.has_target:
		senses.sees_target = _sees(_target.global_position)
		senses.has_turn = _brain.is_looking_for_a_turn() and _may_attack(senses.sees_target) and _claim_turn()
	return senses


func _may_attack(sees_target: bool) -> bool:
	if not _wielder.is_ready() or not (sees_target or not weapon.needs_line_of_sight()):
		return false
	return EnemyTactics.can_attack(global_position.distance_to(_target.global_position), Player.RADIUS, weapon.aim_range())


## Without a squad, every enemy attacks whenever it can.
func _claim_turn() -> bool:
	return squad == null or squad.request_turn(get_instance_id())


func _on_state_changed(from: EnemyBrain.State, to: EnemyBrain.State) -> void:
	if to == EnemyBrain.State.POSITION:
		_path.clear()
	elif to == EnemyBrain.State.WINDUP:
		_start_attack()
	if from == EnemyBrain.State.WINDUP:
		_end_turn()
		# Step aside the other way next time, so its moves are harder to read.
		_strafe_sign = -_strafe_sign


## Aims ahead of a moving target, where it will be when the attack arrives.
func _start_attack() -> void:
	var to_target := _target.global_position - global_position
	var seconds := weapon.windup + weapon.travel_seconds(to_target.length())
	var aim := EnemyTactics.lead(to_target, _target_velocity(), seconds, lead_share)
	_wielder.start(aim, aim.length())


func _end_turn() -> void:
	if squad != null:
		squad.end_turn(get_instance_id())


func _target_velocity() -> Vector2:
	return _target.velocity if _target is CharacterBody2D else Vector2.ZERO


func _report_to_squad() -> void:
	if squad != null and is_instance_valid(_target):
		squad.report_bearing(get_instance_id(), _bearing())


## The angle from the target to this enemy.
func _bearing() -> float:
	return (global_position - _target.global_position).angle()


## Unit-or-shorter direction to move in, for what the brain is doing.
func _movement() -> Vector2:
	match _brain.state:
		EnemyBrain.State.HUNT:
			return _path_direction(_target.global_position)
		EnemyBrain.State.POSITION:
			var to_target := _target.global_position - global_position
			var ideal := weapon.ideal_distance()
			return EnemyTactics.move_direction(to_target, ideal, ideal * SLACK_SHARE, _strafe_sign, _flank_gap())
		EnemyBrain.State.RECOVER:
			if not is_instance_valid(_target):
				return Vector2.ZERO
			return global_position.direction_to(_target.global_position).orthogonal() * _strafe_sign
	return Vector2.ZERO


## How far round the target this enemy's spot in the squad is (0 without a squad).
func _flank_gap() -> float:
	if squad == null:
		return 0.0
	return angle_difference(_bearing(), squad.flank_bearing(get_instance_id()))


func _update_facing() -> void:
	if _wielder.is_winding_up():
		facing = _wielder.aim_direction()
	elif is_instance_valid(_target) and _path.is_empty():
		facing = global_position.direction_to(_target.global_position)
	elif velocity != Vector2.ZERO:
		facing = velocity.normalized()


func _sees(point: Vector2) -> bool:
	return navigation == null or navigation.can_see(global_position, point)


## The way along a path around whatever blocks the view.
func _path_direction(goal: Vector2) -> Vector2:
	if navigation == null:
		return global_position.direction_to(goal)
	if _repath_left <= 0.0:
		_path = navigation.path(global_position, goal)
		_repath_left = REPATH_SECONDS
	while not _path.is_empty() and global_position.distance_to(_path[0]) < WAYPOINT_REACHED:
		_path.remove_at(0)
	return global_position.direction_to(_path[0]) if not _path.is_empty() else Vector2.ZERO


func _release(attacks: Array) -> void:
	if attacks.is_empty():
		return
	for attack: Variant in attacks:
		attack.hurts_player = true
		attack.damage += monster.damage_bonus
		attack.source = Monster.with_article(monster.display_name)
	attack_fired.emit(attacks)


func _draw() -> void:
	if _wielder.is_winding_up():
		AimPreview.draw(self, weapon.aim_shape(), _wielder.aim_direction(), _wielder.aim_distance(), TELEGRAPH_COLOR)
	draw_circle(Vector2.ZERO, body_radius(), Color(BODY_COLOR, BASE_FILL_ALPHA))
	draw_arc(Vector2.ZERO, body_radius(), 0.0, TAU, 32, BODY_COLOR, BASE_RING_WIDTH, true)
	if is_slowed():
		draw_arc(Vector2.ZERO, body_radius() + SLOWED_RING_GAP, 0.0, TAU, 32, SLOWED_COLOR, BASE_RING_WIDTH, true)


func _on_died() -> void:
	if squad != null:
		squad.leave(get_instance_id())
	defeated.emit(self)
	queue_free()
