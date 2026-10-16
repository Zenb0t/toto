extends Node2D
## Composition root: builds the test dungeon, spawns actors, routes touch intents to the player,
## and applies the room-lock rules.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const RESTART_DELAY_SECONDS := 1.5

var _map: DungeonMap
var _view: DungeonView
var _progress: DungeonProgress
var _player: Player
var _enemies_by_room := {}  # int -> Array[Enemy]

@onready var _hud: Label = $Hud/Status
@onready var _move_stick: TouchStick = $TouchControls/MoveStick
@onready var _attack_button: AimButton = $TouchControls/AttackButton
@onready var _utility_button: AimButton = $TouchControls/UtilityButton


func _ready() -> void:
	_map = DungeonMapParser.new().parse(TestDungeon.LAYOUT)
	_view = DungeonView.new()
	add_child(_view)
	move_child(_view, 0)
	_view.show_map(_map)

	_player = _spawn_player()
	_spawn_enemies()
	_progress = _create_progress()
	_connect_controls()
	_refresh_hud()


func _physics_process(_delta: float) -> void:
	_player.move(_move_input())
	_attack_button.set_cooldown_ratio(_player.attack_cooldown_ratio())
	_utility_button.set_cooldown_ratio(_player.dash_cooldown_ratio())
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
		func(direction: Vector2) -> void: _player.preview_aim(direction * Projectile.RANGE))
	_attack_button.aim_released.connect(_on_attack_released)
	_utility_button.aim_changed.connect(
		func(direction: Vector2) -> void: _player.preview_aim(direction * Player.DASH_DISTANCE))
	_utility_button.aim_released.connect(_on_utility_released)


# --- Input routing -------------------------------------------------------------------------------

## Touch stick first; WASD as a desktop fallback.
func _move_input() -> Vector2:
	var touch := _move_stick.current_strength()
	if touch != Vector2.ZERO:
		return touch
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _on_attack_released(release: AimGesture.Release) -> void:
	_player.preview_aim(Vector2.ZERO)
	_player.attack(release.direction if not release.is_auto else _auto_aim_direction())


func _on_utility_released(release: AimGesture.Release) -> void:
	_player.preview_aim(Vector2.ZERO)
	_player.dash(release.direction if not release.is_auto else _player.facing)


## Nearest enemy in the room you're fighting in, or straight ahead if there is none.
func _auto_aim_direction() -> Vector2:
	var positions: Array[Vector2] = []
	for enemy: Enemy in _enemies_by_room.get(_progress.locked_room, []):
		positions.append(enemy.global_position)
	var target := AutoAim.nearest_index(_player.global_position, positions, Projectile.RANGE)
	if target == AutoAim.NO_TARGET:
		return _player.facing
	return _player.global_position.direction_to(positions[target])


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


func _on_attack_fired(origin: Vector2, direction: Vector2) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(origin, direction)
	add_child(projectile)


# --- Run state -----------------------------------------------------------------------------------

func _refresh_hud() -> void:
	_hud.text = "HP %d/%d    Enemies left: %d" % [
		_player.health.current, _player.health.maximum, _progress.total_enemies_left()]


func _end_run(message: String) -> void:
	_hud.text = message
	await get_tree().create_timer(RESTART_DELAY_SECONDS).timeout
	get_tree().reload_current_scene()
