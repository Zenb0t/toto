class_name WorldView3D
extends Node3D
## The game as the player sees it: a 3D scene built over the 2D world that runs it. A fixed, Brawl
## Stars-style camera follows the hero; the 2D plane lies on the floor (GroundView); walls and closed
## doors stand on it (MapView3D); actors get 3D stand-ins that copy them (Puppets). Owns no game rules.

const LIGHT_ROTATION_DEGREES := Vector3(-55.0, -25.0, 0.0)
const AMBIENT_COLOR := Color(0.6, 0.6, 0.7)
const AMBIENT_ENERGY := 0.8
## How far up the screen from the camera's aim the floor texture is centred, in cells: a tilted camera
## sees farther ahead than behind.
const GROUND_LEAD := 2.0

## Where the camera sits. Takes effect on the next frame.
var framing := CameraFraming.new()

var _camera := Camera3D.new()
var _ground := GroundView.new()
var _map := MapView3D.new()
var _puppets := Puppets.new()
var _hero: Node2D


func _init() -> void:
	add_child(_ground)
	add_child(_map)
	add_child(_puppets)
	add_child(_camera)
	_add_lighting()


## plane: the root of the 2D world, drawn on the floor from now on. Call once this view is in the tree.
func show_world(plane: CanvasItem, wall_cells: Array[Vector2i], door_cells: Array[Vector2i]) -> void:
	_ground.lay_down(plane)
	_map.show_map(wall_cells, door_cells)
	_camera.current = true


func set_wall_height(height: float) -> void:
	_map.wall_height = height


func set_doors_closed(door_cells: Array[Vector2i], closed: bool) -> void:
	_map.set_doors_closed(door_cells, closed)


func show_exploration(exploration: Exploration) -> void:
	_map.show_exploration(exploration)


## The camera follows the player.
func add_player(player: Player) -> void:
	_hero = player
	_puppets.add(player, CharacterModel.new(Player.BODY_COLOR), func(model: CharacterModel) -> void:
		model.face(player.facing)
		model.hold(player.weapon.color))


func add_enemy(enemy: Enemy) -> void:
	_puppets.add(enemy, CharacterModel.new(Enemy.BODY_COLOR, true), func(model: CharacterModel) -> void:
		model.face(enemy.facing)
		model.hold(enemy.weapon.color)
		model.show_health(float(enemy.health.current) / enemy.health.maximum))


func add_projectile(projectile: Projectile) -> void:
	var shot := projectile.shot()
	_puppets.add(projectile, ShotModel.new(shot.color, shot.size), func(model: ShotModel) -> void:
		model.lift(projectile.height()))


func add_chest(chest: Chest) -> void:
	_puppets.add(chest, ChestModel.new(), func(model: ChestModel) -> void:
		model.show_open(chest.is_open()))


func add_drop(drop: ItemDrop) -> void:
	_puppets.add(drop, LootModel.new(), func(model: LootModel) -> void:
		model.show_item(drop.item))


func add_potion(drop: PotionDrop) -> void:
	_puppets.add(drop, LootModel.new(), func(model: LootModel) -> void:
		model.show_potion(drop.potion))


func _process(_delta: float) -> void:
	if not is_instance_valid(_hero):
		return
	var focus := WorldSpace.to_3d(_hero.global_position)
	_camera.position = framing.eye(focus)
	_camera.rotation = Vector3(-deg_to_rad(framing.pitch_degrees), 0.0, 0.0)
	_camera.fov = framing.field_of_view
	var lead := (framing.look_ahead + GROUND_LEAD) * DungeonView.TILE_SIZE
	_ground.show_around(_hero.global_position + Vector2(0.0, -lead))


func _add_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = LIGHT_ROTATION_DEGREES
	add_child(sun)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = AMBIENT_COLOR
	environment.ambient_light_energy = AMBIENT_ENERGY
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
