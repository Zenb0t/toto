extends Node2D
## Composition root: generates the floor's dungeon, spawns actors, routes touch intents to the player,
## applies the room-lock, loot and stairs rules, and connects the pause menu's settings screens.
## The scene is one floor: the stairs carry the run (RunState) down to a freshly loaded scene.
## The 2D world under this node runs the game; WorldView3D shows it in 3D, with the 2D plane on its floor.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
## How long the end of a run shows in the game before its summary.
const SUMMARY_DELAY_SECONDS := 1.2
## How long "down to floor N" shows before the next floor loads.
const DESCEND_DELAY_SECONDS := 0.8
const LEVEL_UP_COLOR := Color(1.0, 0.85, 0.35)
## The branch's name and greeting show on arriving, then fade out.
const ARRIVAL_SECONDS := 2.5
const ARRIVAL_FADE_SECONDS := 1.0
## Where a chest's potion lands, tried in order: beside the chest, on safe floor.
const BESIDE: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
## How often line of sight is worked out again.
const SIGHT_UPDATE_SECONDS := 0.1
const TOUCH_HELP := "Left side: move.  Buttons: tap = auto-aim, drag = aim, release = fire.  Cleared rooms leave a chest.  Gold stairs lead down.  II: menu."
const KEYBOARD_MOUSE_HELP := "WASD: move.  Mouse: aim; click or hold: attack.  Right click / Space: utility.  1-3: potions.  E: take item.  Q: next weapon.  Esc: menu."

var _seed: int
## The run so far: which floor this is, and what the player brought down.
var _run := RunState.take_carried()
var _map: DungeonMap
var _pathfinder: Pathfinder
var _run_over := false
var _lava := LavaBurn.new()
var _exploration := Exploration.new()
var _fog: FogView
var _minimap := MinimapView.new()
var _big_map := MapOverlay.new()
var _sight_update_left := 0.0
## Where the player last looked from; sight is only worked out again when this or a door changes.
var _sight_origin := DungeonMap.NO_CELL
var _view: DungeonView
var _world: WorldView3D
var _progress: DungeonProgress
var _player: Player
var _enemies_by_room := {}  # int -> Array[Enemy]
var _squads_by_room := {}  # int -> Squad: each room's enemies fight as a team
var _settings := GameSettings.new()
var _layout: ControlLayout
var _tuning: Tuning
var _weapon_id := _run.weapon_id
## How long the mouse button has been held on a weapon that charges.
var _mouse_held_seconds := 0.0
var _utility_id := _run.utility_id
var _rng := RandomNumberGenerator.new()
var _offered_drop: ItemDrop  ## The dropped item the player is standing on, if any.
var _belt := PotionBelt.new()
var _experience := Experience.new(_run.experience)

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
@onready var _utility_button: AimButton = $TouchControls/UtilityButton
@onready var _keyboard_mouse: KeyboardMouseControls = $KeyboardMouse
@onready var _pause_menu: PauseMenu = $Overlay/PauseMenu
@onready var _layout_editor: LayoutEditor = $Overlay/LayoutEditor
@onready var _tuning_panel: TuningPanel = $Overlay/TuningPanel
@onready var _credits_panel: CreditsPanel = $Overlay/CreditsPanel
@onready var _run_summary: RunSummaryPanel = $Overlay/RunSummary


func _ready() -> void:
	_rng.randomize()
	_seed = _rng.randi()
	_map = DungeonMapParser.new().parse(DungeonGenerator.new().generate(_seed, _run.floor_number))
	_pathfinder = Pathfinder.new(_map)
	_view = DungeonView.new()
	add_child(_view)
	move_child(_view, 0)
	_view.show_map(_map, _branch().look)
	_fog = FogView.new(_map.size, _view.drawn_cells())
	_world = WorldView3D.new()
	add_child(_world)
	_world.show_world(self, _map, _view.wall_cells(), _branch().look)
	_tuning = _settings.load_tuning()
	_layout = _settings.load_layout()
	_pause_menu.show_seed(_seed, _run.floor_number)

	_player = _spawn_player()
	_spawn_enemies()
	_spawn_floor_loot()
	add_child(_fog)
	_hud_layer.add_child(_minimap)
	_minimap.visible = _settings.load_minimap_shown()
	$Overlay.add_child(_big_map)
	_update_sight()
	_progress = _create_progress()
	_belt.changed.connect(_refresh_potions)
	_belt.load_dict(_run.potions)
	_connect_controls()
	_connect_keyboard_mouse()
	_connect_menu()
	_apply_tuning(_tuning)
	_touch_controls.apply_layout(_layout)
	_show_input_mode(_keyboard_mouse.mode)
	_refresh_hud()
	_greet()


func _physics_process(delta: float) -> void:
	_player.move(_move_input())
	var mouse_held := _keyboard_mouse.is_attack_held() and not _run_over
	if mouse_held and _player.weapon.charge_seconds() > 0.0:
		_mouse_held_seconds += delta
		_charge_toward_cursor()
	elif mouse_held:
		_attack_toward_cursor()
	else:
		_mouse_held_seconds = 0.0
	_update_charging()
	_apply_terrain(delta)
	for squad: Squad in _squads_by_room.values():
		squad.tick(delta)
	_sight_update_left -= delta
	if _sight_update_left <= 0.0:
		_sight_update_left = SIGHT_UPDATE_SECONDS
		_update_sight()
	_attack_button.set_cooldown_ratio(_player.attack_cooldown_ratio())
	_utility_button.set_cooldown_ratio(_player.utility_cooldown_ratio())
	_track_player_room()


# --- Setup ---------------------------------------------------------------------------------------

func _spawn_player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.health = Health.restored(_run.max_health, _run.health)
	player.position = DungeonView.cell_center(_map.player_spawn)
	player.attack_fired.connect(_spawn_attacks.bind(player))
	player.health_changed.connect(func(_current: int, _maximum: int) -> void: _refresh_hud())
	player.died.connect(func() -> void: _end_run(RunSummary.Ending.DIED))
	add_child(player)
	_world.add_player(player)
	return player


func _spawn_enemies() -> void:
	for cell in _map.enemy_spawns:
		var room := _map.room_at(cell)
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.position = DungeonView.cell_center(cell)
		var monster := Bestiary.by_id(_map.monster_at(cell))
		enemy.become(monster, GameTuning.enemy_health_multiplier(_tuning))
		enemy.arm(GameTuning.enemy_weapon(_tuning, monster.weapon_id))
		enemy.navigation = _pathfinder
		enemy.squad = _squads_by_room.get_or_add(room, Squad.new())
		enemy.attack_fired.connect(_spawn_attacks.bind(enemy))
		enemy.defeated.connect(_on_enemy_defeated.bind(room))
		add_child(enemy)
		_world.add_enemy(enemy)
		_enemies_by_room.get_or_add(room, []).append(enemy)


## Things lying around from the start (vault treasure, dead-end finds): potions, or gear picked like a chest's.
func _spawn_floor_loot() -> void:
	for cell in _map.loot_cells:
		var at := DungeonView.cell_center(cell)
		if LootTable.rolls(LootTable.FLOOR_POTION_SHARE, _rng):
			_spawn_potion(at, LootTable.pick_potion_id(GameTuning.potion_weights(), _rng))
		else:
			_spawn_drop(at, LootTable.pick_item_id(GameTuning.item_ids(), _held_ids(), _rng))


func _create_progress() -> DungeonProgress:
	var counts := {}
	for room: int in _enemies_by_room:
		counts[room] = _enemies_by_room[room].size()
	var progress := DungeonProgress.new(counts)
	progress.room_locked.connect(_on_room_locked)
	progress.room_cleared.connect(_on_room_cleared)
	return progress


func _connect_controls() -> void:
	_attack_button.aim_changed.connect(
		func(direction: Vector2, strength: float) -> void:
			_player.preview_aim(direction, _player.weapon.aim_shape(), strength))
	_attack_button.aim_released.connect(_on_attack_released)
	_utility_button.aim_changed.connect(
		func(direction: Vector2, _strength: float) -> void:
			_player.preview_aim(direction, _player.utility.aim_shape()))
	_weapon_switch.pressed.connect(_on_weapon_switch_pressed)
	_utility_button.aim_released.connect(_on_utility_released)
	_attack_button.returned_to_dead_zone.connect(_buzz)
	_utility_button.returned_to_dead_zone.connect(_buzz)
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
	_keyboard_mouse.utility_requested.connect(_use_utility_toward_cursor)
	_keyboard_mouse.potion_requested.connect(func(slot: int) -> void: _drink(GameTuning.potion_ids()[slot]))
	_keyboard_mouse.take_requested.connect(_on_take_pressed)
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
	_pause_menu.credits_requested.connect(_on_credits_requested)
	_credits_panel.finished.connect(_on_credits_finished)
	_run_summary.play_again_pressed.connect(_restart)


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
	if _run_over or _player.weapon.charge_seconds() <= 0.0:
		return
	var aim := MouseAim.toward(_player.global_position, _cursor_on_plane(), _player.weapon, _player.facing)
	_player.attack(aim.direction, null, aim.strength, held)


## The hero is slower while drawing a weapon that charges, by touch or mouse.
func _update_charging() -> void:
	var weapon := _player.weapon
	if weapon.charge_seconds() <= 0.0:
		_player.charging = false
		return
	_player.charging = _attack_button.is_held() or _mouse_held_seconds > 0.0
	if _attack_button.is_held():
		_player.preview_charge(Charge.ratio(_attack_button.held_seconds(), weapon.charge_seconds()))


func _use_utility_toward_cursor() -> void:
	if not _run_over:
		_player.use_utility(MouseAim.direction(_player.global_position, _cursor_on_plane(), _player.facing))


func _cursor_on_plane() -> Vector2:
	return _world.plane_point_at(_keyboard_mouse.cursor())


func _on_attack_released(release: AimGesture.Release) -> void:
	_player.preview_aim(Vector2.ZERO)
	if release.is_cancelled:
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


func _on_utility_released(release: AimGesture.Release) -> void:
	_player.preview_aim(Vector2.ZERO)
	if release.is_cancelled:
		return
	_player.use_utility(release.direction if not release.is_auto else _player.facing)


## Closest enemy in the room the player is fighting in (or standing in), at any distance. Null if none.
func _auto_aim_target() -> Enemy:
	var enemies: Array = _enemies_by_room.get(_combat_room(), [])
	var positions: Array[Vector2] = []
	for enemy: Enemy in enemies:
		positions.append(enemy.global_position)
	var nearest := AutoAim.nearest_index(_player.global_position, positions, INF)
	return null if nearest == AutoAim.NO_TARGET else enemies[nearest]


func _combat_room() -> int:
	if _progress.locked_room != DungeonProgress.NO_ROOM:
		return _progress.locked_room
	return _map.room_at(DungeonView.world_to_cell(_player.global_position))


# --- Rooms and combat ----------------------------------------------------------------------------

## Lock a room only once the player is a full tile past its doorway, so a closing door can't trap them in it.
## Stepping on the stairs, once their room is clear, leads down (or out, from the last floor).
func _track_player_room() -> void:
	var cell := DungeonView.world_to_cell(_player.global_position)
	if _map.is_clear_of_doors(cell):
		_progress.enter_room(_map.room_at(cell))
	if cell == _map.exit_cell and _progress.is_cleared(_map.room_at(cell)):
		_take_stairs()


func _on_room_locked(room: int) -> void:
	_view.set_room_closed(room, true)
	_world.set_doors_closed(_map.doors_of_room(room), true)
	_sight_origin = DungeonMap.NO_CELL
	for enemy: Enemy in _enemies_by_room[room]:
		enemy.chase(_player)


func _on_room_cleared(room: int) -> void:
	_view.set_room_closed(room, false)
	_world.set_doors_closed(_map.doors_of_room(room), false)
	_sight_origin = DungeonMap.NO_CELL
	_spawn_chest(room)


func _on_enemy_defeated(enemy: Enemy, room: int) -> void:
	_enemies_by_room[room].erase(enemy)
	_progress.record_defeat(room)
	_run.kills += 1
	_grow_from(enemy.monster)
	_refresh_hud()
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
			get_tree().create_timer(attack.delay, false, true).timeout.connect(_follow_up.bind(attack, attacker))
		elif attack is Shot:
			_launch(attack)
		elif attack is Slash:
			add_child(SlashEffect.new(attack, attacker))
		elif attack is Nova:
			add_child(NovaEffect.new(attack))


func _launch(shot: Shot) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(shot)
	add_child(projectile)
	_world.add_projectile(projectile)


## A delayed shot (a flurry's later punch) sets off from where its attacker stands now, if still standing.
func _follow_up(shot: Shot, attacker: Node2D) -> void:
	if not is_instance_valid(attacker) or not attacker.is_physics_processing():
		return
	shot.origin = Weapon.muzzle(attacker.global_position, shot.direction)
	_launch(shot)


## Fog of war: the player sees through open floor, water and lava, not walls or closed doors. Enemies out of
## sight are hidden; the map they have seen stays drawn, dimmed, with the items seen on it (like Dungeon
## Crawl's map memory). Items not seen yet are hidden.
func _update_sight() -> void:
	var origin := DungeonView.world_to_cell(_player.global_position)
	if origin != _sight_origin:
		_sight_origin = origin
		var is_clear := func(cell: Vector2i) -> bool: return _map.is_see_through(cell) and not _view.is_door_closed(cell)
		_exploration.look_from(origin, is_clear)
		_fog.show_exploration(_exploration)
		_world.show_exploration(_exploration)
		_minimap.show_map(_map, _exploration, origin)
	for enemies: Array in _enemies_by_room.values():
		for enemy: Enemy in enemies:
			enemy.visible = _exploration.is_visible(DungeonView.world_to_cell(enemy.global_position))
	for pickup: PickupArea in get_tree().get_nodes_in_group(PickupArea.GROUP):
		pickup.visible = _exploration.is_seen(DungeonView.world_to_cell(pickup.global_position))


## Shows or hides the minimap, and remembers the choice for the next floor and the next run.
func _toggle_minimap() -> void:
	_minimap.visible = not _minimap.visible
	_warn_if_failed(_settings.save_minimap_shown(_minimap.visible), "the minimap setting")


## The whole map fills the screen and the game waits until it is closed.
func _open_big_map() -> void:
	if _run_over:
		return
	get_tree().paused = true
	_big_map.open(_map, _exploration, DungeonView.world_to_cell(_player.global_position))


## Lava burns whoever stands in it; shallow water slows whoever wades through it.
func _apply_terrain(delta: float) -> void:
	_burn(_player, delta)
	_player.ground_speed = _map.ground_speed(DungeonView.world_to_cell(_player.global_position))
	for enemies: Array in _enemies_by_room.values():
		for enemy: Enemy in enemies:
			_burn(enemy, delta)
			enemy.ground_speed = _map.ground_speed(DungeonView.world_to_cell(enemy.global_position))


func _burn(actor: Node2D, delta: float) -> void:
	var cell := DungeonView.world_to_cell(actor.global_position)
	var in_lava := _map.terrain_at(cell) == DungeonMap.Terrain.LAVA
	var damage := _lava.damage_due(actor.get_instance_id(), in_lava, delta)
	if damage > 0:
		actor.take_damage(damage, "lava")


# --- Loot ----------------------------------------------------------------------------------------

func _spawn_chest(room: int) -> void:
	var chest := Chest.new()
	chest.position = DungeonView.cell_center(_map.room_center(room))
	chest.opened.connect(_open_chest.bind(chest.position))
	_place_on_floor.call_deferred(chest)
	_world.add_chest(chest)


## A chest holds a random weapon or utility the player doesn't already have, picked when it opens, and
## sometimes a potion beside it.
func _open_chest(at: Vector2) -> void:
	_spawn_drop(at, LootTable.pick_item_id(GameTuning.item_ids(), _held_ids(), _rng))
	if LootTable.rolls(GameTuning.chest_potion_chance(_tuning), _rng):
		_spawn_potion(_spot_beside(at), LootTable.pick_potion_id(GameTuning.potion_weights(), _rng))


## The centre of a safe floor cell next to a spot, or the spot itself if there is none.
func _spot_beside(at: Vector2) -> Vector2:
	var cell := DungeonView.world_to_cell(at)
	for step in BESIDE:
		if _map.is_standable(cell + step) and not _map.is_door(cell + step):
			return DungeonView.cell_center(cell + step)
	return at


func _held_ids() -> Array[String]:
	return [_weapon_id, _utility_id]


func _spawn_drop(at: Vector2, item_id: String) -> void:
	var drop := ItemDrop.new(GameTuning.item(_tuning, item_id))
	drop.position = at
	drop.player_entered.connect(_offer.bind(drop))
	drop.player_exited.connect(_on_drop_left.bind(drop))
	_place_on_floor.call_deferred(drop)
	_world.add_drop(drop)


func _spawn_potion(at: Vector2, potion_id: String) -> void:
	var drop := PotionDrop.new(GameTuning.potion(_tuning, potion_id))
	drop.position = at
	drop.player_entered.connect(_collect_potion.bind(drop))
	_place_on_floor.call_deferred(drop)
	_world.add_potion(drop)


## Potions are picked up by walking over them, while the belt has room for that kind.
func _collect_potion(drop: PotionDrop) -> void:
	if _belt.add(drop.potion.id):
		drop.queue_free()


func _drink(potion_id: String) -> void:
	if not _run_over and _belt.take(potion_id):
		_player.drink(GameTuning.potion(_tuning, potion_id))


func _refresh_potions() -> void:
	_potion_bar.show_belt(_belt, GameTuning.potions(), _keyboard_mouse.is_keyboard_mouse())


## Drawn above the map but below the actors. Loot appears from inside physics callbacks (a hit, a step),
## where areas can't be added yet, so callers defer this.
func _place_on_floor(node: Node2D) -> void:
	add_child(node)
	move_child(node, _view.get_index() + 1)


func _offer(drop: ItemDrop) -> void:
	_offered_drop = drop
	_loot_card.show_offer(drop.item, _held_in_same_slot(drop.item))


func _held_in_same_slot(found: Item) -> Item:
	return _player.weapon if found is Weapon else _player.utility


func _on_drop_left(drop: ItemDrop) -> void:
	if drop == _offered_drop:
		_close_offer()


func _close_offer() -> void:
	_offered_drop = null
	_loot_card.hide()


## Swap: the player takes the found item and leaves the one it replaces on the floor in its place. The card
## only comes back after stepping off and on again, so a swap can be undone but never happens by accident.
func _on_take_pressed() -> void:
	if _offered_drop == null:
		return
	var found := _offered_drop.item
	_offered_drop.item = _held_in_same_slot(found)
	_close_offer()
	if found is Weapon:
		_weapon_id = found.id
	else:
		_utility_id = found.id
	_apply_tuning(_tuning)


# --- Equipment and tuning ------------------------------------------------------------------------

## Applies everything that can change mid-run. The rest (like enemy health) waits for the next run.
func _apply_tuning(tuning: Tuning) -> void:
	_player.move_speed = GameTuning.player_move_speed(tuning)
	_world.framing = GameTuning.camera_framing(tuning)
	_world.set_wall_height(GameTuning.wall_height(tuning))
	_weapon_switch.visible = GameTuning.shows_weapon_switch(tuning)
	_equip(GameTuning.weapon(tuning, _weapon_id), GameTuning.utility(tuning, _utility_id))
	_attack_button.dead_zone = GameTuning.weapon_dead_zone(tuning)
	_utility_button.dead_zone = GameTuning.utility_dead_zone(tuning)
	_attack_button.catch_scale = GameTuning.button_catch_scale(tuning)
	_utility_button.catch_scale = GameTuning.button_catch_scale(tuning)
	_attack_button.drag_reach = GameTuning.drag_reach(tuning)
	_utility_button.drag_reach = GameTuning.drag_reach(tuning)
	for enemies: Array in _enemies_by_room.values():
		for enemy: Enemy in enemies:
			enemy.move_speed = GameTuning.enemy_move_speed(tuning) * enemy.monster.speed_multiplier
			enemy.arm(GameTuning.enemy_weapon(tuning, enemy.weapon.id))
			enemy.lead_share = GameTuning.enemy_lead_share(tuning)
			enemy.recover_seconds = GameTuning.enemy_recover_seconds(tuning)
	for squad: Squad in _squads_by_room.values():
		GameTuning.tune_squad(squad, tuning)


## The buttons always show what is equipped.
func _equip(weapon: Weapon, utility: Utility) -> void:
	_player.equip_weapon(weapon)
	_player.equip_utility(utility)
	_attack_button.label = weapon.button_label
	_attack_button.color = weapon.color
	_weapon_switch.text = "Weapon: %s" % weapon.button_label
	_utility_button.label = utility.button_label
	_utility_button.color = utility.color
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
	_tuning_panel.open(_tuning, GameTuning.sections(_weapon_id, _utility_id))


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
		_world.float_text(_player.global_position, "LEVEL %d!" % _experience.level(), LEVEL_UP_COLOR)


## Names the branch and greets the player, like Dungeon Crawl on arriving somewhere new.
func _greet() -> void:
	_arrival.text = "The %s\n%s" % [_branch().display_name, _branch().greeting]
	var fade := create_tween()
	fade.tween_interval(ARRIVAL_SECONDS)
	fade.tween_property(_arrival, "modulate:a", 0.0, ARRIVAL_FADE_SECONDS)


## The branch this floor is in (see Branch).
func _branch() -> Branch:
	return Branch.for_floor(_run.floor_number)


func _refresh_hud() -> void:
	if _run_over:
		return
	var goal := "Find the way out" if _run.is_last_floor() else "Find the stairs down"
	_hud.text = "%s (floor %d/%d)    Level %d (%d%%)    HP %d/%d    %s" % [
		_branch().display_name, _run.floor_number, RunState.FLOOR_COUNT,
		_experience.level(), roundi(_experience.progress() * 100), _player.health.current,
		_player.health.maximum, goal]


## Down to the next floor with everything the player holds, or out of the dungeon from the last one.
func _take_stairs() -> void:
	if _run.is_last_floor():
		_end_run(RunSummary.Ending.ESCAPED)
		return
	if _run_over:
		return
	_run_over = true
	var next := _run.next_floor(_weapon_id, _utility_id, _player.health, _belt.to_dict(), _experience.points)
	_hud.text = "Down to the %s..." % Branch.for_floor(next.floor_number).display_name
	await get_tree().create_timer(DESCEND_DELAY_SECONDS).timeout
	RunState.carry(next)
	_restart()


## A moment to see what happened, then the run's summary, until the player starts over.
func _end_run(ending: RunSummary.Ending) -> void:
	if _run_over:
		return
	_run_over = true
	_hud.text = RunSummary.title(ending)
	await get_tree().create_timer(SUMMARY_DELAY_SECONDS).timeout
	get_tree().paused = true
	_hud_layer.hide()
	_run_summary.show_summary(ending, RunSummary.lines(_run, _experience.level(), ending, _player.last_hurt_by))


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
