class_name Player
extends CharacterBody2D
## The hero. Contains no input code: whoever controls it calls move(), attack() and use_utility().
## What those do comes from the equipped Weapon and Utility.

## The Shots and Slashes of one attack, for the world to carry out.
signal attack_fired(attacks: Array)
signal health_changed(current: int, maximum: int)
signal died

## The player is in this group, so area attacks (like the fireball's blast) can find them.
const GROUP := &"players"
const DEFAULT_MOVE_SPEED := 140.0
const MAX_HEALTH := 10
const RADIUS := 12.0
const BODY_COLOR := Color(0.35, 0.75, 1.0)
const AIM_PREVIEW_COLOR := Color(1, 1, 1, 0.3)
const WINDUP_COLOR := Color(1.0, 0.85, 0.4, 0.8)
const SHIELD_COLOR := Color(0.7, 0.6, 1.0, 0.8)
const SHIELD_RING_GAP := 6.0

var health := Health.new(MAX_HEALTH)
var facing := Vector2.RIGHT
var move_speed := DEFAULT_MOVE_SPEED
var weapon: Weapon:
	get:
		return _wielder.weapon
var utility: Utility = Dash.new()

var _wielder := Wielder.new(Wand.new())
var _move_input := Vector2.ZERO
var _utility_cooldown := Cooldown.new(utility.cooldown)
var _dash_direction := Vector2.ZERO
var _dash_speed := 0.0
var _dash_time_left := 0.0
var _shield_time_left := 0.0
var _aim_direction := Vector2.ZERO
var _aim_shape: AimShape
var _aim_strength := 1.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group(GROUP)
	health.changed.connect(func(current: int, maximum: int) -> void: health_changed.emit(current, maximum))
	health.died.connect(_on_died)


func equip_weapon(new_weapon: Weapon) -> void:
	_wielder.equip(new_weapon)


func equip_utility(new_utility: Utility) -> void:
	utility = new_utility
	_utility_cooldown = Cooldown.new(new_utility.cooldown)


## strength: 0..1 vector from a stick or keys.
func move(strength: Vector2) -> void:
	_move_input = strength.limit_length(1.0)


## Starts an attack. It happens after the weapon's wind-up; taps during the cooldown are ignored.
## With a target (auto-aim), the aim keeps tracking it during the wind-up so the delay doesn't cause misses,
## and weapons that aim at a spot land on it. Without one, strength (0..1) picks how far away to aim.
func attack(direction: Vector2, target: Node2D = null, strength := 1.0) -> void:
	if not _wielder.start(direction, weapon.aim_distance(strength), target):
		return
	facing = direction.normalized()
	if weapon.windup <= 0.0:
		_release(_wielder.advance(0.0, global_position))


## Uses the utility toward direction (dash) or on the spot (shield, heal). Ignored during its cooldown.
func use_utility(direction: Vector2) -> void:
	if direction == Vector2.ZERO or not _utility_cooldown.try_trigger():
		return
	facing = direction.normalized()
	_apply(utility.activate(facing))


## Shows where an ability will go, in the ability's own shape. Pass a zero direction or no shape to hide it.
## strength (0..1) places the landing spot of shapes that aim at a distance, as the weapon will when it fires.
func preview_aim(direction: Vector2, shape: AimShape = null, strength := 1.0) -> void:
	_aim_direction = direction.normalized()
	_aim_shape = shape
	_aim_strength = strength
	queue_redraw()


func attack_cooldown_ratio() -> float:
	return _wielder.cooldown_ratio()


func utility_cooldown_ratio() -> float:
	return _utility_cooldown.remaining_ratio()


func is_shielded() -> bool:
	return _shield_time_left > 0.0


func take_damage(amount: int) -> void:
	if not is_shielded():
		health.take_damage(amount)


func _physics_process(delta: float) -> void:
	_utility_cooldown.tick(delta)
	_shield_time_left = maxf(_shield_time_left - delta, 0.0)
	_release(_wielder.advance(delta, global_position))
	if _wielder.is_winding_up():
		facing = _wielder.aim_direction()
	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity = _dash_direction * _dash_speed
	else:
		velocity = _move_input * move_speed
		if _move_input.length() > 0.1:
			facing = _move_input.normalized()
	move_and_slide()
	queue_redraw()


func _release(attacks: Array) -> void:
	if not attacks.is_empty():
		attack_fired.emit(attacks)


func _apply(effect: UtilityEffect) -> void:
	if effect.dash_seconds > 0.0:
		_dash_direction = effect.dash_direction
		_dash_speed = effect.dash_speed
		_dash_time_left = effect.dash_seconds
	_shield_time_left = maxf(_shield_time_left, effect.shield_seconds)
	health.heal(effect.heal_amount)


func _draw() -> void:
	if _wielder.is_winding_up():
		draw_line(Vector2.ZERO, _wielder.aim_direction() * (RADIUS + 28.0), WINDUP_COLOR, RADIUS * 1.4)
	if _aim_direction != Vector2.ZERO and _aim_shape != null:
		AimPreview.draw(self, _aim_shape, _aim_direction, weapon.aim_distance(_aim_strength), AIM_PREVIEW_COLOR)
	draw_circle(Vector2.ZERO, RADIUS, BODY_COLOR)
	draw_line(Vector2.ZERO, facing * (RADIUS + 6.0), Color.WHITE, 3.0)
	if is_shielded():
		draw_arc(Vector2.ZERO, RADIUS + SHIELD_RING_GAP, 0.0, TAU, 32, SHIELD_COLOR, 3.0, true)


func _on_died() -> void:
	set_physics_process(false)
	hide()
	died.emit()
