extends Node2D
## Composition root: builds a floor, places the hero and enemies, and runs the win/lose loop.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const ENEMIES_PER_ROOM := 2
const RESTART_DELAY_SECONDS := 1.5

var _player: Player
var _enemies_left := 0

@onready var _hud: Label = $Hud/Label


func _ready() -> void:
	var seed_value := randi()
	var layout := DungeonGenerator.new().generate(seed_value)

	var view := DungeonView.new()
	add_child(view)
	view.show_layout(layout)

	_player = _spawn_player(layout)
	_spawn_enemies(layout, seed_value, _player)
	_refresh_hud()


func _spawn_player(layout: DungeonLayout) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = DungeonView.cell_center(layout.room_center(0))
	player.shot_fired.connect(_on_shot_fired)
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	add_child(player)
	return player


func _spawn_enemies(layout: DungeonLayout, seed_value: int, player: Player) -> void:
	for cell in SpawnPlanner.new().plan_enemy_cells(layout, seed_value, ENEMIES_PER_ROOM):
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.position = DungeonView.cell_center(cell)
		enemy.defeated.connect(_on_enemy_defeated)
		add_child(enemy)
		enemy.chase(player)
		_enemies_left += 1


func _on_shot_fired(origin: Vector2, direction: Vector2) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(origin, direction)
	add_child(projectile)


func _on_player_health_changed(_current: int, _maximum: int) -> void:
	_refresh_hud()


func _refresh_hud() -> void:
	_hud.text = "HP %d/%d    Enemies left: %d" % [_player.health.current, _player.health.maximum, _enemies_left]


func _on_enemy_defeated(_enemy: Enemy) -> void:
	_enemies_left -= 1
	_refresh_hud()
	if _enemies_left == 0:
		_end_run("Floor cleared!")


func _on_player_died() -> void:
	_end_run("You died...")


func _end_run(message: String) -> void:
	_hud.text = message
	await get_tree().create_timer(RESTART_DELAY_SECONDS).timeout
	get_tree().reload_current_scene()
