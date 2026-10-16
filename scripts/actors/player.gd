class_name Player
extends CharacterBody2D
## The hero. Contains no input code: whoever controls it calls move(), attack() and use_utility().
## What those do comes from the equipped Weapon and Utility.

## The Shots and Slashes of one attack, for the world to carry out.
signal attack_fired(attacks: Array)
signal health_changed(current: int, maximum: int)
signal died

const DEFAULT_MOVE_SPEED := 140.0
const MAX_HEALTH := 10
const RADIUS := 12.0
const BODY_COLOR := Color(0.35, 0.75, 1.0)
const AIM_PREVIEW_COLOR := Color(1, 1, 1, 0.3)
const AIM_PREVIEW_WIDTH := 4.0
const AIM_PREVIEW_ARC_POINTS := 24
const WINDUP_COLOR := Color(1.0, 0.85, 0.4, 0.8)

var health := Health.new(MAX_HEALTH)
var facing := Vector2.RIGHT
var move_speed := DEFAULT_MOVE_SPEED
var weapon: Weapon = Wand.new()
var utility := Utility.new()

var _move_input := Vector2.ZERO
var _attack_cooldown := Cooldown.new(weapon.cooldown)
var _utility_cooldown := Cooldown.new(utility.cooldown)
var _dash_direction := Vector2.ZERO
var _dash_time_left := 0.0
var _aim_direction := Vector2.ZERO
var _aim_shape: AimShape
var _aim_strength := 1.0
var _windup_direction := Vector2.ZERO
var _windup_target: Node2D
var _windup_strength := 1.0
var _windup_time_left := 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	health.changed.connect(func(current: int, maximum: int) -> void: health_changed.emit(current, maximum))
	health.died.connect(_on_died)


func equip_weapon(new_weapon: Weapon) -> void:
	weapon = new_weapon
	_attack_cooldown = Cooldown.new(new_weapon.cooldown)


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
	if direction == Vector2.ZERO or not _attack_cooldown.try_trigger():
		return
	facing = direction.normalized()
	_windup_direction = facing
	_windup_target = target
	_windup_strength = strength
	_windup_time_left = weapon.windup
	if _windup_time_left <= 0.0:
		_fire()


func use_utility(direction: Vector2) -> void:
	if direction == Vector2.ZERO or not _utility_cooldown.try_trigger():
		return
	facing = direction.normalized()
	_dash_direction = facing
	_dash_time_left = utility.dash_duration


## Shows where an ability will go, in the ability's own shape. Pass a zero direction to hide it.
## strength (0..1) places the landing spot of shapes that aim at a distance.
func preview_aim(direction: Vector2, shape: AimShape = null, strength := 1.0) -> void:
	_aim_direction = direction.normalized()
	_aim_shape = shape
	_aim_strength = strength
	queue_redraw()


func attack_cooldown_ratio() -> float:
	return _attack_cooldown.remaining_ratio()


func utility_cooldown_ratio() -> float:
	return _utility_cooldown.remaining_ratio()


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func _physics_process(delta: float) -> void:
	_attack_cooldown.tick(delta)
	_utility_cooldown.tick(delta)
	_advance_windup(delta)
	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity = _dash_direction * utility.dash_speed
	else:
		velocity = _move_input * move_speed
		if _move_input.length() > 0.1:
			facing = _move_input.normalized()
	move_and_slide()
	queue_redraw()


func _advance_windup(delta: float) -> void:
	if _windup_time_left <= 0.0:
		return
	if is_instance_valid(_windup_target):
		_windup_direction = global_position.direction_to(_windup_target.global_position)
		facing = _windup_direction
	_windup_time_left -= delta
	if _windup_time_left <= 0.0:
		_fire()


func _fire() -> void:
	var aim_distance := _windup_strength * weapon.aim_range()
	if is_instance_valid(_windup_target):
		aim_distance = global_position.distance_to(_windup_target.global_position)
	_windup_target = null
	_windup_time_left = 0.0
	attack_fired.emit(weapon.attacks(global_position, _windup_direction, aim_distance))


func _draw() -> void:
	if _windup_time_left > 0.0:
		draw_line(Vector2.ZERO, _windup_direction * (RADIUS + 28.0), WINDUP_COLOR, RADIUS * 1.4)
	if _aim_direction != Vector2.ZERO and _aim_shape != null:
		_draw_aim_preview(_aim_direction, _aim_shape)
	draw_circle(Vector2.ZERO, RADIUS, BODY_COLOR)
	draw_line(Vector2.ZERO, facing * (RADIUS + 6.0), Color.WHITE, 3.0)


func _draw_aim_preview(direction: Vector2, shape: AimShape) -> void:
	match shape.kind:
		AimShape.Kind.LINE:
			var end := direction * shape.length
			draw_line(Vector2.ZERO, end, AIM_PREVIEW_COLOR, AIM_PREVIEW_WIDTH * 3.0)
			if shape.end_radius > 0.0:
				draw_circle(end, shape.end_radius, AIM_PREVIEW_COLOR)
		AimShape.Kind.CONE:
			var wedge := ArcPolygon.wedge(direction, shape.length, shape.spread_degrees, AIM_PREVIEW_ARC_POINTS)
			draw_colored_polygon(wedge, AIM_PREVIEW_COLOR)
		AimShape.Kind.LOB:
			var landing := direction * shape.length * _aim_strength
			draw_line(Vector2.ZERO, landing, AIM_PREVIEW_COLOR, AIM_PREVIEW_WIDTH)
			draw_circle(landing, shape.end_radius, AIM_PREVIEW_COLOR)
		AimShape.Kind.FAN:
			for angle in Spread.angles_degrees(shape.count, shape.spread_degrees):
				var line_end := direction.rotated(deg_to_rad(angle)) * shape.length
				draw_line(Vector2.ZERO, line_end, AIM_PREVIEW_COLOR, AIM_PREVIEW_WIDTH)


func _on_died() -> void:
	set_physics_process(false)
	hide()
	died.emit()
