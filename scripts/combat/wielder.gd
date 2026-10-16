class_name Wielder
extends RefCounted
## Holds a weapon and runs its timing: the cooldown between attacks and the wind-up before each one.
## With a target, the aim follows it during the wind-up (the player's auto-aim); without one, the aim
## stays where it was when the attack started (so an enemy's telegraphed attack can be dodged).

var weapon: Weapon
var _cooldown: Cooldown
var _direction := Vector2.ZERO
var _aim_distance := 0.0
var _target: Node2D
var _windup_left := 0.0
var _winding_up := false


func _init(held: Weapon) -> void:
	equip(held)


func equip(held: Weapon) -> void:
	weapon = held
	_cooldown = Cooldown.new(held.cooldown)


## Starts an attack unless the weapon is still cooling down. Returns whether it started.
## aim_distance is how far away to aim (weapons that target a spot use it).
func start(direction: Vector2, aim_distance: float, target: Node2D = null) -> bool:
	if direction == Vector2.ZERO or not _cooldown.try_trigger():
		return false
	_direction = direction.normalized()
	_aim_distance = aim_distance
	_target = target
	_windup_left = weapon.windup
	_winding_up = true
	return true


## Moves time on. Returns the attacks released during this step, from origin: empty while waiting.
func advance(delta: float, origin: Vector2) -> Array:
	_cooldown.tick(delta)
	if not _winding_up:
		return []
	if is_instance_valid(_target):
		_direction = origin.direction_to(_target.global_position)
		_aim_distance = origin.distance_to(_target.global_position)
	_windup_left -= delta
	if _windup_left > 0.0:
		return []
	_winding_up = false
	_target = null
	return weapon.attacks(origin, _direction, _aim_distance)


## Cancels an attack being wound up (being yanked off your feet does that). The cooldown stays spent.
func interrupt() -> void:
	_winding_up = false
	_target = null


func is_winding_up() -> bool:
	return _winding_up


func aim_direction() -> Vector2:
	return _direction


func aim_distance() -> float:
	return _aim_distance


## 1.0 = just used, 0.0 = ready.
func cooldown_ratio() -> float:
	return _cooldown.remaining_ratio()
