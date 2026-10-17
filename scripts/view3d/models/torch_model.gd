class_name TorchModel
extends Node3D
## A torch on the camera-facing side of a wall: a mounted torch (KayKit's) and a flickering flame. It shows once its
## wall has been seen, and burns bright only while in sight.

const MOUNT_SHARE := 0.62
const BRACKET_SIZE := 1.6
const FLAME_COLOR := Color(1.0, 0.72, 0.3)
const EMBER_COLOR := Color(1.0, 0.4, 0.12)
const FLICKER_SPEED := 13.0
const FLICKER_AMOUNT := 0.18

var _flame := Node3D.new()
var _time := 0.0
var _lit := true


func _init() -> void:
	add_child(PropModel.make("torch_mounted", BRACKET_SIZE))
	add_child(_flame)
	_flame.position = Vector3(0, 0.3, 0.2)
	_flame.add_child(ModelParts.part(ModelParts.sphere(0.13), EMBER_COLOR, Vector3.ZERO, true))
	_flame.add_child(ModelParts.part(ModelParts.sphere(0.09), FLAME_COLOR, Vector3(0, 0.1, 0), true))
	# Each torch starts its flicker somewhere else, so they don't flicker in step (looks only).
	_time = randf() * TAU


## Hangs the torch on the south face of a wall cell, shown as brightly as the wall (see MapView3D).
func show_on_wall(cell: Vector2i, wall_height: float, brightness: float) -> void:
	var face := WorldSpace.to_3d(DungeonView.cell_center(cell)) + Vector3(0, wall_height * MOUNT_SHARE - 0.15, 0.5)
	position = face
	visible = brightness > MapView3D.HIDDEN
	_lit = brightness >= MapView3D.LIT
	_flame.visible = _lit


func _process(delta: float) -> void:
	if not visible or not _lit:
		return
	_time += delta
	var flicker := 1.0 + sin(_time * FLICKER_SPEED) * FLICKER_AMOUNT * 0.6 + sin(_time * 23.0) * FLICKER_AMOUNT * 0.4
	_flame.scale = Vector3(1.0, flicker, 1.0)
