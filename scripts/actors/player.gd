class_name Player
extends CharacterBody2D
## The hero. Contains no input code: whoever controls it calls move(), attack() and dash().

signal attack_fired(origin: Vector2, direction: Vector2)
signal health_changed(current: int, maximum: int)
signal died

const SPEED := 140.0
const MAX_HEALTH := 10
const RADIUS := 12.0
const BODY_COLOR := Color(0.35, 0.75, 1.0)
const AIM_PREVIEW_COLOR := Color(1, 1, 1, 0.3)
const ATTACK_INTERVAL := 0.8
## Delay between releasing the button and the shot leaving, so attacks feel deliberate.
const ATTACK_WINDUP := 0.3
const WINDUP_COLOR := Color(1.0, 0.85, 0.4, 0.8)
# Temporary utility until equipment exists.
const DASH_SPEED := 650.0
const DASH_DURATION := 0.18
const DASH_DISTANCE := DASH_SPEED * DASH_DURATION
const DASH_INTERVAL := 1.5

var health := Health.new(MAX_HEALTH)
var facing := Vector2.RIGHT

var _move_input := Vector2.ZERO
var _attack_cooldown := Cooldown.new(ATTACK_INTERVAL)
var _dash_cooldown := Cooldown.new(DASH_INTERVAL)
var _dash_direction := Vector2.ZERO
var _dash_time_left := 0.0
var _aim_preview := Vector2.ZERO
var _windup_direction := Vector2.ZERO
var _windup_target: Node2D
var _windup_time_left := 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	health.changed.connect(func(current: int, maximum: int) -> void: health_changed.emit(current, maximum))
	health.died.connect(_on_died)


## strength: 0..1 vector from a stick or keys.
func move(strength: Vector2) -> void:
	_move_input = strength.limit_length(1.0)


## Starts an attack. The shot leaves after a short wind-up; taps during the cooldown are ignored.
## With a target (auto-aim), the aim keeps tracking it during the wind-up so the delay doesn't cause misses.
func attack(direction: Vector2, target: Node2D = null) -> void:
	if direction == Vector2.ZERO or not _attack_cooldown.try_trigger():
		return
	facing = direction.normalized()
	_windup_direction = facing
	_windup_target = target
	_windup_time_left = ATTACK_WINDUP


func dash(direction: Vector2) -> void:
	if direction == Vector2.ZERO or not _dash_cooldown.try_trigger():
		return
	facing = direction.normalized()
	_dash_direction = facing
	_dash_time_left = DASH_DURATION


## Shows where an ability will go. Pass a zero vector to hide it.
func preview_aim(direction_with_length: Vector2) -> void:
	_aim_preview = direction_with_length
	queue_redraw()


func attack_cooldown_ratio() -> float:
	return _attack_cooldown.remaining_ratio()


func dash_cooldown_ratio() -> float:
	return _dash_cooldown.remaining_ratio()


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func _physics_process(delta: float) -> void:
	_attack_cooldown.tick(delta)
	_dash_cooldown.tick(delta)
	_advance_windup(delta)
	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity = _dash_direction * DASH_SPEED
	else:
		velocity = _move_input * SPEED
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
		_windup_target = null
		attack_fired.emit(_muzzle_position(), _windup_direction)


## Shots start just past the aim tick, in front of the body rather than inside it.
func _muzzle_position() -> Vector2:
	return global_position + _windup_direction * (RADIUS + 6.0)


func _draw() -> void:
	if _windup_time_left > 0.0:
		draw_line(Vector2.ZERO, _windup_direction * (RADIUS + 28.0), WINDUP_COLOR, RADIUS * 1.4)
	if _aim_preview != Vector2.ZERO:
		draw_line(Vector2.ZERO, _aim_preview, AIM_PREVIEW_COLOR, RADIUS * 1.2)
	draw_circle(Vector2.ZERO, RADIUS, BODY_COLOR)
	draw_line(Vector2.ZERO, facing * (RADIUS + 6.0), Color.WHITE, 3.0)


func _on_died() -> void:
	set_physics_process(false)
	hide()
	died.emit()
