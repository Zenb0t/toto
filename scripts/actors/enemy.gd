class_name Enemy
extends CharacterBody2D
## An armed monster (see Bestiary): idles until told to chase, then fights its target with its weapon the way the weapon
## wants (see EnemyTactics). Before each attack it stops and shows where the attack will go, and its aim
## stays put, so the player can see it coming and get out of the way.
## With navigation, an enemy that can't see its target walks around walls to find it, and only attacks
## through them with a weapon that lobs.

signal defeated(enemy: Enemy)
## The Shots and Slashes of one attack, for the world to carry out. They hurt the player.
signal attack_fired(attacks: Array)

## Every enemy is in this group, so area attacks can find them.
const GROUP := &"enemies"
const DEFAULT_MOVE_SPEED := 85.0
const DEFAULT_MAX_HEALTH := 3
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

var _wielder := Wielder.new(Sword.new())
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
	velocity = Vector2.ZERO
	if is_instance_valid(_target) and not _wielder.is_winding_up():
		if _sees(_target.global_position):
			_path.clear()
			_fight(_target.global_position - global_position)
		else:
			_go_around_to(_target.global_position)
	_update_facing()
	velocity *= pace * ground_speed
	move_and_slide()
	queue_redraw()


func _update_facing() -> void:
	if _wielder.is_winding_up():
		facing = _wielder.aim_direction()
	elif is_instance_valid(_target) and _path.is_empty():
		facing = global_position.direction_to(_target.global_position)
	elif velocity != Vector2.ZERO:
		facing = velocity.normalized()


func _fight(to_target: Vector2) -> void:
	var ideal := weapon.ideal_distance()
	velocity = EnemyTactics.move_direction(to_target, ideal, ideal * SLACK_SHARE, _strafe_sign) * move_speed
	_attack_if_in_reach(to_target)


func _attack_if_in_reach(to_target: Vector2) -> void:
	if EnemyTactics.can_attack(to_target.length(), Player.RADIUS, weapon.aim_range()):
		_wielder.start(to_target, to_target.length())


func _sees(point: Vector2) -> bool:
	return navigation == null or navigation.can_see(global_position, point)


## Follows a path around whatever blocks the view. A lobbing weapon still attacks over it.
func _go_around_to(goal: Vector2) -> void:
	if not weapon.needs_line_of_sight():
		_attack_if_in_reach(goal - global_position)
	if _repath_left <= 0.0:
		_path = navigation.path(global_position, goal)
		_repath_left = REPATH_SECONDS
	while not _path.is_empty() and global_position.distance_to(_path[0]) < WAYPOINT_REACHED:
		_path.remove_at(0)
	if not _path.is_empty():
		velocity = global_position.direction_to(_path[0]) * move_speed


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
	defeated.emit(self)
	queue_free()
