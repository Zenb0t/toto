class_name CharacterModel
extends Node3D
## A hero or monster in 3D: a KayKit Adventurers model (see CharacterLook) with its weapon in hand,
## animated by what it does (standing, running, attacking, getting hurt), flashing white when hit, and,
## for enemies, a health bar above its head.

## How tall a character stands, in cells, before its monster's size.
const HEIGHT := 1.35
## How tall the KayKit models are, in their own units.
const MODEL_HEIGHT := 2.3
const HAND_BONE := "handslot.r"
## A model's own weapons and shields come off, so it can hold any weapon; the rest of its gear (hats, capes)
## is what makes it who it is, and stays.
const WEAPON_WORDS: Array[String] = [
	"Sword", "Axe", "Shield", "Crossbow", "Wand", "Staff", "Spellbook", "Knife", "Throwable", "Mug", "Blade",
]
## Headgear, which a bareheaded look takes off (see CharacterLook.wears_hat).
const HAT_WORDS: Array[String] = ["Helmet", "Hat", "Hood"]
## Skin is on the head and arms: what a race's tint colours.
const SKIN_PARTS: Array[String] = ["Head", "Arm"]
const IDLE := "Idle"
const RUN := "Running_A"
const HIT := "Hit_A"
const LOOPING: Array[String] = [IDLE, RUN]
const BLEND_SECONDS := 0.12
## Attacks play faster than authored: the game's swings are quick.
const ATTACK_SPEED := 1.6
const HIT_SECONDS := 0.3
const FLASH_SECONDS := 0.12
const HEALTH_BAR_HEIGHT := HEIGHT + 0.3
const HEALTH_BAR_SIZE := Vector2(0.8, 0.1)
const HEALTH_COLOR := Color(0.95, 0.3, 0.25)
const HEALTH_BACK_COLOR := Color(0.1, 0.08, 0.1, 0.8)

static var _shared_animations: AnimationLibrary

## Everything that turns with the character. The health bar stays level, so it isn't in here.
var _body := Node3D.new()
var _animations: AnimationPlayer
var _weapon_slot := BoneAttachment3D.new()
var _weapon_id := ""
var _meshes: Array[MeshInstance3D] = []
var _health_fill: MeshInstance3D
var _moving := false
var _action_left := 0.0
var _flash_left := 0.0


## With a health bar, the model shows how hurt it is (see show_health).
func _init(look: CharacterLook, with_health_bar := false) -> void:
	add_child(_body)
	var figure: Node3D = load(look.model_path()).instantiate()
	# The models face +Z; the game's front is -Z.
	figure.rotation.y = PI
	figure.scale = look.stretch * (HEIGHT / MODEL_HEIGHT)
	_body.add_child(figure)
	_dress(figure, look)
	var skeleton: Skeleton3D = figure.find_child("Skeleton3D", true, false)
	_weapon_slot.bone_name = HAND_BONE
	skeleton.add_child(_weapon_slot)
	_animations = _animation_player(figure)
	_animations.play(IDLE)
	if with_health_bar:
		add_child(_bar(HEALTH_BACK_COLOR, 0))
		_health_fill = _bar(HEALTH_COLOR, 1)
		add_child(_health_fill)


## Turns the model to face a direction on the 2D plane.
func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		_body.rotation.y = WorldSpace.yaw_toward(direction)


## Which way the model faces, as a direction on the 2D plane.
func facing() -> Vector2:
	var front := -_body.global_basis.z
	return Vector2(front.x, front.z).normalized()


## Puts a weapon's model in the right hand (see CharacterLook.weapon_model).
func hold(weapon_id: String) -> void:
	if weapon_id == _weapon_id:
		return
	_weapon_id = weapon_id
	for held in _weapon_slot.get_children():
		for mesh in _meshes_in(held):
			_meshes.erase(mesh)
		held.queue_free()
	var weapon: Node3D = load(CharacterLook.WEAPONS_PATH % CharacterLook.weapon_model(weapon_id)).instantiate()
	_weapon_slot.add_child(weapon)
	_meshes.append_array(_meshes_in(weapon))


func held_weapon_id() -> String:
	return _weapon_id


## Runs while moving, stands idle otherwise (unless an attack or a hit is playing).
func show_moving(moving: bool) -> void:
	_moving = moving


## Swings, shoots or casts, depending on the weapon in hand.
func play_attack() -> void:
	var attack := CharacterLook.attack_animation(_weapon_id)
	_animations.play(attack, BLEND_SECONDS, ATTACK_SPEED)
	_action_left = _animations.get_animation(attack).length / ATTACK_SPEED


## Flinches, unless in the middle of an attack.
func play_hit() -> void:
	if _action_left > 0.0:
		return
	_animations.play(HIT, BLEND_SECONDS)
	_action_left = HIT_SECONDS


func current_animation() -> String:
	return _animations.current_animation


## ratio: 0 (dead) to 1 (full health). The bar empties from the right.
func show_health(ratio: float) -> void:
	if _health_fill != null:
		_health_fill.scale.x = maxf(clampf(ratio, 0.0, 1.0), 0.001)


## Glows white for a moment, to show a hit landed.
func flash() -> void:
	_flash_left = FLASH_SECONDS
	_overlay(ModelParts.material(Color.WHITE, true))


func is_flashing() -> bool:
	return _flash_left > 0.0


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_overlay(null)
	if _action_left > 0.0:
		_action_left -= delta
		return
	var wanted := RUN if _moving else IDLE
	if _animations.current_animation != wanted:
		_animations.play(wanted, BLEND_SECONDS)


## Out of sight, nothing needs animating.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _animations != null:
		_animations.active = is_visible_in_tree()


## Takes off the model's weapons (it holds ours), keeps what it wears, and colours its skin.
func _dress(figure: Node3D, look: CharacterLook) -> void:
	var skin_tint := look.skin_tint
	var skeleton: Skeleton3D = figure.find_child("Skeleton3D", true, false)
	for child in skeleton.get_children():
		if child is BoneAttachment3D:
			var is_hat := _names_any(child.name, HAT_WORDS)
			if not _names_any(child.name, WEAPON_WORDS) and (look.wears_hat or not is_hat):
				_meshes.append_array(_meshes_in(child))
			else:
				child.free()
		elif child is MeshInstance3D:
			_meshes.append(child)
			if skin_tint != CharacterLook.NO_TINT and _names_any(child.name, SKIN_PARTS):
				_tint(child, skin_tint)


static func _names_any(part_name: String, words: Array[String]) -> bool:
	for word in words:
		if word in part_name:
			return true
	return false


static func _meshes_in(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		meshes.append(mesh)
	return meshes


static func _tint(mesh: MeshInstance3D, tint: Color) -> void:
	for surface in mesh.mesh.get_surface_count():
		var tinted: StandardMaterial3D = mesh.mesh.surface_get_material(surface).duplicate()
		tinted.albedo_color = tinted.albedo_color * tint
		mesh.set_surface_override_material(surface, tinted)


func _overlay(material: Material) -> void:
	for mesh in _meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = material


## The model's own player, or (for models imported without animations) a new one with the shared ones.
func _animation_player(figure: Node3D) -> AnimationPlayer:
	var player: AnimationPlayer = figure.find_child("AnimationPlayer", true, false)
	if player == null:
		player = AnimationPlayer.new()
		figure.add_child(player)
		player.add_animation_library("", _animations_for_all())
	else:
		_animations_for_all()  # Makes sure idling and running loop.
	return player


## The animations every model shares (they all use the same skeleton), with idling and running looped.
static func _animations_for_all() -> AnimationLibrary:
	if _shared_animations == null:
		var animated: Node = load(CharacterLook.new(CharacterLook.ANIMATED_MODEL).model_path()).instantiate()
		var player: AnimationPlayer = animated.find_child("AnimationPlayer", true, false)
		_shared_animations = player.get_animation_library("")
		for name in LOOPING:
			_shared_animations.get_animation(name).loop_mode = Animation.LOOP_LINEAR
		animated.free()
	return _shared_animations


## A flat bar above the head that always faces the camera. It starts at its left end, so scaling it
## along x empties it from the right.
func _bar(color: Color, draw_order: int) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = HEALTH_BAR_SIZE
	quad.center_offset = Vector3(HEALTH_BAR_SIZE.x / 2.0, 0, 0)
	var material := ModelParts.material(color, true)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = draw_order
	quad.material = material
	var bar := MeshInstance3D.new()
	bar.mesh = quad
	bar.position = Vector3(-HEALTH_BAR_SIZE.x / 2.0, HEALTH_BAR_HEIGHT, 0)
	return bar
