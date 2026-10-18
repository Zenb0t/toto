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
const ENEMY_LEAD := "enemy.lead"
const ENEMY_RECOVER := "enemy.recover"
const ENEMY_REGENERATION := "enemy.regeneration"
const SQUAD_MAX_ATTACKERS := "squad.max_attackers"
const SQUAD_TURN_GAP := "squad.turn_gap"
const SQUAD_FLANK_SPREAD := "squad.flank_spread"
const AWARENESS_ASLEEP_SIGHT := "awareness.asleep_sight"
const AWARENESS_WANDER_SIGHT := "awareness.wander_sight"
const AWARENESS_NOISE := "awareness.noise"
const AWARENESS_SHOUT := "awareness.shout"
const AWARENESS_GIVE_UP_SECONDS := "awareness.give_up_seconds"
const AWARENESS_GIVE_UP_CELLS := "awareness.give_up_cells"
const ENEMY_NOTICING := "enemy.noticing"
const ENEMY_WANDER_SPEED := "enemy.wander_speed"
const BAND_WANDER_RADIUS := "band.wander_radius"
const CONTROLS_WEAPON_DEAD_ZONE := "controls.weapon_dead_zone"
const CONTROLS_UTILITY_DEAD_ZONE := "controls.utility_dead_zone"
const CONTROLS_BUTTON_CATCH := "controls.button_catch"
const CONTROLS_HAPTIC := "controls.haptic_ms"
const CONTROLS_DRAG_REACH := "controls.drag_reach"
const CONTROLS_SHOW_WEAPON_SWITCH := "controls.show_weapon_switch"
## A short buzz, in milliseconds, when an aim comes back into the dead zone.
const DEFAULT_HAPTIC_MS := 20
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
const LICH_GROUP := "Lich"
const LOOT_GROUP := "Loot"
const CONTROLS_GROUP := "Controls"
const CAMERA_GROUP := "Camera"
## Resting at a campfire (see RestProfile) and when it is refused (see MonstersAround).
const REST_GROUP := "Rest"
## The world's generation knobs (see QuadrantRecipe): they shape the next world, not the one being played.
const WORLD_GROUP := "World"
const EQUIPPED_MARK := "  (equipped)"
const DEFAULT_WEAPON_ID := "dagger"
const DEFAULT_UTILITY_ID := "dash"


## Every weapon, in the order the quick switch cycles through them.
static func weapons() -> Array[Weapon]:
	return [
		Dagger.new(), MagicMissile.new(), Sword.new(), Fireball.new(), Crossbow.new(), LightningBolt.new(),
		MephiticCloud.new(), Battleaxe.new(), Knuckles.new(), Bow.new(),
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
	params.append_array(_item_params(QuadrantRecipe.plains(), WORLD_GROUP, true))
	params.append_array(_item_params(RestProfile.campfire(), REST_GROUP))
	params.append_array(_item_params(RestProfile.inn(), REST_GROUP))
	params.append_array(_item_params(MonstersAround.new(), REST_GROUP))
	params.append_array(_item_params(Ambush.new(), REST_GROUP))
	params.append_array(_item_params(CryptRecipe.new(), WORLD_GROUP, true))
	params.append_array(_item_params(Lich.new(), LICH_GROUP))
	params.append_array(_item_params(SpellPicker.new(), LICH_GROUP))
	params.append_array([
		Tuning.Param.new(ENEMY_MOVE_SPEED, "Move speed", ENEMIES_GROUP, 20, 250, 5, Enemy.DEFAULT_MOVE_SPEED),
		Tuning.Param.new(ENEMY_HEALTH_MULTIPLIER, "Health (x)", ENEMIES_GROUP, 0.25, 4, 0.05, Enemy.DEFAULT_HEALTH_MULTIPLIER, true),
		Tuning.Param.new(
			ENEMY_COOLDOWN_MULTIPLIER, "Reload slowness (x)", ENEMIES_GROUP, 1, 5, 0.1, Enemy.DEFAULT_COOLDOWN_MULTIPLIER),
		Tuning.Param.new(
			ENEMY_TELEGRAPH, "Telegraph (s)", ENEMIES_GROUP, 0, 1.5, 0.05, Enemy.DEFAULT_TELEGRAPH_SECONDS),
		Tuning.Param.new(
			ENEMY_LEAD, "Aim ahead (0-1)", ENEMIES_GROUP, 0, 1, 0.05, EnemyTactics.DEFAULT_LEAD_SHARE),
		Tuning.Param.new(
			ENEMY_RECOVER, "Step aside after attack (s)", ENEMIES_GROUP, 0, 2, 0.05, EnemyBrain.DEFAULT_RECOVER_SECONDS),
		Tuning.Param.new(
			ENEMY_REGENERATION, "Heal while away (HP/s)", ENEMIES_GROUP, 0, 100, 1,
			Regeneration.DEFAULT_HEALTH_PER_SECOND),
		Tuning.Param.new(
			SQUAD_MAX_ATTACKERS, "Attackers at once", ENEMIES_GROUP, 1, 8, 1, Squad.DEFAULT_MAX_ATTACKERS),
		Tuning.Param.new(
			SQUAD_TURN_GAP, "Gap between attacks (s)", ENEMIES_GROUP, 0, 2, 0.05, Squad.DEFAULT_TURN_GAP_SECONDS),
		Tuning.Param.new(
			SQUAD_FLANK_SPREAD, "Flank spread (deg)", ENEMIES_GROUP, 0, 180, 5, Squad.DEFAULT_FLANK_SPREAD_DEGREES),
		Tuning.Param.new(
			AWARENESS_ASLEEP_SIGHT, "Notice when asleep (cells)", ENEMIES_GROUP, 0, 20, 0.5,
			Awareness.DEFAULT_ASLEEP_SIGHT_CELLS),
		Tuning.Param.new(
			AWARENESS_WANDER_SIGHT, "Notice when wandering (cells)", ENEMIES_GROUP, 0, 20, 0.5,
			Awareness.DEFAULT_WANDER_SIGHT_CELLS),
		Tuning.Param.new(
			AWARENESS_NOISE, "Hero's noise carries (cells)", ENEMIES_GROUP, 0, 20, 0.5,
			Awareness.DEFAULT_NOISE_CELLS),
		Tuning.Param.new(
			AWARENESS_SHOUT, "Monster's shout carries (cells)", ENEMIES_GROUP, 0, 20, 0.5,
			Awareness.DEFAULT_SHOUT_CELLS),
		Tuning.Param.new(
			AWARENESS_GIVE_UP_SECONDS, "Give up after unseen (s)", ENEMIES_GROUP, 1, 30, 0.5,
			Awareness.DEFAULT_GIVE_UP_SECONDS),
		Tuning.Param.new(
			AWARENESS_GIVE_UP_CELLS, "Give up beyond home (cells)", ENEMIES_GROUP, 5, 60, 1,
			Awareness.DEFAULT_GIVE_UP_CELLS),
		Tuning.Param.new(
			ENEMY_NOTICING, "Noticing pause (s)", ENEMIES_GROUP, 0, 2, 0.05, EnemyBrain.DEFAULT_NOTICING_SECONDS),
		Tuning.Param.new(
			ENEMY_WANDER_SPEED, "Wander speed (x move speed)", ENEMIES_GROUP, 0.1, 1, 0.05,
			Enemy.DEFAULT_WANDER_SPEED_SHARE),
		Tuning.Param.new(
			BAND_WANDER_RADIUS, "Wander radius (cells)", ENEMIES_GROUP, 1, 15, 0.5, Band.DEFAULT_WANDER_RADIUS_CELLS),
		Tuning.Param.new(
			LOOT_ENEMY_DROP_CHANCE, "Enemy drop chance", LOOT_GROUP, 0, 1, 0.01, LootTable.DEFAULT_ENEMY_DROP_CHANCE),
		Tuning.Param.new(
			LOOT_POTION_DROP_CHANCE, "Enemy potion chance", LOOT_GROUP, 0, 1, 0.05, LootTable.DEFAULT_POTION_DROP_CHANCE),
		Tuning.Param.new(
			LOOT_CHEST_POTION_CHANCE, "Chest potion chance", LOOT_GROUP, 0, 1, 0.05, LootTable.DEFAULT_CHEST_POTION_CHANCE),
		Tuning.Param.new(
			CONTROLS_WEAPON_DEAD_ZONE, "Weapon dead zone", CONTROLS_GROUP, 0, 100, 2, AimButton.ATTACK_DEAD_ZONE),
		Tuning.Param.new(
			CONTROLS_UTILITY_DEAD_ZONE, "Utility dead zone", CONTROLS_GROUP, 0, 100, 2, AimButton.DEFAULT_DEAD_ZONE),
		Tuning.Param.new(
			CONTROLS_BUTTON_CATCH, "Button catch area (x)", CONTROLS_GROUP, 1, 3, 0.1, AimButton.DEFAULT_CATCH_SCALE),
		Tuning.Param.new(
			CONTROLS_DRAG_REACH, "Full drag reach (x button)", CONTROLS_GROUP, 1, 4, 0.1, AimButton.DEFAULT_DRAG_REACH),
		Tuning.Param.new(CONTROLS_HAPTIC, "Haptic buzz (ms, 0 = off)", CONTROLS_GROUP, 0, 80, 5, DEFAULT_HAPTIC_MS),
		Tuning.Param.new(
			CONTROLS_SHOW_WEAPON_SWITCH, "Show weapon switch (0 = hide)", CONTROLS_GROUP, 0, 1, 1, 0),
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


## The keys of knobs counted in health points (damage, healing), which old saves hold on an older scale.
static func points_keys() -> Array[String]:
	var keys: Array[String] = []
	var tunables: Array = []
	tunables.append_array(weapons())
	tunables.append_array(utilities())
	tunables.append_array(potions())
	for each: Object in tunables:
		for knob: Knob in each.knobs():
			if knob.is_points:
				keys.append(key(each.id, knob.field))
	return keys


## Saved values brought from an older health scale to this one: health points are multiplied by factor, the
## rest stays as it was. Returns a new dictionary.
static func rescaled_points(saved: Dictionary, factor: float) -> Dictionary:
	var result := saved.duplicate()
	for points_key in points_keys():
		var value: Variant = result.get(points_key)
		if value is float or value is int:
			result[points_key] = value * factor
	return result


## The Tune screen's menu: every group of knobs, sorted into sections. Weapons and utilities each get an
## entry under their section, with the equipped one marked.
static func sections(equipped_weapon_id: String, equipped_utility_id: String) -> Array[TuningSection]:
	return [
		TuningSection.new(PLAYER_GROUP, [PLAYER_GROUP]),
		_items_section("Weapons", weapons(), weapon_group, equipped_weapon_id),
		_items_section("Utilities", utilities(), utility_group, equipped_utility_id),
		_items_section("Potions", potions(), potion_group, ""),
		TuningSection.new(ENEMIES_GROUP, [ENEMIES_GROUP]),
		TuningSection.new(LICH_GROUP, [LICH_GROUP]),
		TuningSection.new(LOOT_GROUP, [LOOT_GROUP]),
		TuningSection.new(CONTROLS_GROUP, [CONTROLS_GROUP]),
		TuningSection.new(CAMERA_GROUP, [CAMERA_GROUP]),
		TuningSection.new(REST_GROUP, [REST_GROUP]),
		TuningSection.new(WORLD_GROUP, [WORLD_GROUP]),
	]


## Unknown ids fall back to the starter weapon, so a stale saved choice can't break a run.
static func weapon(tuning: Tuning, weapon_id: String) -> Weapon:
	var result := _new_weapon(weapon_id)
	_apply_knobs(result, tuning)
	return result


## The same weapon in an enemy's hands: one charge of ammo, reloading slower, and a longer, telegraphed wind-up.
static func enemy_weapon(tuning: Tuning, weapon_id: String) -> Weapon:
	var result := weapon(tuning, weapon_id)
	result.ammo = 1
	result.reload *= tuning.value(ENEMY_COOLDOWN_MULTIPLIER)
	result.windup += tuning.value(ENEMY_TELEGRAPH)
	return result


## The Lich with the tuned numbers (Tune → Lich).
static func lich(tuning: Tuning) -> Lich:
	var result := Lich.new()
	_apply_knobs(result, tuning)
	return result


## The Lich's spell rule with the tuned numbers: a new one, ready to cast.
static func lich_spells(tuning: Tuning) -> SpellPicker:
	var result := SpellPicker.new()
	tune_spells(result, tuning)
	return result


## Applies the tuned numbers to a spell rule, keeping its pause and what it is casting.
static func tune_spells(target: SpellPicker, tuning: Tuning) -> void:
	_apply_knobs(target, tuning)


## The weapon a monster fights with: the enemy version of its weapon. The Lich casts as often as his spell pause
## lets him (see SpellPicker), so his Cloud has no reload of its own.
static func monster_weapon(tuning: Tuning, monster: Monster) -> Weapon:
	var result := enemy_weapon(tuning, monster.weapon_id)
	if monster.id == Lich.ID:
		result.reload = 0.0
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


## How much enemies aim ahead of a moving player (0 = at where the player is).
static func enemy_lead_share(tuning: Tuning) -> float:
	return tuning.value(ENEMY_LEAD)


static func enemy_recover_seconds(tuning: Tuning) -> float:
	return tuning.value(ENEMY_RECOVER)


## How fast hurt monsters heal while the hero is away from their map (see Regeneration).
static func enemy_regeneration(tuning: Tuning) -> float:
	return tuning.value(ENEMY_REGENERATION)


## Applies the tuned teamwork rules (taking turns, flanking) to a room's squad.
static func tune_squad(target: Squad, tuning: Tuning) -> void:
	target.max_attackers = roundi(tuning.value(SQUAD_MAX_ATTACKERS))
	target.turn_gap_seconds = tuning.value(SQUAD_TURN_GAP)
	target.flank_spread_degrees = tuning.value(SQUAD_FLANK_SPREAD)


## Applies the tuned noticing rules (how far a calm monster notices the hero from, asleep or wandering, and how
## far noises and shouts carry).
static func tune_awareness(target: Awareness, tuning: Tuning) -> void:
	target.asleep_sight_cells = tuning.value(AWARENESS_ASLEEP_SIGHT)
	target.wander_sight_cells = tuning.value(AWARENESS_WANDER_SIGHT)
	target.noise_cells = tuning.value(AWARENESS_NOISE)
	target.shout_cells = tuning.value(AWARENESS_SHOUT)
	target.give_up_seconds = tuning.value(AWARENESS_GIVE_UP_SECONDS)
	target.give_up_cells = tuning.value(AWARENESS_GIVE_UP_CELLS)


## How long a monster stands still, showing "!", once it notices the hero.
static func enemy_noticing_seconds(tuning: Tuning) -> float:
	return tuning.value(ENEMY_NOTICING)


## A wandering monster's pace, as a share of its speed.
static func enemy_wander_speed_share(tuning: Tuning) -> float:
	return tuning.value(ENEMY_WANDER_SPEED)


## How far from home a wandering monster strolls, in cells.
static func band_wander_radius_cells(tuning: Tuning) -> float:
	return tuning.value(BAND_WANDER_RADIUS)


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


## How far a drag goes for full strength (the farthest throw), as a multiple of the button's radius.
static func drag_reach(tuning: Tuning) -> float:
	return tuning.value(CONTROLS_DRAG_REACH)


## How long the buzz lasts when an aim comes back into the dead zone, in milliseconds (0 = no buzz).
static func haptic_ms(tuning: Tuning) -> int:
	return roundi(tuning.value(CONTROLS_HAPTIC))


## Whether the HUD shows the weapon switch, a testing aid that cycles through every weapon.
static func shows_weapon_switch(tuning: Tuning) -> bool:
	return tuning.value(CONTROLS_SHOW_WEAPON_SWITCH) >= 1.0


static func camera_framing(tuning: Tuning) -> CameraFraming:
	var framing := CameraFraming.new()
	framing.pitch_degrees = tuning.value(CAMERA_PITCH)
	framing.distance = tuning.value(CAMERA_DISTANCE)
	framing.field_of_view = tuning.value(CAMERA_FIELD_OF_VIEW)
	framing.look_ahead = tuning.value(CAMERA_LOOK_AHEAD)
	return framing


static func wall_height(tuning: Tuning) -> float:
	return tuning.value(CAMERA_WALL_HEIGHT)


## How a campfire heals, burns and cools (Tune → Rest).
static func rest_profile(tuning: Tuning) -> RestProfile:
	var profile := RestProfile.campfire()
	_apply_knobs(profile, tuning)
	return profile


## How long the inn's rest takes and how close to its doorstep the hero must stand (Tune → Rest).
static func inn_profile(tuning: Tuning) -> RestProfile:
	var profile := RestProfile.inn()
	_apply_knobs(profile, tuning)
	return profile


## When resting is refused because of monsters around (Tune → Rest).
static func monsters_around(tuning: Tuning) -> MonstersAround:
	var rule := MonstersAround.new()
	_apply_knobs(rule, tuning)
	return rule


## How likely resting at a campfire is to bring an ambush, how big and how soon (Tune → Rest).
static func ambush(tuning: Tuning) -> Ambush:
	var rule := Ambush.new()
	_apply_knobs(rule, tuning)
	return rule


## What the crypt of the next world is made of (Tune → World).
static func crypt_recipe(tuning: Tuning) -> CryptRecipe:
	var recipe := CryptRecipe.new()
	_apply_knobs(recipe, tuning)
	return recipe


## What the plains of the next world are made of (Tune → World).
static func plains_recipe(tuning: Tuning) -> QuadrantRecipe:
	var recipe := QuadrantRecipe.plains()
	_apply_knobs(recipe, tuning)
	return recipe


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


## fresh: an Item, a Potion or a recipe, as built with its defaults. next_run_only: its knobs shape the next world.
static func _item_params(fresh: Object, group: String, next_run_only := false) -> Array[Tuning.Param]:
	var params: Array[Tuning.Param] = []
	for knob in fresh.knobs():
		params.append(Tuning.Param.new(
			key(fresh.id, knob.field), knob.label, group, knob.min_value, knob.max_value, knob.step,
			fresh.get(knob.field), next_run_only))
	return params


## Builds an item, potion or recipe from tuning values, keeping whole-number fields (counts, damage) whole.
static func _apply_knobs(built: Object, tuning: Tuning) -> void:
	for knob in built.knobs():
		var value := tuning.value(key(built.id, knob.field))
		built.set(knob.field, roundi(value) if built.get(knob.field) is int else value)
