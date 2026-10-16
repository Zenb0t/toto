class_name Enemy
extends CharacterBody2D
## Simple chaser: idles until told to chase, then walks straight at its target and hurts it on contact.

signal defeated(enemy: Enemy)

## Every enemy is in this group, so area attacks can find them.
const GROUP := &"enemies"
const DEFAULT_MOVE_SPEED := 80.0
const DEFAULT_MAX_HEALTH := 3
const CONTACT_DAMAGE := 1
const CONTACT_INTERVAL := 0.8
const RADIUS := 11.0
const BODY_COLOR := Color(0.9, 0.35, 0.3)

var health := Health.new(DEFAULT_MAX_HEALTH)
var move_speed := DEFAULT_MOVE_SPEED
var _target: Node2D
var _contact_cooldown := Cooldown.new(CONTACT_INTERVAL)


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group(GROUP)
	health.changed.connect(func(_current: int, _maximum: int) -> void: queue_redraw())
	health.died.connect(_on_died)


## Must be called before the enemy is added to the tree.
func set_max_health(max_health: int) -> void:
	health = Health.new(max_health)


func chase(target: Node2D) -> void:
	_target = target


func take_damage(amount: int) -> void:
	health.take_damage(amount)


func _physics_process(delta: float) -> void:
	_contact_cooldown.tick(delta)
	if is_instance_valid(_target):
		velocity = global_position.direction_to(_target.global_position) * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_hurt_target_on_contact()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, BODY_COLOR)
	var health_ratio := float(health.current) / health.maximum
	draw_rect(Rect2(-RADIUS, -RADIUS - 8.0, RADIUS * 2.0 * health_ratio, 3.0), Color.WHITE)


func _hurt_target_on_contact() -> void:
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider()
		if collider is Player and _contact_cooldown.try_trigger():
			collider.take_damage(CONTACT_DAMAGE)


func _on_died() -> void:
	defeated.emit(self)
	queue_free()
