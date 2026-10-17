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
const CONTROLS_BUTTON_CATCH := "controls.button_catch"
const LOOT_ENEMY_DROP_CHANCE := "loot.enemy_drop_chance"
const LOOT_POTION_DROP_CHANCE := "loot.potion_drop_chance"
const LOOT_CHEST_POTION_CHANCE := "loot.chest_potion_chance"
const CAMERA_PITCH := "camera.pitch"
const CAMERA_DISTANCE := "camera.distance"
const CAMERA_FIELD_OF_VIEW := "camera.field_of_view"
const CAMERA_LOOK_AHEAD := "camera.look_ahead"
const CAMERA_WALL_HEIGHT := "camera.wall_height"
const PLAYER_GROUP := "Player"
const ENEMIES_GROUP := "Enemies"
const LOOT_GROUP := "Loot"
const CONTROLS_GROUP := "Controls"
const CAMERA_GROUP := "Camera"
const EQUIPPED_MARK := "  (equipped)"
const DEFAULT_WEAPON_ID := "wand"
const DEFAULT_UTILITY_ID := "dash"


## Every weapon, in the order the quick switch cycles through them.
static func weapons() -> Array[Weapon]:
	return [
		MagicMissile.new(), Sword.new(), Fireball.new(), Crossbow.new(), LightningBolt.new(), MephiticCloud.new(),
		Battleaxe.new(),
	]


static func utilities() -> Array[Utility]:
	return [Dash.new(), Shield.new(), Blink.new(), FrostNova.new(), Beckoning.new()]


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
		Tuning.Param.new(PLAYER_MOVE_SPEED, "Move speed", PLAYER_GROUP, 60, 300, 5, Player.DEFAULT_MOVE_SPEED),
	]
	for each in weapons():
		params.append_array(_item_params(each, weapon_group(each.id)))
	for each in utilities():
		params.append_array(_item_params(each, utility_group(each.id)))
	for each in potions():
		params.append_array(_item_params(each, potion_group(each.id)))
	params.append_array([
		Tuning.Param.new(ENEMY_MOVE_SPEED, "Move speed", ENEMIES_GROUP, 20, 250, 5, Enemy.DEFAULT_MOVE_SPEED),
		Tuning.Param.new(ENEMY_HEALTH_MULTIPLIER, "Health (x)", ENEMIES_GROUP, 0.25, 4, 0.05, 1.0, true),
		Tuning.Param.new(
			ENEMY_COOLDOWN_MULTIPLIER, "Attack slowness (x)", ENEMIES_GROUP, 1, 5, 0.1, Enemy.DEFAULT_COOLDOWN_MULTIPLIER),
		Tuning.Param.new(
			ENEMY_TELEGRAPH, "Telegraph (s)", ENEMIES_GROUP, 0, 1.5, 0.05, Enemy.DEFAULT_TELEGRAPH_SECONDS),
		Tuning.Param.new(
			LOOT_ENEMY_DROP_CHANCE, "Enemy drop chance", LOOT_GROUP, 0, 1, 0.05, LootTable.DEFAULT_ENEMY_DROP_CHANCE),
		Tuning.Param.new(
			LOOT_POTION_DROP_CHANCE, "Enemy potion chance", LOOT_GROUP, 0, 1, 0.05, LootTable.DEFAULT_POTION_DROP_CHANCE),
		Tuning.Param.new(
			LOOT_CHEST_POTION_CHANCE, "Chest potion chance", LOOT_GROUP, 0, 1, 0.05, LootTable.DEFAULT_CHEST_POTION_CHANCE),
		Tuning.Param.new(
			CONTROLS_WEAPON_DEAD_ZONE, "Weapon dead zone", CONTROLS_GROUP, 0, 100, 2, AimButton.DEFAULT_DEAD_ZONE),
		Tuning.Param.new(
			CONTROLS_UTILITY_DEAD_ZONE, "Utility dead zone", CONTROLS_GROUP, 0, 100, 2, AimButton.DEFAULT_DEAD_ZONE),
		Tuning.Param.new(
			CONTROLS_BUTTON_CATCH, "Button catch area (x)", CONTROLS_GROUP, 1, 3, 0.1, AimButton.DEFAULT_CATCH_SCALE),
		Tuning.Param.new(
			CAMERA_PITCH, "Tilt (90 = top-down)", CAMERA_GROUP, 30, 90, 1, CameraFraming.DEFAULT_PITCH_DEGREES),
		Tuning.Param.new(
			CAMERA_DISTANCE, "Distance (cells)", CAMERA_GROUP, 6, 30, 0.5, CameraFraming.DEFAULT_DISTANCE),
		Tuning.Param.new(
			CAMERA_FIELD_OF_VIEW, "Field of view", CAMERA_GROUP, 15, 75, 1, CameraFraming.DEFAULT_FIELD_OF_VIEW),
		Tuning.Param.new(
			CAMERA_LOOK_AHEAD, "Look ahead (cells)", CAMERA_GROUP, 0, 5, 0.25, CameraFraming.DEFAULT_LOOK_AHEAD),
		Tuning.Param.new(
			CAMERA_WALL_HEIGHT, "Wall height (cells)", CAMERA_GROUP, 0.2, 2, 0.05, MapView3D.DEFAULT_WALL_HEIGHT),
	])
	return Tuning.new(params)


## The Tune screen's menu: every group of knobs, sorted into sections. Weapons and utilities each get an
## entry under their section, with the equipped one marked.
static func sections(equipped_weapon_id: String, equipped_utility_id: String) -> Array[TuningSection]:
	return [
		TuningSection.new(PLAYER_GROUP, [PLAYER_GROUP]),
		_items_section("Weapons", weapons(), weapon_group, equipped_weapon_id),
		_items_section("Utilities", utilities(), utility_group, equipped_utility_id),
		_items_section("Potions", potions(), potion_group, ""),
		TuningSection.new(ENEMIES_GROUP, [ENEMIES_GROUP]),
		TuningSection.new(LOOT_GROUP, [LOOT_GROUP]),
		TuningSection.new(CONTROLS_GROUP, [CONTROLS_GROUP]),
		TuningSection.new(CAMERA_GROUP, [CAMERA_GROUP]),
	]


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


## How far around the attack and utility buttons a touch still grabs them, as a multiple of their radius.
static func button_catch_scale(tuning: Tuning) -> float:
	return tuning.value(CONTROLS_BUTTON_CATCH)


static func camera_framing(tuning: Tuning) -> CameraFraming:
	var framing := CameraFraming.new()
	framing.pitch_degrees = tuning.value(CAMERA_PITCH)
	framing.distance = tuning.value(CAMERA_DISTANCE)
	framing.field_of_view = tuning.value(CAMERA_FIELD_OF_VIEW)
	framing.look_ahead = tuning.value(CAMERA_LOOK_AHEAD)
	return framing


static func wall_height(tuning: Tuning) -> float:
	return tuning.value(CAMERA_WALL_HEIGHT)


## items: Items or Potions; group_of: their id -> their group.
static func _items_section(title: String, items: Array, group_of: Callable, equipped_id: String) -> TuningSection:
	var groups: Array[String] = []
	var labels := {}
	for each: Object in items:
		var group: String = group_of.call(each.id)
		groups.append(group)
		labels[group] = each.display_name + (EQUIPPED_MARK if each.id == equipped_id else "")
	return TuningSection.new(title, groups, labels)


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
