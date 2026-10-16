class_name GameTuning
extends RefCounted
## The knobs exposed in the Tune screen, and how they become game objects.
## Defaults come from the classes themselves, so there is one source of truth for every value.

const PLAYER_MOVE_SPEED := "player.move_speed"
const WEAPON_COOLDOWN := "weapon.cooldown"
const WEAPON_WINDUP := "weapon.windup"
const WEAPON_SHOT_SPEED := "weapon.shot_speed"
const WEAPON_SHOT_RANGE := "weapon.shot_range"
const WEAPON_SHOT_DAMAGE := "weapon.shot_damage"
const UTILITY_DASH_SPEED := "utility.dash_speed"
const UTILITY_DASH_DURATION := "utility.dash_duration"
const UTILITY_COOLDOWN := "utility.cooldown"
const ENEMY_MOVE_SPEED := "enemy.move_speed"
const ENEMY_MAX_HEALTH := "enemy.max_health"


static func create() -> Tuning:
	var weapon := Weapon.new()
	var utility := Utility.new()
	var weapon_group := "Weapon: %s" % weapon.display_name
	var utility_group := "Utility: %s" % utility.display_name
	var params: Array[Tuning.Param] = [
		Tuning.Param.new(PLAYER_MOVE_SPEED, "Move speed", "Player", 60, 300, 5, Player.DEFAULT_MOVE_SPEED),
		Tuning.Param.new(WEAPON_COOLDOWN, "Cooldown (s)", weapon_group, 0.1, 2.0, 0.05, weapon.cooldown),
		Tuning.Param.new(WEAPON_WINDUP, "Wind-up (s)", weapon_group, 0.0, 1.0, 0.02, weapon.windup),
		Tuning.Param.new(WEAPON_SHOT_SPEED, "Shot speed", weapon_group, 100, 1200, 10, weapon.shot_speed),
		Tuning.Param.new(WEAPON_SHOT_RANGE, "Range", weapon_group, 100, 1000, 10, weapon.shot_range),
		Tuning.Param.new(WEAPON_SHOT_DAMAGE, "Damage", weapon_group, 1, 5, 1, weapon.shot_damage),
		Tuning.Param.new(UTILITY_DASH_SPEED, "Dash speed", utility_group, 200, 1500, 25, utility.dash_speed),
		Tuning.Param.new(UTILITY_DASH_DURATION, "Dash time (s)", utility_group, 0.05, 0.5, 0.01, utility.dash_duration),
		Tuning.Param.new(UTILITY_COOLDOWN, "Cooldown (s)", utility_group, 0.2, 5.0, 0.1, utility.cooldown),
		Tuning.Param.new(ENEMY_MOVE_SPEED, "Move speed", "Enemies", 20, 250, 5, Enemy.DEFAULT_MOVE_SPEED),
		Tuning.Param.new(ENEMY_MAX_HEALTH, "Health", "Enemies", 1, 10, 1, Enemy.DEFAULT_MAX_HEALTH, true),
	]
	return Tuning.new(params)


static func weapon(tuning: Tuning) -> Weapon:
	var result := Weapon.new()
	result.cooldown = tuning.value(WEAPON_COOLDOWN)
	result.windup = tuning.value(WEAPON_WINDUP)
	result.shot_speed = tuning.value(WEAPON_SHOT_SPEED)
	result.shot_range = tuning.value(WEAPON_SHOT_RANGE)
	result.shot_damage = roundi(tuning.value(WEAPON_SHOT_DAMAGE))
	return result


static func utility(tuning: Tuning) -> Utility:
	var result := Utility.new()
	result.dash_speed = tuning.value(UTILITY_DASH_SPEED)
	result.dash_duration = tuning.value(UTILITY_DASH_DURATION)
	result.cooldown = tuning.value(UTILITY_COOLDOWN)
	return result


static func player_move_speed(tuning: Tuning) -> float:
	return tuning.value(PLAYER_MOVE_SPEED)


static func enemy_move_speed(tuning: Tuning) -> float:
	return tuning.value(ENEMY_MOVE_SPEED)


static func enemy_max_health(tuning: Tuning) -> int:
	return roundi(tuning.value(ENEMY_MAX_HEALTH))
