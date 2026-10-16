class_name Player
extends CharacterBody2D
## Twin-stick style hero: WASD to move, mouse to aim, hold left click to shoot.

signal shot_fired(origin: Vector2, direction: Vector2)
signal health_changed(current: int, maximum: int)
signal died

const SPEED := 220.0
const MAX_HEALTH := 10
const FIRE_INTERVAL := 0.25
const RADIUS := 12.0
const BODY_COLOR := Color(0.35, 0.75, 1.0)

var health := Health.new(MAX_HEALTH)
var _fire_cooldown := Cooldown.new(FIRE_INTERVAL)
var _aim_direction := Vector2.RIGHT


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	health.changed.connect(func(current: int, maximum: int) -> void: health_changed.emit(current, maximum))
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_fire_cooldown.tick(delta)
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED
	move_and_slide()
	_aim_direction = _direction_to_mouse()
	if Input.is_action_pressed("shoot") and _fire_cooldown.try_trigger():
		shot_fired.emit(global_position, _aim_direction)
	queue_redraw()


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, BODY_COLOR)
	draw_line(Vector2.ZERO, _aim_direction * (RADIUS + 8.0), Color.WHITE, 3.0)


func _direction_to_mouse() -> Vector2:
	var to_mouse := get_global_mouse_position() - global_position
	return to_mouse.normalized() if to_mouse.length() > 1.0 else _aim_direction


func _on_died() -> void:
	set_physics_process(false)
	hide()
	died.emit()
