class_name CharacterModel
extends Node3D
## Placeholder hero or enemy: a capsule body with a round head, eyes that show which way it faces, and the
## weapon in its hand in the weapon's colour. A race adds a feature (pointy ears, tusks, a beard) so the
## peoples of the dungeon tell apart. Stands in until real models arrive.

const BODY_RADIUS := 0.36
const BODY_HEIGHT := 0.85
const HEAD_RADIUS := 0.27
const EYE_COLOR := Color(0.05, 0.05, 0.08)
const WEAPON_SIZE := Vector3(0.12, 0.12, 0.55)
const HEALTH_BAR_HEIGHT := 1.65
const HEALTH_BAR_SIZE := Vector2(0.8, 0.1)
const HEALTH_COLOR := Color(0.95, 0.3, 0.25)
const HEALTH_BACK_COLOR := Color(0.1, 0.08, 0.1, 0.8)
const TUSK_COLOR := Color(0.95, 0.92, 0.8)
const BEARD_COLOR := Color(0.55, 0.35, 0.2)

## Everything that turns with the character. The health bar stays level, so it isn't in here.
var _body := Node3D.new()
var _weapon: MeshInstance3D
var _health_fill: MeshInstance3D


## With a health bar, the model shows how hurt it is (see show_health). race: see Monster.race.
func _init(body_color: Color, with_health_bar := false, race := "") -> void:
	add_child(_body)
	_body.add_child(ModelParts.part(
		ModelParts.capsule(BODY_RADIUS, BODY_HEIGHT), body_color, Vector3(0, BODY_HEIGHT / 2.0, 0)))
	var head_center := Vector3(0, BODY_HEIGHT + HEAD_RADIUS * 0.6, 0)
	_body.add_child(ModelParts.part(ModelParts.sphere(HEAD_RADIUS), body_color.lightened(0.25), head_center))
	for side: float in [-1.0, 1.0]:
		var eye := head_center + Vector3(side * HEAD_RADIUS * 0.4, HEAD_RADIUS * 0.15, -HEAD_RADIUS * 0.9)
		_body.add_child(ModelParts.part(ModelParts.box(Vector3(0.07, 0.1, 0.04)), EYE_COLOR, eye))
	_add_race_feature(race, head_center, body_color)
	_weapon = ModelParts.part(
		ModelParts.box(WEAPON_SIZE), Color.WHITE, Vector3(BODY_RADIUS + 0.06, BODY_HEIGHT * 0.5, -0.25))
	_body.add_child(_weapon)
	if with_health_bar:
		add_child(_bar(HEALTH_BACK_COLOR, 0))
		_health_fill = _bar(HEALTH_COLOR, 1)
		add_child(_health_fill)


func _add_race_feature(race: String, head_center: Vector3, body_color: Color) -> void:
	match race:
		"kobold", "goblin", "elf":
			for side: float in [-1.0, 1.0]:
				var ear := ModelParts.part(ModelParts.box(Vector3(0.26, 0.07, 0.1)), body_color.darkened(0.15),
					head_center + Vector3(side * HEAD_RADIUS * 1.05, HEAD_RADIUS * 0.3, 0))
				ear.rotation.z = side * 0.5
				_body.add_child(ear)
		"orc", "ogre":
			for side: float in [-1.0, 1.0]:
				_body.add_child(ModelParts.part(ModelParts.box(Vector3(0.05, 0.12, 0.05)), TUSK_COLOR,
					head_center + Vector3(side * HEAD_RADIUS * 0.35, -HEAD_RADIUS * 0.45, -HEAD_RADIUS * 0.85)))
		"dwarf":
			_body.add_child(ModelParts.part(ModelParts.box(Vector3(0.36, 0.34, 0.14)), BEARD_COLOR,
				head_center + Vector3(0, -HEAD_RADIUS * 0.75, -HEAD_RADIUS * 0.7)))


## Turns the model to face a direction on the 2D plane.
func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		_body.rotation.y = WorldSpace.yaw_toward(direction)


## Which way the model faces, as a direction on the 2D plane.
func facing() -> Vector2:
	var front := -_body.global_basis.z
	return Vector2(front.x, front.z).normalized()


## Paints the weapon in hand.
func hold(weapon_color: Color) -> void:
	var weapon_material: StandardMaterial3D = _weapon.material_override
	weapon_material.albedo_color = weapon_color


## ratio: 0 (dead) to 1 (full health). The bar empties from the right.
func show_health(ratio: float) -> void:
	if _health_fill != null:
		_health_fill.scale.x = maxf(clampf(ratio, 0.0, 1.0), 0.001)


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
