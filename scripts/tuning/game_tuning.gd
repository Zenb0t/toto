class_name GameTuning
extends RefCounted
## The knobs exposed in the Tune screen, and how they become game objects.
## Items (weapons, the utility) declare their own knobs; their tuning keys are "<item id>.<field>".
## Defaults come from the classes themselves, so there is one source of truth for every value.

const PLAYER_MOVE_SPEED := "player.move_speed"
const ENEMY_MOVE_SPEED := "enemy.move_speed"
const ENEMY_MAX_HEALTH := "enemy.max_health"
const CONTROLS_WEAPON_DEAD_ZONE := "controls.weapon_dead_zone"
const CONTROLS_UTILITY_DEAD_ZONE := "controls.utility_dead_zone"
const LOOT_ENEMY_DROP_CHANCE := "loot.enemy_drop_chance"
const DEFAULT_WEAPON_ID := "wand"


## Every weapon, in the order the quick switch cycles through them.
static func weapons() -> Array[Weapon]:
	return [Wand.new(), Sword.new(), Fireball.new(), Crossbow.new()]


static func weapon_ids() -> Array[String]:
	var ids: Array[String] = []
	for each in weapons():
		ids.append(each.id)
	return ids


static func next_weapon_id(current_id: String) -> String:
	var ids := weapon_ids()
	return ids[(ids.find(current_id) + 1) % ids.size()]


static func key(item_id: String, field: String) -> String:
	return "%s.%s" % [item_id, field]


static func weapon_group(weapon_id: String) -> String:
	return "Weapon: %s" % _new_weapon(weapon_id).display_name


static func create() -> Tuning:
	var params: Array[Tuning.Param] = [
		Tuning.Param.new(PLAYER_MOVE_SPEED, "Move speed", "Player", 60, 300, 5, Player.DEFAULT_MOVE_SPEED),
	]
	for each in weapons():
		params.append_array(_item_params(each, each.id, weapon_group(each.id), each.knobs()))
	var utility := Utility.new()
	params.append_array(_item_params(utility, utility.id, "Utility: %s" % utility.display_name, utility.knobs()))
	params.append_array([
		Tuning.Param.new(ENEMY_MOVE_SPEED, "Move speed", "Enemies", 20, 250, 5, Enemy.DEFAULT_MOVE_SPEED),
		Tuning.Param.new(ENEMY_MAX_HEALTH, "Health", "Enemies", 1, 10, 1, Enemy.DEFAULT_MAX_HEALTH, true),
		Tuning.Param.new(
			LOOT_ENEMY_DROP_CHANCE, "Enemy drop chance", "Loot", 0, 1, 0.05, LootTable.DEFAULT_ENEMY_DROP_CHANCE),
		Tuning.Param.new(
			CONTROLS_WEAPON_DEAD_ZONE, "Weapon dead zone", "Controls", 0, 100, 2, AimButton.DEFAULT_DEAD_ZONE),
		Tuning.Param.new(
			CONTROLS_UTILITY_DEAD_ZONE, "Utility dead zone", "Controls", 0, 100, 2, AimButton.DEFAULT_DEAD_ZONE),
	])
	return Tuning.new(params)


## Every group except the weapons that are not equipped, so the Tune screen shows what is in play.
static func visible_groups(tuning: Tuning, equipped_weapon_id: String) -> Array[String]:
	var hidden: Array[String] = []
	for id in weapon_ids():
		if id != equipped_weapon_id:
			hidden.append(weapon_group(id))
	var groups: Array[String] = []
	for param in tuning.params():
		if param.group not in groups and param.group not in hidden:
			groups.append(param.group)
	return groups


## Unknown ids fall back to the starter weapon, so a stale saved choice can't break a run.
static func weapon(tuning: Tuning, weapon_id: String) -> Weapon:
	var result := _new_weapon(weapon_id)
	_apply_knobs(result, result.id, result.knobs(), tuning)
	return result


static func utility(tuning: Tuning) -> Utility:
	var result := Utility.new()
	_apply_knobs(result, result.id, result.knobs(), tuning)
	return result


static func player_move_speed(tuning: Tuning) -> float:
	return tuning.value(PLAYER_MOVE_SPEED)


static func enemy_move_speed(tuning: Tuning) -> float:
	return tuning.value(ENEMY_MOVE_SPEED)


static func enemy_max_health(tuning: Tuning) -> int:
	return roundi(tuning.value(ENEMY_MAX_HEALTH))


static func enemy_drop_chance(tuning: Tuning) -> float:
	return tuning.value(LOOT_ENEMY_DROP_CHANCE)


static func weapon_dead_zone(tuning: Tuning) -> float:
	return tuning.value(CONTROLS_WEAPON_DEAD_ZONE)


static func utility_dead_zone(tuning: Tuning) -> float:
	return tuning.value(CONTROLS_UTILITY_DEAD_ZONE)


static func _new_weapon(weapon_id: String) -> Weapon:
	for each in weapons():
		if each.id == weapon_id:
			return each
	return _new_weapon(DEFAULT_WEAPON_ID)


static func _item_params(item: Object, item_id: String, group: String, knobs: Array[Knob]) -> Array[Tuning.Param]:
	var params: Array[Tuning.Param] = []
	for knob in knobs:
		params.append(Tuning.Param.new(
			key(item_id, knob.field), knob.label, group, knob.min_value, knob.max_value, knob.step,
			item.get(knob.field)))
	return params


## Builds the item from tuning values, keeping whole-number fields (counts, damage) whole.
static func _apply_knobs(item: Object, item_id: String, knobs: Array[Knob], tuning: Tuning) -> void:
	for knob in knobs:
		var value := tuning.value(key(item_id, knob.field))
		item.set(knob.field, roundi(value) if item.get(knob.field) is int else value)
