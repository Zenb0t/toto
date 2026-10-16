class_name GameTuning
extends RefCounted
## The knobs exposed in the Tune screen, and how they become game objects.
## Items (weapons, utilities) and potions declare their own knobs; their tuning keys are "<id>.<field>".
## Defaults come from the classes themselves, so there is one source of truth for every value.

const PLAYER_MOVE_SPEED := "player.move_speed"
const ENEMY_MOVE_SPEED := "enemy.move_speed"
const ENEMY_HEALTH_MULTIPLIER := "enemy.health_multiplier"
const ENEMY_COOLDOWN_MULTIPLIER := "enemy.cooldown_multiplier"
const ENEMY_TELEGRAPH := "enemy.telegraph"
const CONTROLS_WEAPON_DEAD_ZONE := "controls.weapon_dead_zone"
const CONTROLS_UTILITY_DEAD_ZONE := "controls.utility_dead_zone"
const LOOT_ENEMY_DROP_CHANCE := "loot.enemy_drop_chance"
const LOOT_POTION_DROP_CHANCE := "loot.potion_drop_chance"
const LOOT_CHEST_POTION_CHANCE := "loot.chest_potion_chance"
const CAMERA_PITCH := "camera.pitch"
const CAMERA_DISTANCE := "camera.distance"
const CAMERA_FIELD_OF_VIEW := "camera.field_of_view"
const CAMERA_LOOK_AHEAD := "camera.look_ahead"
const CAMERA_WALL_HEIGHT := "camera.wall_height"
const DEFAULT_WEAPON_ID := "wand"
const DEFAULT_UTILITY_ID := "dash"


## Every weapon, in the order the quick switch cycles through them.
static func weapons() -> Array[Weapon]:
	return [Wand.new(), Sword.new(), Fireball.new(), Crossbow.new()]


static func utilities() -> Array[Utility]:
	return [Dash.new(), Shield.new()]


## Every potion, in the order the potion belt shows them.
static func potions() -> Array[Potion]:
	return [HealingPotion.new(), HastePotion.new(), MightPotion.new()]


static func potion_ids() -> Array[String]:
	var ids: Array[String] = []
	for each in potions():
		ids.append(each.id)
	return ids


## How often each potion turns up, relative to the others (potion id -> weight).
static func potion_weights() -> Dictionary:
	var weights := {}
	for each in potions():
		weights[each.id] = each.frequency
	return weights


static func weapon_ids() -> Array[String]:
	return _ids(weapons())


static func utility_ids() -> Array[String]:
	return _ids(utilities())


## Everything that can be found as loot.
static func item_ids() -> Array[String]:
	var ids := weapon_ids()
	ids.append_array(utility_ids())
	return ids


static func next_weapon_id(current_id: String) -> String:
	var ids := weapon_ids()
	return ids[(ids.find(current_id) + 1) % ids.size()]


static func key(item_id: String, field: String) -> String:
	return "%s.%s" % [item_id, field]


static func weapon_group(weapon_id: String) -> String:
	return "Weapon: %s" % _new_weapon(weapon_id).display_name


static func utility_group(utility_id: String) -> String:
	return "Utility: %s" % _new_utility(utility_id).display_name


static func potion_group(potion_id: String) -> String:
	return _new_potion(potion_id).display_name


static func create() -> Tuning:
	var params: Array[Tuning.Param] = [
		Tuning.Param.new(PLAYER_MOVE_SPEED, "Move speed", "Player", 60, 300, 5, Player.DEFAULT_MOVE_SPEED),
	]
	for each in weapons():
		params.append_array(_item_params(each, weapon_group(each.id)))
	for each in utilities():
		params.append_array(_item_params(each, utility_group(each.id)))
	for each in potions():
		params.append_array(_item_params(each, potion_group(each.id)))
	params.append_array([
		Tuning.Param.new(ENEMY_MOVE_SPEED, "Move speed", "Enemies", 20, 250, 5, Enemy.DEFAULT_MOVE_SPEED),
		Tuning.Param.new(ENEMY_HEALTH_MULTIPLIER, "Health (x)", "Enemies", 0.25, 4, 0.05, 1.0, true),
		Tuning.Param.new(
			ENEMY_COOLDOWN_MULTIPLIER, "Attack slowness (x)", "Enemies", 1, 5, 0.1, Enemy.DEFAULT_COOLDOWN_MULTIPLIER),
		Tuning.Param.new(
			ENEMY_TELEGRAPH, "Telegraph (s)", "Enemies", 0, 1.5, 0.05, Enemy.DEFAULT_TELEGRAPH_SECONDS),
		Tuning.Param.new(
			LOOT_ENEMY_DROP_CHANCE, "Enemy drop chance", "Loot", 0, 1, 0.05, LootTable.DEFAULT_ENEMY_DROP_CHANCE),
		Tuning.Param.new(
			LOOT_POTION_DROP_CHANCE, "Enemy potion chance", "Loot", 0, 1, 0.05, LootTable.DEFAULT_POTION_DROP_CHANCE),
		Tuning.Param.new(
			LOOT_CHEST_POTION_CHANCE, "Chest potion chance", "Loot", 0, 1, 0.05, LootTable.DEFAULT_CHEST_POTION_CHANCE),
		Tuning.Param.new(
			CONTROLS_WEAPON_DEAD_ZONE, "Weapon dead zone", "Controls", 0, 100, 2, AimButton.DEFAULT_DEAD_ZONE),
		Tuning.Param.new(
			CONTROLS_UTILITY_DEAD_ZONE, "Utility dead zone", "Controls", 0, 100, 2, AimButton.DEFAULT_DEAD_ZONE),
		Tuning.Param.new(
			CAMERA_PITCH, "Tilt (90 = top-down)", "Camera", 30, 90, 1, CameraFraming.DEFAULT_PITCH_DEGREES),
		Tuning.Param.new(
			CAMERA_DISTANCE, "Distance (cells)", "Camera", 6, 30, 0.5, CameraFraming.DEFAULT_DISTANCE),
		Tuning.Param.new(
			CAMERA_FIELD_OF_VIEW, "Field of view", "Camera", 15, 75, 1, CameraFraming.DEFAULT_FIELD_OF_VIEW),
		Tuning.Param.new(
			CAMERA_LOOK_AHEAD, "Look ahead (cells)", "Camera", 0, 5, 0.25, CameraFraming.DEFAULT_LOOK_AHEAD),
		Tuning.Param.new(
			CAMERA_WALL_HEIGHT, "Wall height (cells)", "Camera", 0.2, 2, 0.05, MapView3D.DEFAULT_WALL_HEIGHT),
	])
	return Tuning.new(params)


## Every group except the items that are not equipped, so the Tune screen shows what is in play.
static func visible_groups(tuning: Tuning, equipped_weapon_id: String, equipped_utility_id: String) -> Array[String]:
	var hidden: Array[String] = []
	for id in weapon_ids():
		if id != equipped_weapon_id:
			hidden.append(weapon_group(id))
	for id in utility_ids():
		if id != equipped_utility_id:
			hidden.append(utility_group(id))
	var groups: Array[String] = []
	for param in tuning.params():
		if param.group not in groups and param.group not in hidden:
			groups.append(param.group)
	return groups


## Unknown ids fall back to the starter weapon, so a stale saved choice can't break a run.
static func weapon(tuning: Tuning, weapon_id: String) -> Weapon:
	var result := _new_weapon(weapon_id)
	_apply_knobs(result, tuning)
	return result


## The same weapon in an enemy's hands: slower between attacks, with a longer, telegraphed wind-up.
static func enemy_weapon(tuning: Tuning, weapon_id: String) -> Weapon:
	var result := weapon(tuning, weapon_id)
	result.cooldown *= tuning.value(ENEMY_COOLDOWN_MULTIPLIER)
	result.windup += tuning.value(ENEMY_TELEGRAPH)
	return result


## Unknown ids fall back to the starter utility.
static func utility(tuning: Tuning, utility_id: String) -> Utility:
	var result := _new_utility(utility_id)
	_apply_knobs(result, tuning)
	return result


## Unknown ids fall back to healing.
static func potion(tuning: Tuning, potion_id: String) -> Potion:
	var result := _new_potion(potion_id)
	_apply_knobs(result, tuning)
	return result


static func is_weapon(item_id: String) -> bool:
	return item_id in weapon_ids()


static func item(tuning: Tuning, item_id: String) -> Item:
	return weapon(tuning, item_id) if is_weapon(item_id) else utility(tuning, item_id)


static func player_move_speed(tuning: Tuning) -> float:
	return tuning.value(PLAYER_MOVE_SPEED)


static func enemy_move_speed(tuning: Tuning) -> float:
	return tuning.value(ENEMY_MOVE_SPEED)


## How much tougher than their kind's health enemies are (1 = as listed in the Bestiary).
static func enemy_health_multiplier(tuning: Tuning) -> float:
	return tuning.value(ENEMY_HEALTH_MULTIPLIER)


static func enemy_drop_chance(tuning: Tuning) -> float:
	return tuning.value(LOOT_ENEMY_DROP_CHANCE)


static func potion_drop_chance(tuning: Tuning) -> float:
	return tuning.value(LOOT_POTION_DROP_CHANCE)


static func chest_potion_chance(tuning: Tuning) -> float:
	return tuning.value(LOOT_CHEST_POTION_CHANCE)


static func weapon_dead_zone(tuning: Tuning) -> float:
	return tuning.value(CONTROLS_WEAPON_DEAD_ZONE)


static func utility_dead_zone(tuning: Tuning) -> float:
	return tuning.value(CONTROLS_UTILITY_DEAD_ZONE)


static func camera_framing(tuning: Tuning) -> CameraFraming:
	var framing := CameraFraming.new()
	framing.pitch_degrees = tuning.value(CAMERA_PITCH)
	framing.distance = tuning.value(CAMERA_DISTANCE)
	framing.field_of_view = tuning.value(CAMERA_FIELD_OF_VIEW)
	framing.look_ahead = tuning.value(CAMERA_LOOK_AHEAD)
	return framing


static func wall_height(tuning: Tuning) -> float:
	return tuning.value(CAMERA_WALL_HEIGHT)


static func _ids(items: Array) -> Array[String]:
	var ids: Array[String] = []
	for each: Item in items:
		ids.append(each.id)
	return ids


static func _new_weapon(weapon_id: String) -> Weapon:
	for each in weapons():
		if each.id == weapon_id:
			return each
	return _new_weapon(DEFAULT_WEAPON_ID)


static func _new_utility(utility_id: String) -> Utility:
	for each in utilities():
		if each.id == utility_id:
			return each
	return _new_utility(DEFAULT_UTILITY_ID)


static func _new_potion(potion_id: String) -> Potion:
	for each in potions():
		if each.id == potion_id:
			return each
	return HealingPotion.new()


## fresh: an Item or a Potion, as built with its defaults.
static func _item_params(fresh: Object, group: String) -> Array[Tuning.Param]:
	var params: Array[Tuning.Param] = []
	for knob in fresh.knobs():
		params.append(Tuning.Param.new(
			key(fresh.id, knob.field), knob.label, group, knob.min_value, knob.max_value, knob.step,
			fresh.get(knob.field)))
	return params


## Builds an item or potion from tuning values, keeping whole-number fields (counts, damage) whole.
static func _apply_knobs(built: Object, tuning: Tuning) -> void:
	for knob in built.knobs():
		var value := tuning.value(key(built.id, knob.field))
		built.set(knob.field, roundi(value) if built.get(knob.field) is int else value)
