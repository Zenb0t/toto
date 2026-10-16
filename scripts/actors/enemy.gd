class_name Enemy
extends CharacterBody2D
## An armed enemy: idles until told to chase, then fights its target with its weapon the way the weapon
## wants (see EnemyTactics). Before each attack it stops and shows where the attack will go, and its aim
## stays put, so the player can see it coming and get out of the way.
## With navigation, an enemy that can't see its target walks around walls to find it, and only attacks
## through them with a weapon that lobs.

signal defeated(enemy: Enemy)
## The Shots and Slashes of one attack, for the world to carry out. They hurt the player.
signal attack_fired(attacks: Array)

## Every enemy is in this group, so area attacks can find them.
const GROUP := &"enemies"
const DEFAULT_MOVE_SPEED := 80.0
const DEFAULT_MAX_HEALTH := 3
## Enemies attack this many times slower than the player with the same weapon...
const DEFAULT_COOLDOWN_MULTIPLIER := 2.0
## ...and wind up for this much longer, showing where the attack will go.
const DEFAULT_TELEGRAPH_SECONDS := 0.4
const RADIUS := 11.0
const BODY_COLOR := Color(0.9, 0.35, 0.3)
const TELEGRAPH_COLOR := Color(1.0, 0.3, 0.25, 0.3)
## How far from its ideal distance an enemy is still happy, relative to that distance.
const SLACK_SHARE := 0.25
## How often a path around walls is worked out again, as the target moves.
const REPATH_SECONDS := 0.4
## How close to a path point counts as reaching it, in pixels.
const WAYPOINT_REACHED := 6.0

var health := Health.new(DEFAULT_MAX_HEALTH)
var move_speed := DEFAULT_MOVE_SPEED
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


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group(GROUP)
	# Neighbours circle in different directions, so a group spreads out instead of moving as a blob.
	_strafe_sign = 1.0 if get_instance_id() % 2 == 0 else -1.0
	health.changed.connect(func(_current: int, _maximum: int) -> void: queue_redraw())
	health.died.connect(_on_died)


## Must be called before the enemy is added to the tree.
func set_max_health(max_health: int) -> void:
	health = Health.new(max_health)


func arm(new_weapon: Weapon) -> void:
	_wielder.equip(new_weapon)
	queue_redraw()


func chase(target: Node2D) -> void:
	_target = target


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func _physics_process(delta: float) -> void:
	_release(_wielder.advance(delta, global_position))
	_repath_left -= delta
	velocity = Vector2.ZERO
	if is_instance_valid(_target) and not _wielder.is_winding_up():
		if _sees(_target.global_position):
			_path.clear()
			_fight(_target.global_position - global_position)
		else:
			_go_around_to(_target.global_position)
	move_and_slide()
	queue_redraw()


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
	attack_fired.emit(attacks)


func _draw() -> void:
	if _wielder.is_winding_up():
		AimPreview.draw(self, weapon.aim_shape(), _wielder.aim_direction(), _wielder.aim_distance(), TELEGRAPH_COLOR)
	draw_circle(Vector2.ZERO, RADIUS, BODY_COLOR)
	draw_circle(Vector2.ZERO, RADIUS * 0.45, weapon.color)
	var health_ratio := float(health.current) / health.maximum
	draw_rect(Rect2(-RADIUS, -RADIUS - 8.0, RADIUS * 2.0 * health_ratio, 3.0), Color.WHITE)


func _on_died() -> void:
	defeated.emit(self)
	queue_free()
