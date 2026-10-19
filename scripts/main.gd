extends Node2D
## Composition root: wires the controls, the HUD and the pause menu's screens together once, then builds the
## current map of the run (a MapStage) and spawns its actors and loot, routes touch intents to the player and
## applies the room-lock, loot, stairs and rest rules. The run (Run) lives for the whole run: taking the stairs, or
## starting over, frees the map and builds the next one in the running game. Each map is made again from its
## seed on every visit; its MapRecord (what was killed, opened, taken, dropped, explored, left hurt) is applied
## on entering and written on leaving.
## The 2D world under this node runs the game; WorldView3D shows it in 3D, with the 2D plane on its floor.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
## How long the end of a run shows in the game before its summary.
const SUMMARY_DELAY_SECONDS := 1.2
## How long "down to (or up to) the next floor" shows before it is built.
const DESCEND_DELAY_SECONDS := 0.8
const LEVEL_UP_COLOR := Color(1.0, 0.85, 0.35)
## The branch's name and greeting show on arriving, then fade out.
const ARRIVAL_SECONDS := 2.5
const ARRIVAL_FADE_SECONDS := 1.0
## Where a chest's potion lands, tried in order: beside the chest, on safe floor.
const BESIDE: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
## How often line of sight is worked out again.
const SIGHT_UPDATE_SECONDS := 0.1
const TOUCH_HELP := "Left side: move.  Buttons: tap = auto-aim, drag = aim, release = fire.  Gold stairs lead down, silver ones back up.  II: menu."
## The attack button reads this, in this colour, while the hero can rest at a campfire or the inn's doorstep.
const REST_LABEL := "REST"
const REST_COLOR := Color(1.0, 0.6, 0.25)
## The skill button while no skill is held.
const EMPTY_SKILL_LABEL := "SKILL"
const EMPTY_SKILL_COLOR := Color(0.5, 0.5, 0.55)
const INN_RESTING_TEXT := "Resting..."
const INN_RESTED_TEXT := "Fully rested"
const INN_INTERRUPTED_TEXT := "Rest interrupted"
const REST_REFUSED_COLOR := Color(1.0, 0.45, 0.4)
## Floats up when a lighting brings an ambush, before the ambushers arrive.
const AMBUSH_WARNING_TEXT := "Something is coming..."
const KEYBOARD_MOUSE_HELP := "WASD: move.  Mouse: aim; click or hold: attack.  Space / Shift: dash or blink.  Right click: skill.  1-3: potions.  E: take item, or rest at a campfire or the inn.  Q: next weapon.  Esc: menu."

var _rng := RandomNumberGenerator.new()
var _settings := GameSettings.new()
var _layout: ControlLayout
var _tuning: Tuning
var _minimap := MinimapView.new()
var _big_map := MapOverlay.new()
var _arrival_fade: Tween

# The run: its world and map, and what the hero holds on this map.
var _run: Run
## False while the run is over or the hero is leaving the map: no more attacks, potions or stairs.
var _in_play := false
var _weapon_id: String
var _movement_id: String
var _skill_id: String
var _belt := PotionBelt.new()
var _experience: Experience

# The current map: built by _enter_map, freed by _leave_map.
var _stage: MapStage
## What the hero has changed on this map (kept by the run).
var _record: MapRecord
var _player: Player
var _progress: DungeonProgress
var _enemies_by_band := {}  # int -> Array[Enemy]: each band (a camp round its campfire, or a room's monsters)
var _squads_by_band := {}  # int -> Squad: each band fights as a team
var _spawn_cells := {}  # Enemy -> its spawn cell, which is how the record knows it
## The band of each trap room the hero hasn't sprung (room -> its monsters' spawn cells): not in the world yet.
var _hidden_trap_band := {}
var _trap_chests := {}  # int (trap room) -> its Chest
## Who hears the hero's noise and a monster's shout (see Awareness); tuned like each enemy's own.
var _hearing := Awareness.new()
var _floor_loot_cells := {}  # PickupArea -> its loot cell, for the floor items not taken yet
## The stairs the hero arrived on: they only lead on once the hero has stepped off them.
var _arrival_cell := DungeonMap.NO_CELL
var _lava := LavaBurn.new()
var _rest_spots := {}  # Vector2i (its cell) -> RestSpot: the map's campfires as the record has them
## The campfires a band still holds (they burn for it and can't be rested at), until its last monster dies.
var _held_campfires := {}  # Vector2i -> true
var _rest_profile := RestProfile.campfire()
var _ambush := Ambush.new()
## Ambushes on their way (hit by a lighting, not arrived yet), and the monsters that arrived in one. Ambushers
## belong to no spawn cell, so the record never holds them: they are not saved, and the lighting's spent roll is
## all that keeps another ambush from coming for it.
var _ambush_parties: Array[AmbushParty] = []
var _ambushers := {}  # Enemy -> true
var _inn: InnSpot  # the inn's doorstep, or null (only the plains have a village)
var _inn_in_reach := false
var _monsters_around := MonstersAround.new()
## The campfire no band holds within the hero's reach (whatever its state), or DungeonMap.NO_CELL.
var _fire_in_reach := DungeonMap.NO_CELL
## The attack button reads REST (see RestOffer).
var _rest_offer := false
var _sight_update_left := 0.0
## Where the player last looked from; sight is only worked out again when this or a door changes.
var _sight_origin := DungeonMap.NO_CELL
## The fog, minimap and 3D view show this map's exploration as a whole: from then on a step only redraws the
## cells it changed.
var _sight_drawn := false
## The name of the place the banner last showed ("The village", "The plains"...), to notice crossing a gate.
var _shown_place := ""
var _offered_drop: ItemDrop  ## The dropped item the player is standing on, if any.
## How long the mouse button has been held on a weapon that charges.
var _mouse_held_seconds := 0.0

@onready var _hud_layer: CanvasLayer = $Hud
@onready var _hud: Label = $Hud/Status
@onready var _help: Label = $Hud/Help
@onready var _map_toggle: Button = $Hud/MapToggle
@onready var _weapon_switch: Button = $Hud/WeaponSwitch
@onready var _loot_card: LootCard = $Hud/LootCard
@onready var _potion_bar: PotionBar = $Hud/PotionBar
@onready var _arrival: Label = $Hud/Arrival
@onready var _touch_controls: TouchControls = $TouchControls
@onready var _move_stick: TouchStick = $TouchControls/MoveStick
@onready var _attack_button: AimButton = $TouchControls/AttackButton
@onready var _movement_button: AimButton = $TouchControls/MovementButton
@onready var _skill_button: AimButton = $TouchControls/SkillButton
@onready var _keyboard_mouse: KeyboardMouseControls = $KeyboardMouse
@onready var _pause_menu: PauseMenu = $Overlay/PauseMenu
@onready var _layout_editor: LayoutEditor = $Overlay/LayoutEditor
@onready var _tuning_panel: TuningPanel = $Overlay/TuningPanel
@onready var _credits_panel: CreditsPanel = $Overlay/CreditsPanel
@onready var _run_summary: RunSummaryPanel = $Overlay/RunSummary


func _ready() -> void:
	_rng.randomize()
	_tuning = _settings.load_tuning()
	_layout = _settings.load_layout()
	_hud_layer.add_child(_minimap)
	_minimap.visible = _settings.load_minimap_shown()
	$Overlay.add_child(_big_map)
	_belt.changed.connect(_refresh_potions)
	_connect_controls()
	_connect_keyboard_mouse()
	_connect_menu()
	_touch_controls.apply_layout(_layout)
	_start_run(Run.random(_rng, GameTuning.plains_recipe(_tuning), GameTuning.crypt_recipe(_tuning)))
	_show_input_mode(_keyboard_mouse.mode)


func _physics_process(delta: float) -> void:
	_run.advance(delta)
	_update_rest_offer()
	_tick_ambushes(delta)
	_player.move(_move_input())
	var mouse_held := _keyboard_mouse.is_attack_held() and _in_play
	if mouse_held and _player.weapon.charge_seconds() > 0.0:
		_mouse_held_seconds += delta
		_charge_toward_cursor()
	elif mouse_held:
		_attack_toward_cursor()
	else:
		_mouse_held_seconds = 0.0
	_update_charging()
	_apply_terrain(delta)
	for squad: Squad in _squads_by_band.values():
		squad.tick(delta)
	_sight_update_left -= delta
	if _sight_update_left <= 0.0:
		_sight_update_left = SIGHT_UPDATE_SECONDS
		_update_sight()
	_attack_button.set_cooldown_ratio(_player.attack_cooldown_ratio())
	_movement_button.set_cooldown_ratio(_player.utility_cooldown_ratio(Utility.Slot.MOVEMENT))
	_skill_button.set_cooldown_ratio(_player.utility_cooldown_ratio(Utility.Slot.SKILL))
	_track_player_room()
	_track_place()


# --- Building and leaving a map -----------------------------------------------------------------

## Starts a run on its first map, with the hero it holds.
func _start_run(run: Run) -> void:
	_run = run
	_enter_map()


## Builds the run's current map, replays its record (so it is as the hero left it) and puts the hero on their
## arrival spot, carrying what they hold (Run.hero).
func _enter_map() -> void:
	var hero := _run.hero
	_weapon_id = hero.weapon_id
	_movement_id = hero.movement_id
	_skill_id = hero.skill_id
	_experience = Experience.new(hero.experience)
	_belt.load_dict(hero.potions)
	_stage = MapStage.new(_run.current_map())
	_record = _run.record_of(_stage.spec.id)
	add_child(_stage)
	move_child(_stage, 0)
	_pause_menu.show_seed(_run.world_seed, _stage.spec)
	_stage.exploration.restore(_record.explored_cells())
	_arrival_cell = WorldLayout.arrival_cell(_stage.map, _run.arrival_spot)
	_player = _spawn_player(hero, _arrival_cell)
	_spawn_enemies()
	_spawn_ruin_chest()
	_spawn_campfires()
	_spawn_inn()
	_spawn_floor_loot()
	_spawn_dropped_items()
	_update_sight()
	_progress = _create_progress()
	_spawn_trap_chests()
	_apply_tuning(_tuning)
	_in_play = true
	_refresh_hud()
	_greet()


## Writes down what changed on the map, then frees it and everything on it (actors, loot, attacks in flight).
func _leave_map() -> void:
	_close_offer()
	_write_record()
	remove_child(_stage)
	_stage.queue_free()
	_stage = null
	_record = null
	_player = null
	_enemies_by_band.clear()
	_squads_by_band.clear()
	_spawn_cells.clear()
	_hidden_trap_band.clear()
	_trap_chests.clear()
	_floor_loot_cells.clear()
	_rest_spots.clear()
	_held_campfires.clear()
	_ambush_parties.clear()
	_ambushers.clear()
	_fire_in_reach = DungeonMap.NO_CELL
	_inn = null
	_inn_in_reach = false
	_rest_offer = false
	_lava = LavaBurn.new()
	_sight_origin = DungeonMap.NO_CELL
	_sight_drawn = false
	_sight_update_left = 0.0
	_mouse_held_seconds = 0.0


## What changed on this map, kept by the run for the next visit: what the hero has seen, what lies on the floor
## that the map didn't start with, and the monsters left hurt (kills, opened chests and taken floor items are
## written as they happen).
func _write_record() -> void:
	_record.remember_explored(_stage.exploration.seen_cells())
	_record.remember_dropped(_dropped_items())
	var hurt := {}
	for enemy: Enemy in _spawn_cells:
		if enemy.health.current < enemy.health.maximum:
			hurt[_spawn_cells[enemy]] = enemy.health.current
	_record.remember_hurt(hurt, _run.seconds_played)
	for cell: Vector2i in _rest_spots:
		_record.remember_campfire(cell, _rest_spots[cell].fire)


## Gear and potions on the floor, other than the floor items still where the map put them.
func _dropped_items() -> Array[MapRecord.DroppedItem]:
	var items: Array[MapRecord.DroppedItem] = []
	for node in _stage.get_children():
		if node.is_queued_for_deletion() or _floor_loot_cells.has(node):
			continue
		if node is ItemDrop:
			items.append(MapRecord.DroppedItem.new(node.item.id, false, node.position))
		elif node is PotionDrop:
			items.append(MapRecord.DroppedItem.new(node.potion.id, true, node.position))
	return items


func _spawn_player(hero: HeroState, cell: Vector2i) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.health = Health.restored(hero.max_health, hero.health)
	player.position = DungeonView.cell_center(cell)
	player.attack_fired.connect(_spawn_attacks.bind(player))
	player.attack_fired.connect(func(_attacks: Array) -> void: _make_noise(player.global_position))
	player.health_changed.connect(func(_current: int, _maximum: int) -> void: _refresh_hud())
	player.died.connect(func() -> void: _end_run(RunSummary.Ending.DIED))
	player.blink_landing = _blink_landing
	_stage.add_actor(player)
	_stage.world.add_player(player)
	return player


## The map's monsters, but for those killed on an earlier visit; the ones left hurt have healed for the time the
## hero was away. The monsters of a camp are a band whose home is its campfire; any others are a band per room,
## living at its middle. Each band starts asleep or wandering (the same for the same map), until one of them
## notices the hero.
func _spawn_enemies() -> void:
	for cell in _stage.map.enemy_spawns:
		if _record.is_killed(cell):
			continue
		var room := _stage.map.room_at(cell)
		if _stage.map.locking_kind(room) == LockingRoom.Kind.TRAP:
			_hidden_trap_band.get_or_add(room, []).append(cell)  # unseen until the room seals (_on_room_locked)
			continue
		_spawn_enemy(cell)


## One monster of the map at its spawn cell, as its band has it.
func _spawn_enemy(cell: Vector2i) -> void:
	var band := Band.home_of(_stage.map, cell, _stage.spec.room_wandering_share(), _camp_wandering_share())
	var locking := _stage.map.locking_kind(_stage.map.room_at(cell)) != LockingRoom.NONE
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = DungeonView.cell_center(cell)
	var monster := Bestiary.by_id(_stage.map.monster_at(cell))
	if monster.id == Lich.ID:
		monster = GameTuning.lich(_tuning).monster()
		enemy.spell_picker = GameTuning.lich_spells(_tuning)
		enemy.spell_weapons = GameTuning.lich_spell_weapons(_tuning)
	enemy.become(monster, GameTuning.enemy_health_multiplier(_tuning))
	enemy.set_current_health(_record.health_on_return(
		cell, enemy.health.maximum, _run.seconds_played, GameTuning.enemy_regeneration(_tuning)))
	enemy.arm(GameTuning.monster_weapon(_tuning, monster))
	enemy.navigation = _stage.pathfinder
	enemy.squad = _squads_by_band.get_or_add(band.id, Squad.new())
	enemy.settle(
		DungeonView.cell_center(band.cell),
		Band.start_of(_stage.spec.seed_value, band.id, band.wandering_share, locking))
	# The band of a locking room is awake but ignores the hero until the room locks (see _on_room_locked), and
	# keeps to its room meanwhile: strolling out through a door, it would be shut out when the room locks.
	if locking:
		enemy.wander_cells = _cell_set(_stage.map.cells_of_room(_stage.map.room_at(cell)))
		# Hurt before the lock, the Lich withdraws to where no doorway can see him: the hero has to walk in.
		if _stage.map.locking_kind(_stage.map.room_at(cell)) == LockingRoom.Kind.ARENA:
			enemy.retreat_to(DungeonView.cell_center(Hideout.cell_for(_stage.map, cell, _stage.pathfinder)))
	else:
		enemy.chase(_player)
	enemy.attack_fired.connect(_spawn_attacks.bind(enemy))
	enemy.noticed.connect(_on_enemy_noticed)
	enemy.defeated.connect(_on_enemy_defeated.bind(band.id))
	_stage.add_actor(enemy)
	_stage.world.add_enemy(enemy)
	enemy.never_gives_up = locking
	_tune_enemy(enemy, _tuning)  # a trap room's band joins after the map's tuning was applied
	GameTuning.tune_squad(enemy.squad, _tuning)
	_enemies_by_band.get_or_add(band.id, []).append(enemy)
	_spawn_cells[enemy] = cell


## A set of cells (cell -> true), for Enemy.wander_cells.
static func _cell_set(cells: Array[Vector2i]) -> Dictionary:
	var result := {}
	for cell in cells:
		result[cell] = true
	return result


## The map's campfires as the record has them (unlit if never lit), and which a band still holds.
func _spawn_campfires() -> void:
	_rest_profile = GameTuning.rest_profile(_tuning)
	for cell in _stage.map.campfire_cells:
		var spot := RestSpot.new(_record.campfire_at(cell, _rest_profile), DungeonView.cell_center(cell))
		spot.attend(_player)
		_stage.add_child(spot)
		_rest_spots[cell] = spot
	_refresh_held_campfires()


## The inn's rest at its doorstep, if the map has a village with an inn.
func _spawn_inn() -> void:
	var village := _stage.map.village
	if village == null or village.inn_doorstep == DungeonMap.NO_CELL:
		return
	_inn = InnSpot.new(InnRest.new(GameTuning.inn_profile(_tuning)), DungeonView.cell_center(village.inn_doorstep))
	_inn.attend(_player)
	_inn.rest_ended.connect(_on_inn_rest_ended)
	_stage.add_child(_inn)


func _refresh_held_campfires() -> void:
	_held_campfires.clear()
	for cell in _rest_spots:
		if Camps.is_held(_stage.map, cell, _record):
			_held_campfires[cell] = true


## The share of camps that start wandering: the quadrant recipe's (a crypt level has no camps, only rooms).
func _camp_wandering_share() -> float:
	var quadrant := _stage.spec.quadrant
	return quadrant.camp_wandering_share() if quadrant != null else _stage.spec.room_wandering_share()


## Things lying around from the start (vault treasure, dead-end finds), but for those taken on an earlier
## visit: potions or gear, the same for the same map (see LootTable.floor_find).
func _spawn_floor_loot() -> void:
	for cell in _stage.map.loot_cells:
		if _record.is_loot_taken(cell):
			continue
		var at := DungeonView.cell_center(cell)
		var find := LootTable.floor_find(
			_stage.spec.seed_value, cell, GameTuning.item_ids(), GameTuning.potion_weights())
		var drop: PickupArea = _spawn_potion(at, find.item_id) if find.is_potion else _spawn_drop(at, find.item_id)
		_floor_loot_cells[drop] = cell


## What lay on the floor when the hero last left (swapped-out gear, unclaimed finds and drops).
func _spawn_dropped_items() -> void:
	for item in _record.dropped_items():
		if item.is_potion:
			_spawn_potion(item.position, item.item_id)
		else:
			_spawn_drop(item.position, item.item_id)


func _create_progress() -> DungeonProgress:
	var counts := {}
	var cells: Array = _spawn_cells.values()
	for band_cells: Array in _hidden_trap_band.values():
		cells.append_array(band_cells)
	for cell: Vector2i in cells:
		var room := _stage.map.room_at(cell)
		counts[room] = counts.get(room, 0) + 1
	# Only the rooms the map marks lock (the boss arena, trap rooms): in the others monsters come when they notice.
	var progress := DungeonProgress.new(counts, _stage.map.locking_room_ids())
	progress.room_locked.connect(_on_room_locked)
	progress.room_cleared.connect(_on_room_cleared)
	return progress


func _connect_controls() -> void:
	_attack_button.aim_changed.connect(
		func(direction: Vector2, strength: float) -> void:
			if not _rest_offer:
				_player.preview_aim(direction, _player.weapon.aim_shape(), strength))
	_attack_button.aim_released.connect(_on_attack_released)
	_weapon_switch.pressed.connect(_on_weapon_switch_pressed)
	_attack_button.returned_to_dead_zone.connect(_buzz)
	for slot: Utility.Slot in _utility_buttons():
		var button: AimButton = _utility_buttons()[slot]
		button.aim_changed.connect(
			func(direction: Vector2, strength: float) -> void: _player.preview_utility(slot, direction, strength))
		button.aim_released.connect(_on_utility_released.bind(slot))
		button.returned_to_dead_zone.connect(_buzz)
	_loot_card.take_pressed.connect(_on_take_pressed)
	_loot_card.leave_pressed.connect(_close_offer)
	_potion_bar.drink_requested.connect(_drink)
	_map_toggle.pressed.connect(_toggle_minimap)
	_minimap.pressed.connect(_open_big_map)
	_touch_controls.keep_touches_for([_minimap, _map_toggle])
	_big_map.closed.connect(func() -> void: get_tree().paused = false)


func _connect_keyboard_mouse() -> void:
	_keyboard_mouse.mode_changed.connect(_show_input_mode)
	_keyboard_mouse.attack_held_changed.connect(func(held: bool) -> void:
		if not held:
			_player.preview_aim(Vector2.ZERO))
	_keyboard_mouse.attack_released.connect(_release_charged_attack)
	_keyboard_mouse.movement_requested.connect(_use_utility_toward_cursor.bind(Utility.Slot.MOVEMENT))
	_keyboard_mouse.skill_requested.connect(_use_utility_toward_cursor.bind(Utility.Slot.SKILL))
	_keyboard_mouse.potion_requested.connect(func(slot: int) -> void: _drink(GameTuning.potion_ids()[slot]))
	_keyboard_mouse.take_requested.connect(_on_interact_pressed)
	_keyboard_mouse.weapon_switch_requested.connect(_on_weapon_switch_pressed)
	_keyboard_mouse.minimap_toggle_requested.connect(_toggle_minimap)


func _connect_menu() -> void:
	_pause_menu.opened.connect(func() -> void: get_tree().paused = true)
	_pause_menu.closed.connect(func() -> void: get_tree().paused = false)
	_pause_menu.restart_requested.connect(_restart)
	_pause_menu.customize_requested.connect(_on_customize_requested)
	_layout_editor.layout_changed.connect(_touch_controls.apply_layout)
	_layout_editor.finished.connect(_on_layout_finished)
	_pause_menu.tuning_requested.connect(_on_tuning_requested)
	_tuning_panel.tuning_changed.connect(_apply_tuning)
	_tuning_panel.finished.connect(_on_tuning_finished)
	_tuning_panel.new_world_requested.connect(_restart)
	_tuning_panel.same_seed_requested.connect(_restart_with_same_seed)
	_tuning_panel.warp_requested.connect(_warp_to)
	_pause_menu.credits_requested.connect(_on_credits_requested)
	_credits_panel.finished.connect(_on_credits_finished)
	_run_summary.play_again_pressed.connect(_restart)
	_run_summary.keep_playing_pressed.connect(_keep_playing)


# --- Input routing -------------------------------------------------------------------------------

## Touch stick first; the movement keys otherwise.
func _move_input() -> Vector2:
	var touch := _move_stick.current_strength()
	if touch != Vector2.ZERO:
		return touch
	return _keyboard_mouse.move_strength()


## The touch controls show only while playing by touch; with keyboard and mouse the HUD names the keys.
func _show_input_mode(mode: InputMode.Kind) -> void:
	var touch := mode == InputMode.Kind.TOUCH
	_touch_controls.use_touch(touch)
	_help.text = TOUCH_HELP if touch else KEYBOARD_MOUSE_HELP
	_player.preview_aim(Vector2.ZERO)
	_refresh_potions()


## While the mouse button is held, the attack follows the cursor and fires whenever the weapon is ready.
func _attack_toward_cursor() -> void:
	var aim := MouseAim.toward(_player.global_position, _cursor_on_plane(), _player.weapon, _player.facing)
	_player.preview_aim(aim.direction, _player.weapon.aim_shape(), aim.strength)
	_player.attack(aim.direction, null, aim.strength)


## A weapon that charges is drawn while the mouse button is held, and shoots when it is let go.
func _charge_toward_cursor() -> void:
	var aim := MouseAim.toward(_player.global_position, _cursor_on_plane(), _player.weapon, _player.facing)
	_player.preview_aim(aim.direction, _player.weapon.aim_shape(), aim.strength)
	_player.preview_charge(Charge.ratio(_mouse_held_seconds, _player.weapon.charge_seconds()))


func _release_charged_attack() -> void:
	var held := _mouse_held_seconds
	_mouse_held_seconds = 0.0
	_player.preview_aim(Vector2.ZERO)
	if not _in_play or _player.weapon.charge_seconds() <= 0.0:
		return
	var aim := MouseAim.toward(_player.global_position, _cursor_on_plane(), _player.weapon, _player.facing)
	_player.attack(aim.direction, null, aim.strength, held)


## The hero is slower while drawing a weapon that charges, by touch or mouse.
func _update_charging() -> void:
	var weapon := _player.weapon
	if weapon.charge_seconds() <= 0.0:
		_player.charging = false
		return
	_player.charging = (_attack_button.is_held() and not _rest_offer) or _mouse_held_seconds > 0.0
	if _attack_button.is_held() and not _rest_offer:
		_player.preview_charge(Charge.ratio(_attack_button.held_seconds(), weapon.charge_seconds()))


## A blink lands on the cursor, as far as it reaches; the other utilities only go its way.
func _use_utility_toward_cursor(slot: Utility.Slot) -> void:
	var used := _player.utility_in(slot)
	if not _in_play or used == null:
		return
	var aim := MouseAim.toward(_player.global_position, _cursor_on_plane(), used, _player.facing)
	_player.use_utility(slot, aim.direction, aim.strength)


func _cursor_on_plane() -> Vector2:
	return _stage.world.plane_point_at(_keyboard_mouse.cursor())


func _on_attack_released(release: AimGesture.Release) -> void:
	_player.preview_aim(Vector2.ZERO)
	if release.is_cancelled:
		return
	if _rest_offer:
		_rest()
		return
	if not release.is_auto:
		_player.attack(release.direction, null, release.strength, release.held_seconds)
		return
	var target := _auto_aim_target()
	if target == null:
		_player.attack(_player.facing, null, 1.0, release.held_seconds)
	else:
		_player.attack(
			_player.global_position.direction_to(target.global_position), target, 1.0, release.held_seconds)


## Like Brawl Stars, a short buzz tells the thumb its aim came back into the dead zone, where letting go cancels
## (phones that support it).
func _buzz() -> void:
	var milliseconds := GameTuning.haptic_ms(_tuning)
	if milliseconds > 0:
		Input.vibrate_handheld(milliseconds)


## A tap goes the way the hero faces, as far as it reaches; a drag goes where it was dragged.
func _on_utility_released(release: AimGesture.Release, slot: Utility.Slot) -> void:
	_player.preview_aim(Vector2.ZERO)
	if release.is_cancelled:
		return
	if release.is_auto:
		_player.use_utility(slot, _player.facing)
	else:
		_player.use_utility(slot, release.direction, release.strength)


## A blink stops at walls and closed doors and lands only where the hero can stand (see BlinkLanding).
func _blink_landing(from: Vector2, to: Vector2) -> Vector2:
	return BlinkLanding.find(from, to, _stage.map, _stage.view.is_door_closed, Player.RADIUS)


func _utility_buttons() -> Dictionary:
	return {Utility.Slot.MOVEMENT: _movement_button, Utility.Slot.SKILL: _skill_button}


## Closest enemy the hero can see, at any distance. Null if none.
func _auto_aim_target() -> Enemy:
	var enemies: Array[Enemy] = []
	var positions: Array[Vector2] = []
	for band: Array in _enemies_by_band.values():
		for enemy: Enemy in band:
			if _stage.exploration.is_visible(DungeonView.world_to_cell(enemy.global_position)):
				enemies.append(enemy)
				positions.append(enemy.global_position)
	var nearest := AutoAim.nearest_index(_player.global_position, positions, INF)
	return null if nearest == AutoAim.NO_TARGET else enemies[nearest]


# --- Rooms and combat ----------------------------------------------------------------------------

## Lock a (locking) room only once the player is a full tile past its doorway, so a closing door can't trap them in it.
## Stepping on the stairs down leads down when WorldLayout.stairs_down_open says so (the crypt entrance always, a crypt
## level's once their room is clear); the stairs up always lead up. The stairs the hero arrived on only lead on once
## stepped off.
func _track_player_room() -> void:
	var cell := DungeonView.world_to_cell(_player.global_position)
	if _stage.map.is_clear_of_doors(cell):
		_progress.enter_room(_stage.map.room_at(cell))
	if cell == _arrival_cell:
		return
	_arrival_cell = DungeonMap.NO_CELL
	var exit := WorldLayout.exit_at(_stage.map, cell)
	if exit == WorldLayout.Exit.STAIRS_UP \
			or (exit == WorldLayout.Exit.STAIRS_DOWN
				and WorldLayout.stairs_down_open(_stage.spec.id, _progress.is_cleared(_stage.map.room_at(cell)))):
		_take_stairs(exit)


## A locking room seals with the hero in it, and its band, which ignored the hero until now, wakes and attacks.
func _on_room_locked(room: int) -> void:
	_stage.view.set_room_closed(room, true)
	_stage.world.set_doors_closed(_stage.map.doors_of_room(room), true)
	_sight_origin = DungeonMap.NO_CELL
	for cell: Vector2i in _hidden_trap_band.get(room, []):
		_spawn_enemy(cell)
	_hidden_trap_band.erase(room)
	for enemy: Enemy in _spawn_cells:
		if _stage.map.room_at(_spawn_cells[enemy]) == room:
			enemy.wake(_player)


func _on_room_cleared(room: int) -> void:
	if _trap_chests.has(room):
		_trap_chests[room].unlock()
	_stage.view.set_room_closed(room, false)
	_stage.world.set_doors_closed(_stage.map.doors_of_room(room), false)
	_sight_origin = DungeonMap.NO_CELL


## A monster that notices the hero shouts, waking the rest of its band and whoever else hears it (see Awareness).
## Each one woken notices in turn and shouts too; a monster that is already awake is not woken again, so the
## chain ends.
func _on_enemy_noticed(noticer: Enemy) -> void:
	var listeners: Array[Enemy] = []
	var bands := PackedInt32Array()  # each listener's band
	for band: int in _enemies_by_band:
		for enemy: Enemy in _enemies_by_band[band]:
			listeners.append(enemy)
			bands.append(band)
	var shouter := listeners.find(noticer)
	if shouter == -1:
		return
	for index in _hearing.shout_hearers(shouter, _cells_of(listeners), bands):
		listeners[index].alert()


## The hero's attack or a blast makes noise at a point (world position), waking monsters that hear it.
func _make_noise(at: Vector2) -> void:
	var listeners := _all_enemies()
	for index in _hearing.noise_hearers(at / DungeonView.TILE_SIZE, _cells_of(listeners)):
		listeners[index].alert()


func _all_enemies() -> Array[Enemy]:
	var all: Array[Enemy] = []
	for enemies: Array in _enemies_by_band.values():
		all.append_array(enemies)
	return all


## Where the enemies are, in cells.
func _cells_of(enemies: Array[Enemy]) -> PackedVector2Array:
	var cells := PackedVector2Array()
	for enemy in enemies:
		cells.append(enemy.global_position / DungeonView.TILE_SIZE)
	return cells


func _on_enemy_defeated(enemy: Enemy, band: int) -> void:
	_enemies_by_band[band].erase(enemy)
	if _ambushers.has(enemy):
		_ambushers.erase(enemy)  # not a spawn of the map: nothing to record, no room to clear
	else:
		var spawn_cell: Vector2i = _spawn_cells[enemy]
		_record.kill(spawn_cell)
		_refresh_held_campfires()
		_spawn_cells.erase(enemy)
		_progress.record_defeat(_stage.map.room_at(spawn_cell))
	_run.hero.kills += 1
	_grow_from(enemy.monster)
	_refresh_hud()
	if enemy.monster.id == Lich.ID:
		_run.lich_killed()
		_win()
	if LootTable.rolls_enemy_drop(GameTuning.enemy_drop_chance(_tuning), _rng):
		var drop_id := LootTable.enemy_drop_id(enemy.weapon.id, GameTuning.item_ids(), _held_ids(), _rng)
		_spawn_drop(enemy.position, drop_id)
	elif LootTable.rolls(GameTuning.potion_drop_chance(_tuning), _rng):
		_spawn_potion(enemy.position, LootTable.pick_potion_id(GameTuning.potion_weights(), _rng))


## Carries out the Shots, Slashes and Novas of one attack, by the player or an enemy (the swing follows its
## swinger).
func _spawn_attacks(attacks: Array, attacker: Node2D) -> void:
	for attack: Variant in attacks:
		if attack is Shot and attack.delay > 0.0:
			var from_attacker: Vector2 = attack.origin - attacker.global_position
			get_tree().create_timer(attack.delay, false, true).timeout.connect(_follow_up.bind(attack, attacker, from_attacker))
		elif attack is Shot:
			_launch(attack)
		elif attack is Slash:
			_stage.add_effect(SlashEffect.new(attack, attacker))
		elif attack is Nova:
			_stage.add_effect(NovaEffect.new(attack))


func _launch(shot: Shot) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(shot)
	projectile.exploded.connect(_make_noise)
	_stage.add_effect(projectile)
	_stage.world.add_projectile(projectile)


## A delayed shot (a flurry's later punch, a later wave of Bone Spray) sets off from where its attacker stands now,
## the same distance out as it was meant to start, if the attacker is still standing.
func _follow_up(shot: Shot, attacker: Node2D, from_attacker: Vector2) -> void:
	if not is_instance_valid(attacker) or not attacker.is_physics_processing():
		return
	shot.origin = attacker.global_position + from_attacker
	_launch(shot)


## Fog of war: the player sees through open floor, water and lava, not walls or closed doors. Enemies out of
## sight are hidden; the map they have seen stays drawn, dimmed, with the items seen on it (like Dungeon
## Crawl's map memory). Items not seen yet are hidden.
func _update_sight() -> void:
	var origin := DungeonView.world_to_cell(_player.global_position)
	if origin != _sight_origin:
		_sight_origin = origin
		var is_clear := func(cell: Vector2i) -> bool: return _stage.map.is_see_through(cell) and not _stage.view.is_door_closed(cell)
		_stage.exploration.look_from(origin, is_clear)
		_show_sight(origin)
	for enemies: Array in _enemies_by_band.values():
		for enemy: Enemy in enemies:
			enemy.visible = _stage.exploration.is_visible(DungeonView.world_to_cell(enemy.global_position))
	for pickup: PickupArea in get_tree().get_nodes_in_group(PickupArea.GROUP):
		pickup.visible = _stage.exploration.is_seen(DungeonView.world_to_cell(pickup.global_position))


## The first look at a map draws all of it (what was remembered from earlier visits too); later ones only what
## they changed (see Exploration.changed_cells).
func _show_sight(origin: Vector2i) -> void:
	if _sight_drawn:
		_stage.fog.show_changes(_stage.exploration)
		_stage.world.show_changes(_stage.exploration)
		_minimap.show_changes(_stage.map, _stage.exploration, origin)
		return
	_stage.fog.show_exploration(_stage.exploration)
	_stage.world.show_exploration(_stage.exploration)
	_minimap.show_map(_stage.map, _stage.exploration, origin)
	_sight_drawn = true


## Shows or hides the minimap, and remembers the choice for the next floor and the next run.
func _toggle_minimap() -> void:
	_minimap.visible = not _minimap.visible
	_warn_if_failed(_settings.save_minimap_shown(_minimap.visible), "the minimap setting")


## The whole map fills the screen and the game waits until it is closed.
func _open_big_map() -> void:
	if not _in_play:
		return
	get_tree().paused = true
	_big_map.open(_stage.map, _stage.exploration, DungeonView.world_to_cell(_player.global_position))


## Lava burns whoever stands in it; shallow water slows whoever wades through it.
func _apply_terrain(delta: float) -> void:
	_burn(_player, delta)
	_player.ground_speed = _stage.map.ground_speed(DungeonView.world_to_cell(_player.global_position))
	for enemies: Array in _enemies_by_band.values():
		for enemy: Enemy in enemies:
			_burn(enemy, delta)
			enemy.ground_speed = _stage.map.ground_speed(DungeonView.world_to_cell(enemy.global_position))


func _burn(actor: Node2D, delta: float) -> void:
	var cell := DungeonView.world_to_cell(actor.global_position)
	var in_lava := _stage.map.terrain_at(cell) == DungeonMap.Terrain.LAVA
	var damage := _lava.damage_due(actor.get_instance_id(), in_lava, delta)
	if damage > 0:
		actor.take_damage(damage, "lava")


# --- Resting --------------------------------------------------------------------------------------

## The campfires' models follow their state; the campfire within the hero's reach is noted, and the attack button
## reads REST while it can be lit and no monster hunts the hero (see RestOffer). (Time moves on for the campfires
## in their RestSpots, only while the hero is on the map.)
func _update_rest_offer() -> void:
	_fire_in_reach = DungeonMap.NO_CELL
	for cell: Vector2i in _rest_spots:
		var spot: RestSpot = _rest_spots[cell]
		_stage.world.show_campfire(cell, spot.fire.state, spot.fire.seconds_left(), _held_campfires.has(cell))
		if _in_play and _fire_in_reach == DungeonMap.NO_CELL and not _held_campfires.has(cell) \
				and spot.fire.profile.is_within_reach(spot.hero_cells()):
			_fire_in_reach = cell
	_inn_in_reach = _in_play and _inn != null and _inn.is_within_reach()
	var in_reach := _fire_in_reach != DungeonMap.NO_CELL or _inn_in_reach
	var usable: bool = _inn_in_reach or (in_reach and _rest_spots[_fire_in_reach].fire.can_light())
	# The monsters are only looked over when it could matter.
	var verdict: MonstersAround.Verdict = \
			_monsters_around.check(_monsters_near_hero()) if usable else MonstersAround.Verdict.CALM
	var offer := RestOffer.shows_rest(usable, in_reach, verdict)
	if offer != _rest_offer:
		_rest_offer = offer
		_show_attack_button()


## E: takes the item on offer, or else rests.
func _on_interact_pressed() -> void:
	if _offered_drop != null:
		_on_take_pressed()
	else:
		_rest()


## Lights the campfire within reach, or rests at the inn on its doorstep, unless monsters around forbid it or the
## fire is still in embers (then says so).
func _rest() -> void:
	if not _in_play:
		return
	if _fire_in_reach == DungeonMap.NO_CELL:
		if _inn_in_reach:
			_rest_at_inn()
		return
	var spot: RestSpot = _rest_spots[_fire_in_reach]
	var refusal := RestOffer.refusal(spot.fire, _monsters_around.check(_monsters_near_hero()))
	if refusal != "":
		_stage.world.float_text(_player.global_position, refusal, REST_REFUSED_COLOR)
		return
	if spot.rest():
		_roll_ambush(_fire_in_reach)


## Each lighting of a campfire makes one seeded ambush roll (see Ambush); a spent roll stays in the record. On a hit
## the ambushers are on their way: they arrive after the rule's delay.
func _roll_ambush(fire: Vector2i) -> void:
	var lighting := _record.spend_lighting(fire)
	var seed_value := _stage.spec.seed_value
	var outdoors := _stage.spec.branch().outdoors
	if not _ambush.hits(seed_value, fire, lighting, outdoors):
		return
	var cells := AmbushPlacement.cells(
		_stage.map, fire, _rest_profile.light_radius_cells, _ambush.margin_cells, _ambush.size,
		Ambush.placement_rng(seed_value, fire, lighting))
	if cells.is_empty():
		return  # no ground outside the light for anyone to come from: no warning for nobody
	var crew := _ambush.crew(_stage.map, fire, seed_value, lighting)
	crew.resize(cells.size())
	_ambush_parties.append(AmbushParty.new(crew, cells, _ambush.delay_seconds, fire))
	_stage.world.float_text(_player.global_position, AMBUSH_WARNING_TEXT, REST_REFUSED_COLOR)


## Moves the ambushes on their way on; the ones that are due arrive.
func _tick_ambushes(delta: float) -> void:
	if not _in_play:
		return
	for party in _ambush_parties.duplicate():
		if party.tick(delta):
			_ambush_parties.erase(party)
			_spawn_ambushers(party)


## The ambushers appear at the edge of the light, already hunting the hero. They are a band of their own at the
## campfire, fight as a squad and can give up like any hunter, but are never recorded as the map's monsters.
func _spawn_ambushers(party: AmbushParty) -> void:
	var band := Ambush.band_id(_stage.map, party.fire)
	for index in party.cells.size():
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.position = DungeonView.cell_center(party.cells[index])
		var monster := Bestiary.by_id(party.monster_ids[index])
		enemy.become(monster, GameTuning.enemy_health_multiplier(_tuning))
		enemy.arm(GameTuning.monster_weapon(_tuning, monster))
		enemy.navigation = _stage.pathfinder
		var squad: Squad = _squads_by_band.get_or_add(band, Squad.new())
		GameTuning.tune_squad(squad, _tuning)
		enemy.squad = squad
		_tune_enemy(enemy, _tuning)
		enemy.ambush(_player, DungeonView.cell_center(party.fire))
		enemy.attack_fired.connect(_spawn_attacks.bind(enemy))
		enemy.noticed.connect(_on_enemy_noticed)
		enemy.defeated.connect(_on_enemy_defeated.bind(band))
		_stage.add_actor(enemy)
		_stage.world.add_enemy(enemy)
		_enemies_by_band.get_or_add(band, []).append(enemy)
		_ambushers[enemy] = true


## Sits down at the inn: a 3 s rest that moving or a hit cancels (see InnRest). Nothing happens while already resting.
func _rest_at_inn() -> void:
	if _inn.rest.is_resting():
		return
	var refusal := RestOffer.inn_refusal(_monsters_around.check(_monsters_near_hero()))
	if refusal != "":
		_stage.world.float_text(_player.global_position, refusal, REST_REFUSED_COLOR)
		return
	_inn.rest.begin()
	_stage.world.float_text(_player.global_position, INN_RESTING_TEXT, REST_COLOR)


func _on_inn_rest_ended(completed: bool) -> void:
	if completed:
		_stage.world.float_text(_player.global_position, INN_RESTED_TEXT, REST_COLOR)
	else:
		_stage.world.float_text(_player.global_position, INN_INTERRUPTED_TEXT, REST_REFUSED_COLOR)


## Every monster on the map as the rule for resting sees it (see MonstersAround). Line of sight is only worked
## out for the awake ones close enough to matter.
func _monsters_near_hero() -> Array[MonstersAround.Nearby]:
	var nearby: Array[MonstersAround.Nearby] = []
	for enemy in _all_enemies():
		var awake := not enemy.is_asleep()
		var cells := _player.global_position.distance_to(enemy.global_position) / DungeonView.TILE_SIZE
		var in_sight := awake and cells <= _monsters_around.sight_cells \
				and _stage.pathfinder.can_see(_player.global_position, enemy.global_position)
		nearby.append(MonstersAround.Nearby.new(awake, enemy.is_hunting(), cells, in_sight))
	return nearby


# --- Loot ----------------------------------------------------------------------------------------

## The ruin's guaranteed chest, if the map has a ruin.
func _spawn_ruin_chest() -> void:
	if _stage.map.ruin_cell != DungeonMap.NO_CELL:
		_spawn_chest(Ruins.NUMBER, _stage.map.ruin_cell)


## A chest on a cell, open if the record says it was opened. It is known by the id of whatever holds it: a room, or a
## set piece like the ruin (see Ruins.NUMBER). Clearing a room no longer leaves one (loot is earned).
func _spawn_chest(chest_id: int, cell: Vector2i, locked := false) -> Chest:
	var chest := Chest.new(_record.is_chest_opened(chest_id), locked)
	chest.position = DungeonView.cell_center(cell)
	chest.opened.connect(_open_chest.bind(chest.position, chest_id))
	_stage.add_on_floor.call_deferred(chest)
	_stage.world.add_chest(chest)
	return chest


## The chest in the middle of each trap room, on its mark (a cell no monster spawns on), known by its room's id. It
## stays shut and ignores the hero until the room is clear (see _on_room_cleared); a room cleared on an earlier visit
## has its chest ready at once.
func _spawn_trap_chests() -> void:
	for room: int in _stage.map.locking_room_ids():
		if _stage.map.locking_kind(room) == LockingRoom.Kind.TRAP:
			_trap_chests[room] = _spawn_chest(room, _stage.map.locking_mark_cell(room), not _progress.is_cleared(room))


## A chest holds a random weapon, movement or skill the player doesn't already have, picked when it opens, and
## sometimes a potion beside it.
func _open_chest(at: Vector2, chest_id: int) -> void:
	_record.open_chest(chest_id)
	_spawn_drop(at, LootTable.pick_item_id(GameTuning.item_ids(), _held_ids(), _rng))
	if LootTable.rolls(GameTuning.chest_potion_chance(_tuning), _rng):
		_spawn_potion(_spot_beside(at), LootTable.pick_potion_id(GameTuning.potion_weights(), _rng))


## The centre of a safe floor cell next to a spot, or the spot itself if there is none.
func _spot_beside(at: Vector2) -> Vector2:
	var cell := DungeonView.world_to_cell(at)
	for step in BESIDE:
		if _stage.map.is_standable(cell + step) and not _stage.map.is_door(cell + step):
			return DungeonView.cell_center(cell + step)
	return at


func _held_ids() -> Array[String]:
	var held: Array[String] = [_weapon_id, _movement_id]
	if _skill_id != GameTuning.NO_SKILL:
		held.append(_skill_id)
	return held


func _spawn_drop(at: Vector2, item_id: String) -> ItemDrop:
	var drop := ItemDrop.new(GameTuning.item(_tuning, item_id))
	drop.position = at
	drop.player_entered.connect(_offer.bind(drop))
	drop.player_exited.connect(_on_drop_left.bind(drop))
	_stage.add_on_floor.call_deferred(drop)
	_stage.world.add_drop(drop)
	return drop


func _spawn_potion(at: Vector2, potion_id: String) -> PotionDrop:
	var drop := PotionDrop.new(GameTuning.potion(_tuning, potion_id))
	drop.position = at
	drop.player_entered.connect(_collect_potion.bind(drop))
	_stage.add_on_floor.call_deferred(drop)
	_stage.world.add_potion(drop)
	return drop


## Potions are picked up by walking over them, while the belt has room for that kind.
func _collect_potion(drop: PotionDrop) -> void:
	if _belt.add(drop.potion.id):
		_mark_taken(drop)
		drop.queue_free()


## A floor item, once taken, stays gone on later visits; what is swapped into its place is an ordinary drop.
func _mark_taken(drop: PickupArea) -> void:
	if _floor_loot_cells.has(drop):
		_record.take_loot(_floor_loot_cells[drop])
		_floor_loot_cells.erase(drop)


func _drink(potion_id: String) -> void:
	if _in_play and _belt.take(potion_id):
		_player.drink(GameTuning.potion(_tuning, potion_id))


func _refresh_potions() -> void:
	_potion_bar.show_belt(_belt, GameTuning.potions(), _keyboard_mouse.is_keyboard_mouse())


func _offer(drop: ItemDrop) -> void:
	_offered_drop = drop
	_loot_card.show_offer(drop.item, _held_in_same_slot(drop.item))


## What the found item would replace: null when it goes into an empty skill slot.
func _held_in_same_slot(found: Item) -> Item:
	return _player.weapon if found is Weapon else _player.utility_in((found as Utility).slot)


func _on_drop_left(drop: ItemDrop) -> void:
	if drop == _offered_drop:
		_close_offer()


func _close_offer() -> void:
	_offered_drop = null
	_loot_card.hide()


## Swap: the player takes the found item and leaves the one it replaces on the floor in its place (nothing, when
## it fills an empty skill slot). The card only comes back after stepping off and on again, so a swap can be undone
## but never happens by accident.
func _on_take_pressed() -> void:
	if _offered_drop == null:
		return
	var found := _offered_drop.item
	var replaced := _held_in_same_slot(found)
	_mark_taken(_offered_drop)
	if replaced == null:
		_offered_drop.queue_free()
	else:
		_offered_drop.item = replaced
	_close_offer()
	if found is Weapon:
		_weapon_id = found.id
	elif (found as Utility).slot == Utility.Slot.MOVEMENT:
		_movement_id = found.id
	else:
		_skill_id = found.id
	_apply_tuning(_tuning)


# --- Equipment and tuning ------------------------------------------------------------------------

## Applies everything that can change mid-run. The rest (like enemy health) waits for the next run.
func _apply_tuning(tuning: Tuning) -> void:
	_player.move_speed = GameTuning.player_move_speed(tuning)
	_stage.world.framing = GameTuning.camera_framing(tuning)
	_stage.world.set_wall_height(GameTuning.wall_height(tuning))
	_weapon_switch.visible = GameTuning.shows_weapon_switch(tuning)
	_equip(
		GameTuning.weapon(tuning, _weapon_id), GameTuning.movement(tuning, _movement_id),
		GameTuning.skill(tuning, _skill_id))
	_attack_button.dead_zone = GameTuning.weapon_dead_zone(tuning)
	_attack_button.catch_scale = GameTuning.button_catch_scale(tuning)
	_attack_button.drag_reach = GameTuning.drag_reach(tuning)
	for button: AimButton in _utility_buttons().values():
		button.dead_zone = GameTuning.utility_dead_zone(tuning)
		button.catch_scale = GameTuning.button_catch_scale(tuning)
		button.drag_reach = GameTuning.drag_reach(tuning)
	for enemies: Array in _enemies_by_band.values():
		for enemy: Enemy in enemies:
			enemy.arm(GameTuning.monster_weapon(tuning, enemy.monster))
			_tune_enemy(enemy, tuning)
	GameTuning.tune_awareness(_hearing, tuning)
	_rest_profile = GameTuning.rest_profile(tuning)
	_monsters_around = GameTuning.monsters_around(tuning)
	_ambush = GameTuning.ambush(tuning)
	for spot: RestSpot in _rest_spots.values():
		spot.fire.profile = _rest_profile
	if _inn != null:
		_inn.rest.profile = GameTuning.inn_profile(tuning)
	for squad: Squad in _squads_by_band.values():
		GameTuning.tune_squad(squad, tuning)


## The tuned pace, awareness and wandering of one monster (its weapon is armed separately).
func _tune_enemy(enemy: Enemy, tuning: Tuning) -> void:
	enemy.move_speed = GameTuning.enemy_move_speed(tuning) * enemy.monster.speed_multiplier
	enemy.lead_share = GameTuning.enemy_lead_share(tuning)
	enemy.recover_seconds = GameTuning.enemy_recover_seconds(tuning)
	enemy.noticing_seconds = GameTuning.enemy_noticing_seconds(tuning)
	enemy.wander_speed_share = GameTuning.enemy_wander_speed_share(tuning)
	enemy.wander_radius = GameTuning.band_wander_radius_cells(tuning) * DungeonView.TILE_SIZE
	GameTuning.tune_awareness(enemy.awareness, tuning)
	if enemy.monster.id == Lich.ID:
		enemy.keep_distance_cells = GameTuning.lich(tuning).keep_distance_cells
		GameTuning.tune_spells(enemy.spell_picker, tuning)
		enemy.spell_weapons = GameTuning.lich_spell_weapons(tuning)


## The attack button shows the weapon, or REST while the hero can rest at a campfire or the inn's doorstep.
func _show_attack_button() -> void:
	_attack_button.label = REST_LABEL if _rest_offer else _player.weapon.button_label
	_attack_button.color = REST_COLOR if _rest_offer else _player.weapon.color
	_touch_controls.offer_rest(_rest_offer)


## The buttons always show what is equipped. skill: null for an empty skill slot.
func _equip(weapon: Weapon, movement: Utility, skill: Utility) -> void:
	_player.equip_weapon(weapon)
	_player.equip_utility(movement)
	if skill == null:
		_player.unequip_skill()
	else:
		_player.equip_utility(skill)
	_show_attack_button()
	_weapon_switch.text = "Weapon: %s" % weapon.button_label
	_movement_button.label = movement.button_label
	_movement_button.color = movement.color
	_skill_button.label = EMPTY_SKILL_LABEL if skill == null else skill.button_label
	_skill_button.color = EMPTY_SKILL_COLOR if skill == null else skill.color
	if _offered_drop != null:
		_loot_card.show_offer(_offered_drop.item, _held_in_same_slot(_offered_drop.item))


# --- Menu ----------------------------------------------------------------------------------------

func _on_customize_requested() -> void:
	_hud_layer.hide()
	_layout_editor.open(_layout)


func _on_layout_finished(layout: ControlLayout) -> void:
	_hud_layer.show()
	_layout = layout
	_touch_controls.apply_layout(layout)
	_warn_if_failed(_settings.save_layout(layout), "the control layout")
	_pause_menu.return_to_panel()


## Testing aid: cycles through every weapon, keeping each one's own tuning. Runs still start with the Dagger, and
## the HUD button stays hidden unless Tune → Controls shows it (the keyboard key always works).
func _on_weapon_switch_pressed() -> void:
	_weapon_id = GameTuning.next_weapon_id(_weapon_id)
	_apply_tuning(_tuning)


func _on_tuning_requested() -> void:
	_hud_layer.hide()
	_tuning_panel.open(_tuning, GameTuning.sections(_weapon_id, _movement_id, _skill_id), _run.world_seed)


func _on_tuning_finished(tuning: Tuning) -> void:
	_hud_layer.show()
	_tuning = tuning
	_apply_tuning(tuning)
	_warn_if_failed(_settings.save_tuning(tuning), "the tuning")
	_pause_menu.return_to_panel()


func _on_credits_requested() -> void:
	_hud_layer.hide()
	_credits_panel.open()


func _on_credits_finished() -> void:
	_hud_layer.show()
	_pause_menu.return_to_panel()


func _warn_if_failed(error: Error, what: String) -> void:
	if error != OK:
		push_warning("Could not save %s: %s" % [what, error_string(error)])


# --- Run state -----------------------------------------------------------------------------------

## Every kill is worth the monster's toughness in experience; each level makes the hero tougher.
func _grow_from(monster: Monster) -> void:
	var levels := _experience.gain(monster.max_health)
	if levels > 0:
		_player.health.raise_maximum(levels * Experience.HEALTH_PER_LEVEL)
		_stage.world.float_text(_player.global_position, "LEVEL %d!" % _experience.level(), LEVEL_UP_COLOR)


## Names the place and greets the player, like Dungeon Crawl on arriving somewhere new.
func _greet() -> void:
	var place := _place()
	_shown_place = place.name
	_arrival.text = "%s\n%s" % [place.name, place.greeting]
	_arrival.modulate.a = 1.0
	if _arrival_fade != null:
		_arrival_fade.kill()
	_arrival_fade = create_tween()
	_arrival_fade.tween_interval(ARRIVAL_SECONDS)
	_arrival_fade.tween_property(_arrival, "modulate:a", 0.0, ARRIVAL_FADE_SECONDS)


## Where the hero stands: the village inside the palisade, else the map (see Place).
func _place() -> Place:
	return Place.at(_stage.spec, _stage.map, DungeonView.world_to_cell(_player.global_position))


## Crossing a gate names the new place: on the banner, and in the HUD.
func _track_place() -> void:
	if _in_play and _place().name != _shown_place:
		_greet()
		_refresh_hud()


## The branch this map is in (see Branch).
func _branch() -> Branch:
	return _stage.spec.branch()


func _refresh_hud() -> void:
	if not _in_play:
		return
	var goal := "Find the stairs down"
	if _branch().outdoors:
		goal = "Find the crypt entrance"
	elif not WorldLayout.has_stairs_down(_stage.spec.id):
		goal = "The Lich is dead" if _run.won else "Kill the Lich"
	var place := _place().name
	_hud.text = "%s    Level %d (%d%%)    HP %d/%d    %s" % [
		place, _experience.level(), roundi(_experience.progress() * 100), _player.health.current,
		_player.health.maximum, goal]


## The hero as they are now, to take onto the next map.
func _carried_hero() -> HeroState:
	return HeroState.carrying(
		_weapon_id, _movement_id, _skill_id, _player.health, _belt.to_dict(), _experience.points, _run.hero.kills)


## Down (or up) to the next map with everything the player holds: from the plains into the crypt entrance and back,
## and down the floors (the last has no stairs down: the Lich's arena is the end).
func _take_stairs(exit: WorldLayout.Exit) -> void:
	if not _in_play:
		return
	_run.travel(exit, _carried_hero())
	var way := "Down" if exit == WorldLayout.Exit.STAIRS_DOWN else "Up"
	await _move_to_run_map("%s to the %s..." % [way, _run.current_map().branch().display_name])


## Warp (Tune → World, a playtest aid): to a place of the slice with everything the player holds, through the same
## leave-and-enter as the stairs, so the map left is written down and the one entered is replayed.
func _warp_to(target_id: String) -> void:
	var target := Warp.target(target_id)
	if not _in_play or target == null:
		return
	_run.warp(target, _carried_hero())
	_resume_game()
	await _move_to_run_map("Warping to %s..." % target.label.to_lower())


## Leaves the map for the run's current one (which the run has just been told to go to).
func _move_to_run_map(message: String) -> void:
	_in_play = false
	_hud.text = message
	var run := _run
	await get_tree().create_timer(DESCEND_DELAY_SECONDS).timeout
	if run != _run:
		return  # The player started over meanwhile.
	_leave_map()
	_enter_map()


## A moment to see what happened, then the run's summary, until the player starts over.
func _end_run(ending: RunSummary.Ending) -> void:
	if not _in_play:
		return
	_in_play = false
	_hud.text = RunSummary.title(ending)
	var run := _run
	await get_tree().create_timer(SUMMARY_DELAY_SECONDS).timeout
	if run != _run:
		return  # The player started over meanwhile.
	get_tree().paused = true
	_hud_layer.hide()
	_run_summary.show_summary(ending, RunSummary.lines(_run, _experience.level(), ending, _player.last_hurt_by))


## The Lich is dead: a moment to see it, then the run's summary. Dismissing it carries on playing in the same world
## (see _keep_playing). A hero who dies in that moment gets the death summary instead. The moment only runs while
## the game does, so the summary never opens over the pause menu or the map (whose closing would unpause under it).
func _win() -> void:
	var run := _run
	await get_tree().create_timer(SUMMARY_DELAY_SECONDS, false).timeout
	if run != _run or not _in_play:
		return  # The player started over or died meanwhile.
	_in_play = false
	get_tree().paused = true
	_hud_layer.hide()
	_run_summary.show_summary(
		RunSummary.Ending.WON, RunSummary.lines(_run, _experience.level(), RunSummary.Ending.WON, ""))


## "Keep exploring" on the win summary: back to the same world, the Lich still dead.
func _keep_playing() -> void:
	_run_summary.hide()
	_hud_layer.show()
	get_tree().paused = false
	_in_play = true
	_refresh_hud()


## Dying, restarting from the menu or New world in the Tune screen starts a new world with a new seed.
func _restart() -> void:
	_begin_world(_run.next_world(_rng, GameTuning.plains_recipe(_tuning), GameTuning.crypt_recipe(_tuning)))


## Same seed again in the Tune screen: this world's seed from the start, made with the tuning as it is now.
func _restart_with_same_seed() -> void:
	_begin_world(_run.same_world_again(GameTuning.plains_recipe(_tuning), GameTuning.crypt_recipe(_tuning)))


func _begin_world(run: Run) -> void:
	_resume_game()
	_leave_map()
	_start_run(run)


## Closes the summary and the pause menu and lets the game run.
func _resume_game() -> void:
	_run_summary.hide()
	_hud_layer.show()
	if _pause_menu.is_open():
		_pause_menu.close()
	get_tree().paused = false
