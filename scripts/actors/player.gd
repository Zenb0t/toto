class_name Player
extends CharacterBody2D
## The hero. Contains no input code: whoever controls it calls move(), attack(), use_utility() and drink().
## What those do comes from the equipped Weapon, the two Utilities (a movement and a skill, see Utility.Slot) and the
## Potion drunk.

## The Shots and Slashes of one attack, for the world to carry out.
signal attack_fired(attacks: Array)
signal health_changed(current: int, maximum: int)
signal died
## A utility was used (its id), for whoever shows it.
signal utility_used(utility_id: String)

## The player is in this group, so area attacks (like the fireball's blast) can find them.
const GROUP := &"players"
const DEFAULT_MOVE_SPEED := 140.0
## How far the stick or keys must be pushed (0..1) to count as moving.
const MOVING_THRESHOLD := 0.1
const MAX_HEALTH := 1000
const RADIUS := 12.0
const BODY_COLOR := Color(0.35, 0.75, 1.0)
const AIM_PREVIEW_COLOR := Color(1, 1, 1, 0.3)
const WINDUP_COLOR := Color(1.0, 0.85, 0.4, 0.8)
const SHIELD_COLOR := Color(0.7, 0.6, 1.0, 0.8)
const SHIELD_RING_GAP := 6.0
## Rings on the floor while a potion works, in the potion's colour.
const HASTE_COLOR := Color(0.4, 0.9, 1.0, 0.8)
const MIGHT_COLOR := Color(1.0, 0.55, 0.2, 0.8)
const POTION_RING_GAP := 11.0
## The ring on the floor under the hero, in the hero's colour (the body itself is in the 3D view).
const BASE_FILL_ALPHA := 0.25
const BASE_RING_WIDTH := 2.5

var health := Health.new(MAX_HEALTH)
## When poison last ticked on the hero; clouds overlapping each other don't add up.
var poison := PoisonStatus.new()
## What last hurt the hero: what killed them, once they are dead.
var last_hurt_by := ""
var facing := Vector2.RIGHT
var move_speed := DEFAULT_MOVE_SPEED
## The share of its speed the ground allows (see DungeonMap.ground_speed), set by whoever knows the map.
var ground_speed := 1.0
## Whether the attack button is being held to charge the weapon (set by whoever reads the input): the hero is
## slower for as long as the weapon says (Weapon.charging_move_share).
var charging := false
var weapon: Weapon:
	get:
		return _wielder.weapon
## The movement (Dash, Blink): runs start with the Dash.
var movement: Utility = Dash.new()
## The skill (Shield, Frost Nova...), or null: runs start without one.
var skill: Utility = null
## Where a blink from one spot toward another ends (see BlinkLanding), set by whoever knows the map. Without a map
## it lands where it was aimed.
var blink_landing := func(_from: Vector2, to: Vector2) -> Vector2: return to

var _wielder := Wielder.new(Dagger.new())
var _move_input := Vector2.ZERO
var _cooldowns := {
	Utility.Slot.MOVEMENT: Cooldown.new(movement.cooldown),
	Utility.Slot.SKILL: Cooldown.new(0.0),
}
var _dash_direction := Vector2.ZERO
var _dash_speed := 0.0
var _dash_time_left := 0.0
var _shield_time_left := 0.0
var _haste_multiplier := 1.0
var _haste_time_left := 0.0
var _might_bonus := 0
var _might_time_left := 0.0
var _aim_direction := Vector2.ZERO
var _aim_shape: AimShape
var _aim_distance := 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group(GROUP)
	health.changed.connect(func(current: int, maximum: int) -> void: health_changed.emit(current, maximum))
	health.died.connect(_on_died)


func equip_weapon(new_weapon: Weapon) -> void:
	_wielder.equip(new_weapon)


## Puts the utility in its slot (see Utility.Slot), in place of the one held there, with a fresh cooldown.
func equip_utility(new_utility: Utility) -> void:
	if new_utility.slot == Utility.Slot.MOVEMENT:
		movement = new_utility
	else:
		skill = new_utility
	_cooldowns[new_utility.slot] = Cooldown.new(new_utility.cooldown)


## Leaves the skill button empty.
func unequip_skill() -> void:
	skill = null
	_cooldowns[Utility.Slot.SKILL] = Cooldown.new(0.0)


## What the slot holds, or null when it is empty.
func utility_in(slot: Utility.Slot) -> Utility:
	return movement if slot == Utility.Slot.MOVEMENT else skill


## strength: 0..1 vector from a stick or keys.
func move(strength: Vector2) -> void:
	_move_input = strength.limit_length(1.0)


## Whether the hero is being steered somewhere (a stick or keys held), not just carried by a dash.
func is_moving() -> bool:
	return _move_input.length() > MOVING_THRESHOLD


## Starts an attack. It happens after the weapon's wind-up; taps during the cooldown are ignored.
## With a target (auto-aim), the aim keeps tracking it during the wind-up so the delay doesn't cause misses,
## and weapons that aim at a spot land on it. Without one, strength (0..1) picks how far away to aim.
## held_seconds is how long the button was held, for weapons that charge (see Charge).
func attack(direction: Vector2, target: Node2D = null, strength := 1.0, held_seconds := Charge.FULL) -> void:
	if not _wielder.start(direction, weapon.aim_distance(strength), target, held_seconds):
		return
	facing = direction.normalized()
	if weapon.windup <= 0.0:
		_release(_wielder.advance(0.0, global_position))


## Uses the utility in the slot toward direction (dash, blink) or on the spot (shield, frost nova). strength (0..1)
## picks how far a blink goes. Ignored during its cooldown, and when the slot is empty.
func use_utility(slot: Utility.Slot, direction: Vector2, strength := 1.0) -> void:
	var used := utility_in(slot)
	if used == null or direction == Vector2.ZERO or not _cooldowns[slot].try_trigger():
		return
	facing = direction.normalized()
	_apply(used.activate(facing, strength))
	utility_used.emit(used.id)


## Drinks a potion: its effect starts at once. Whoever holds the potion belt decides whether there is one.
func drink(potion: Potion) -> void:
	_apply(potion.effect())


## Shows where an attack will go, in the weapon's own shape. Pass a zero direction or no shape to hide it.
## strength (0..1) places the landing spot of shapes that aim at a distance, as the weapon will when it fires.
func preview_aim(direction: Vector2, shape: AimShape = null, strength := 1.0) -> void:
	_show_aim(direction, shape, weapon.aim_distance(strength))


## Shows where the utility in the slot will go. A blink shows the spot it would really land on.
func preview_utility(slot: Utility.Slot, direction: Vector2, strength := 1.0) -> void:
	var used := utility_in(slot)
	if used == null or direction == Vector2.ZERO:
		_show_aim(Vector2.ZERO, null, 0.0)
		return
	var distance := used.aim_distance(strength)
	if used.hops():
		distance = global_position.distance_to(_blink_target(direction.normalized() * distance))
	_show_aim(direction, used.aim_shape(), distance)


## Fills the preview line by how charged the shot is (0..1), for weapons that charge.
func preview_charge(ratio: float) -> void:
	if _aim_shape != null:
		_aim_shape.fill = ratio
		queue_redraw()


func attack_cooldown_ratio() -> float:
	return _wielder.cooldown_ratio()


## How full each charge of the weapon's ammo is (see Ammo.segment_fills).
func ammo_fills() -> Array[float]:
	return _wielder.ammo_fills()


func utility_cooldown_ratio(slot: Utility.Slot) -> float:
	return _cooldowns[slot].remaining_ratio()


## How far from its centre attacks hit it.
func body_radius() -> float:
	return RADIUS


func is_shielded() -> bool:
	return _shield_time_left > 0.0


func is_hasted() -> bool:
	return _haste_time_left > 0.0


func is_mighty() -> bool:
	return _might_time_left > 0.0


## source: what dealt it, as a death message would name it (see Shot.source).
func take_damage(amount: int, source := "") -> void:
	if is_shielded() or amount <= 0:
		return
	last_hurt_by = source
	health.take_damage(amount)


## A poison tick: hurts unless poison already ticked on the player within the last tick interval (no stacking).
## A Shield blocks it without using up the interval.
func take_poison(amount: int, source: String, now: float) -> void:
	if is_shielded():
		return
	if poison.try_tick(now):
		take_damage(amount, source)


func _physics_process(delta: float) -> void:
	for cooldown: Cooldown in _cooldowns.values():
		cooldown.tick(delta)
	_shield_time_left = maxf(_shield_time_left - delta, 0.0)
	_haste_time_left = maxf(_haste_time_left - delta, 0.0)
	_might_time_left = maxf(_might_time_left - delta, 0.0)
	_release(_wielder.advance(delta, global_position))
	if _wielder.is_winding_up():
		facing = _wielder.aim_direction()
	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity = _dash_direction * _dash_speed
	else:
		velocity = _move_input * move_speed * ground_speed * (_haste_multiplier if is_hasted() else 1.0)
		if charging:
			velocity *= weapon.charging_move_share()
		if is_moving():
			facing = _move_input.normalized()
	move_and_slide()
	queue_redraw()


func _release(attacks: Array) -> void:
	if attacks.is_empty():
		return
	for attack: Variant in attacks:
		attack.source = "your own %s" % weapon.display_name
	if is_mighty():
		for attack: Variant in attacks:
			attack.damage += _might_bonus
	attack_fired.emit(attacks)


func _apply(effect: UtilityEffect) -> void:
	if effect.dash_seconds > 0.0:
		_dash_direction = effect.dash_direction
		_dash_speed = effect.dash_speed
		_dash_time_left = effect.dash_seconds
	_shield_time_left = maxf(_shield_time_left, effect.shield_seconds)
	health.heal(effect.heal_amount)
	if effect.blink_offset != Vector2.ZERO:
		global_position = _blink_target(effect.blink_offset)
	# What a utility lets out starts at its user; shots, like a weapon's, just in front of the body.
	for attack: Variant in effect.attacks:
		attack.origin = global_position
		if attack is Shot:
			attack.origin += attack.direction * Weapon.MUZZLE_DISTANCE
	_release(effect.attacks)
	if effect.haste_seconds > 0.0:
		_haste_multiplier = effect.haste_multiplier
		_haste_time_left = effect.haste_seconds
	if effect.might_seconds > 0.0:
		_might_bonus = effect.might_bonus
		_might_time_left = effect.might_seconds


func _show_aim(direction: Vector2, shape: AimShape, landing_distance: float) -> void:
	_aim_direction = direction.normalized()
	_aim_shape = shape
	_aim_distance = landing_distance
	queue_redraw()


func _blink_target(offset: Vector2) -> Vector2:
	return blink_landing.call(global_position, global_position + offset)


func _draw() -> void:
	if _wielder.is_winding_up():
		draw_line(Vector2.ZERO, _wielder.aim_direction() * (RADIUS + 28.0), WINDUP_COLOR, RADIUS * 1.4)
	if _aim_direction != Vector2.ZERO and _aim_shape != null:
		AimPreview.draw(self, _aim_shape, _aim_direction, _aim_distance, AIM_PREVIEW_COLOR)
	draw_circle(Vector2.ZERO, RADIUS, Color(BODY_COLOR, BASE_FILL_ALPHA))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, BODY_COLOR, BASE_RING_WIDTH, true)
	if is_shielded():
		draw_arc(Vector2.ZERO, RADIUS + SHIELD_RING_GAP, 0.0, TAU, 32, SHIELD_COLOR, 3.0, true)
	if is_hasted():
		draw_arc(Vector2.ZERO, RADIUS + POTION_RING_GAP, -PI / 2.0, PI / 2.0, 16, HASTE_COLOR, 3.0, true)
	if is_mighty():
		draw_arc(Vector2.ZERO, RADIUS + POTION_RING_GAP, PI / 2.0, PI * 1.5, 16, MIGHT_COLOR, 3.0, true)


func _on_died() -> void:
	set_physics_process(false)
	hide()
	died.emit()
