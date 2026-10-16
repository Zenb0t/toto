extends Node2D
## Composition root: builds the test dungeon, spawns actors, routes touch intents to the player,
## applies the room-lock rules, and connects the pause menu's settings screens.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const RESTART_DELAY_SECONDS := 1.5

var _map: DungeonMap
var _view: DungeonView
var _progress: DungeonProgress
var _player: Player
var _enemies_by_room := {}  # int -> Array[Enemy]
var _settings := GameSettings.new()
var _layout: ControlLayout
var _tuning: Tuning
var _weapon_id: String

@onready var _hud_layer: CanvasLayer = $Hud
@onready var _hud: Label = $Hud/Status
@onready var _weapon_switch: Button = $Hud/WeaponSwitch
@onready var _touch_controls: TouchControls = $TouchControls
@onready var _move_stick: TouchStick = $TouchControls/MoveStick
@onready var _attack_button: AimButton = $TouchControls/AttackButton
@onready var _utility_button: AimButton = $TouchControls/UtilityButton
@onready var _pause_menu: PauseMenu = $Overlay/PauseMenu
@onready var _layout_editor: LayoutEditor = $Overlay/LayoutEditor
@onready var _tuning_panel: TuningPanel = $Overlay/TuningPanel


func _ready() -> void:
	_map = DungeonMapParser.new().parse(TestDungeon.LAYOUT)
	_view = DungeonView.new()
	add_child(_view)
	move_child(_view, 0)
	_view.show_map(_map)
	_tuning = _settings.load_tuning()
	_layout = _settings.load_layout()
	_weapon_id = _settings.load_weapon_id()

	_player = _spawn_player()
	_spawn_enemies()
	_progress = _create_progress()
	_connect_controls()
	_connect_menu()
	_apply_tuning(_tuning)
	_touch_controls.apply_layout(_layout)
	_refresh_hud()


func _physics_process(_delta: float) -> void:
	_player.move(_move_input())
	_attack_button.set_cooldown_ratio(_player.attack_cooldown_ratio())
	_utility_button.set_cooldown_ratio(_player.utility_cooldown_ratio())
	_track_player_room()


# --- Setup ---------------------------------------------------------------------------------------

func _spawn_player() -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = DungeonView.cell_center(_map.player_spawn)
	player.attack_fired.connect(_on_attack_fired)
	player.health_changed.connect(func(_current: int, _maximum: int) -> void: _refresh_hud())
	player.died.connect(func() -> void: _end_run("You died..."))
	add_child(player)
	return player


func _spawn_enemies() -> void:
	for cell in _map.enemy_spawns:
		var room := _map.room_at(cell)
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.position = DungeonView.cell_center(cell)
		enemy.set_max_health(GameTuning.enemy_max_health(_tuning))
		enemy.defeated.connect(_on_enemy_defeated.bind(room))
		add_child(enemy)
		_enemies_by_room.get_or_add(room, []).append(enemy)


func _create_progress() -> DungeonProgress:
	var counts := {}
	for room: int in _enemies_by_room:
		counts[room] = _enemies_by_room[room].size()
	var progress := DungeonProgress.new(counts)
	progress.room_locked.connect(_on_room_locked)
	progress.room_cleared.connect(_on_room_cleared)
	progress.dungeon_cleared.connect(func() -> void: _end_run("Dungeon cleared!"))
	return progress


func _connect_controls() -> void:
	_attack_button.aim_changed.connect(
		func(direction: Vector2) -> void: _player.preview_aim(direction, _player.weapon.aim_shape()))
	_attack_button.aim_released.connect(_on_attack_released)
	_utility_button.aim_changed.connect(
		func(direction: Vector2) -> void: _player.preview_aim(direction, _player.utility.aim_shape()))
	_weapon_switch.pressed.connect(_on_weapon_switch_pressed)
	_utility_button.aim_released.connect(_on_utility_released)


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


# --- Input routing -------------------------------------------------------------------------------

## Touch stick first; WASD as a desktop fallback.
func _move_input() -> Vector2:
	var touch := _move_stick.current_strength()
	if touch != Vector2.ZERO:
		return touch
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _on_attack_released(release: AimGesture.Release) -> void:
	_player.preview_aim(Vector2.ZERO)
	if not release.is_auto:
		_player.attack(release.direction)
		return
	var target := _auto_aim_target()
	if target == null:
		_player.attack(_player.facing)
	else:
		_player.attack(_player.global_position.direction_to(target.global_position), target)


func _on_utility_released(release: AimGesture.Release) -> void:
	_player.preview_aim(Vector2.ZERO)
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
func _track_player_room() -> void:
	var cell := DungeonView.world_to_cell(_player.global_position)
	if _map.is_clear_of_doors(cell):
		_progress.enter_room(_map.room_at(cell))


func _on_room_locked(room: int) -> void:
	_view.set_room_closed(room, true)
	for enemy: Enemy in _enemies_by_room[room]:
		enemy.chase(_player)


func _on_room_cleared(room: int) -> void:
	_view.set_room_closed(room, false)


func _on_enemy_defeated(enemy: Enemy, room: int) -> void:
	_enemies_by_room[room].erase(enemy)
	_progress.record_defeat(room)
	_refresh_hud()


func _on_attack_fired(attacks: Array) -> void:
	for attack: Variant in attacks:
		if attack is Shot:
			var projectile: Projectile = PROJECTILE_SCENE.instantiate()
			projectile.launch(attack)
			add_child(projectile)
		elif attack is Slash:
			add_child(SlashEffect.new(attack))


# --- Equipment and tuning ------------------------------------------------------------------------

## Applies everything that can change mid-run. The rest (like enemy health) waits for the next run.
func _apply_tuning(tuning: Tuning) -> void:
	_player.move_speed = GameTuning.player_move_speed(tuning)
	_equip(GameTuning.weapon(tuning, _weapon_id), GameTuning.utility(tuning))
	_attack_button.dead_zone = GameTuning.weapon_dead_zone(tuning)
	_utility_button.dead_zone = GameTuning.utility_dead_zone(tuning)
	for enemies: Array in _enemies_by_room.values():
		for enemy: Enemy in enemies:
			enemy.move_speed = GameTuning.enemy_move_speed(tuning)


## The buttons always show what is equipped.
func _equip(weapon: Weapon, utility: Utility) -> void:
	_player.equip_weapon(weapon)
	_player.equip_utility(utility)
	_attack_button.label = weapon.button_label
	_attack_button.color = weapon.color
	_weapon_switch.text = "Weapon: %s" % weapon.button_label
	_utility_button.label = utility.button_label
	_utility_button.color = utility.color


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


## Testing aid: cycles through every weapon, keeping each one's own tuning.
func _on_weapon_switch_pressed() -> void:
	_weapon_id = GameTuning.next_weapon_id(_weapon_id)
	_apply_tuning(_tuning)
	_warn_if_failed(_settings.save_weapon_id(_weapon_id), "the weapon choice")


func _on_tuning_requested() -> void:
	_hud_layer.hide()
	_tuning_panel.open(_tuning, GameTuning.visible_groups(_tuning, _weapon_id))


func _on_tuning_finished(tuning: Tuning) -> void:
	_hud_layer.show()
	_tuning = tuning
	_apply_tuning(tuning)
	_warn_if_failed(_settings.save_tuning(tuning), "the tuning")
	_pause_menu.return_to_panel()


func _warn_if_failed(error: Error, what: String) -> void:
	if error != OK:
		push_warning("Could not save %s: %s" % [what, error_string(error)])


# --- Run state -----------------------------------------------------------------------------------

func _refresh_hud() -> void:
	_hud.text = "HP %d/%d    Enemies left: %d" % [
		_player.health.current, _player.health.maximum, _progress.total_enemies_left()]


func _end_run(message: String) -> void:
	_hud.text = message
	await get_tree().create_timer(RESTART_DELAY_SECONDS).timeout
	_restart()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
