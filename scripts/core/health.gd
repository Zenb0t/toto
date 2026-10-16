class_name Health
extends RefCounted
## Hit points for any actor. Knows nothing about nodes or rendering.

signal changed(current: int, maximum: int)
signal died

var current: int
var maximum: int


func _init(max_health: int) -> void:
	assert(max_health > 0, "max_health must be positive")
	maximum = max_health
	current = max_health


func is_dead() -> bool:
	return current == 0


func take_damage(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current = maxi(current - amount, 0)
	changed.emit(current, maximum)
	if is_dead():
		died.emit()


func heal(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current = mini(current + amount, maximum)
	changed.emit(current, maximum)


## Health that has already taken some damage: current of maximum (clamped to 1..maximum).
static func restored(max_health: int, current_health: int) -> Health:
	var health := Health.new(max_health)
	health.current = clampi(current_health, 1, max_health)
	return health
