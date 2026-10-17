class_name HeroBars
extends Node3D
## Brawl Stars style bars over the hero's head: health in green with the number on it, and below it the
## weapon's ammo, one orange segment per charge, the one reloading filling up. Shows what it is told.

const HEIGHT := CharacterModel.HEIGHT + 0.75
const HEALTH_SIZE := Vector2(1.3, 0.24)
const AMMO_HEIGHT := 0.15
const AMMO_GAP := 0.05
## Below the health bar, with a little space.
const AMMO_DROP := 0.24
const BACK_COLOR := Color(0.08, 0.07, 0.1, 0.85)
const HEALTH_COLOR := Color(0.35, 0.85, 0.35)
const AMMO_COLOR := Color(1.0, 0.6, 0.15)
const RELOADING_COLOR := Color(0.75, 0.45, 0.15)
const NUMBER_SIZE := 40
const NUMBER_PIXEL_SIZE := 0.006

var _health_fill: MeshInstance3D
var _number := Label3D.new()
var _ammo_fills: Array[MeshInstance3D] = []
var _ammo_root := Node3D.new()


func _init() -> void:
	var left := Vector3(-HEALTH_SIZE.x / 2.0, HEIGHT, 0)
	add_child(ModelParts.bar(HEALTH_SIZE, BACK_COLOR, 2, left))
	_health_fill = ModelParts.bar(HEALTH_SIZE, HEALTH_COLOR, 3, left)
	add_child(_health_fill)
	_number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_number.no_depth_test = true
	_number.render_priority = 4
	_number.font_size = NUMBER_SIZE
	_number.pixel_size = NUMBER_PIXEL_SIZE
	_number.outline_size = 8
	_number.position = Vector3(0, HEIGHT, 0)
	add_child(_number)
	add_child(_ammo_root)


## ammo_fills: how full each charge is, 0..1 (see Ammo.segment_fills).
func show_state(health: int, max_health: int, ammo_fills: Array[float]) -> void:
	_health_fill.scale.x = maxf(clampf(float(health) / maxi(max_health, 1), 0.0, 1.0), 0.001)
	_number.text = str(health)
	if ammo_fills.size() != _ammo_fills.size():
		_build_ammo(ammo_fills.size())
	for index in ammo_fills.size():
		var fill := ammo_fills[index]
		_ammo_fills[index].scale.x = maxf(fill, 0.001)
		_ammo_fills[index].visible = fill > 0.0
		(_ammo_fills[index].mesh.material as StandardMaterial3D).albedo_color = (
			AMMO_COLOR if fill >= 1.0 else RELOADING_COLOR)


## How many ammo segments show (one per charge).
func ammo_segments() -> int:
	return _ammo_fills.size()


func _build_ammo(count: int) -> void:
	for child in _ammo_root.get_children():
		child.queue_free()
	_ammo_fills.clear()
	var width := (HEALTH_SIZE.x - AMMO_GAP * (count - 1)) / count
	var size := Vector2(width, AMMO_HEIGHT)
	for index in count:
		var at := Vector3(-HEALTH_SIZE.x / 2.0 + index * (width + AMMO_GAP), HEIGHT - AMMO_DROP, 0)
		_ammo_root.add_child(ModelParts.bar(size, BACK_COLOR, 2, at))
		var fill := ModelParts.bar(size, AMMO_COLOR, 3, at)
		_ammo_root.add_child(fill)
		_ammo_fills.append(fill)
