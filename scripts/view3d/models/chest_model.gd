class_name ChestModel
extends Node3D
## Placeholder chest: a wooden box with a gold band, whose lid swings open.

const SIZE := Vector3(0.8, 0.45, 0.6)
const LID_HEIGHT := 0.18
const OPEN_ANGLE_DEGREES := -110.0
const WOOD_COLOR := Color(0.55, 0.35, 0.2)
const BAND_COLOR := Color(0.95, 0.75, 0.3)

## Hinged along the back edge of the box.
var _lid_hinge := Node3D.new()


func _init() -> void:
	add_child(ModelParts.part(ModelParts.box(SIZE), WOOD_COLOR, Vector3(0, SIZE.y / 2.0, 0)))
	add_child(ModelParts.part(
		ModelParts.box(Vector3(SIZE.x + 0.02, 0.06, SIZE.z + 0.02)), BAND_COLOR, Vector3(0, SIZE.y * 0.7, 0)))
	_lid_hinge.position = Vector3(0, SIZE.y, -SIZE.z / 2.0)
	add_child(_lid_hinge)
	var lid := Vector3(SIZE.x, LID_HEIGHT, SIZE.z)
	_lid_hinge.add_child(ModelParts.part(ModelParts.box(lid), WOOD_COLOR, Vector3(0, LID_HEIGHT / 2.0, SIZE.z / 2.0)))


func show_open(open: bool) -> void:
	_lid_hinge.rotation_degrees.x = OPEN_ANGLE_DEGREES if open else 0.0


func is_shown_open() -> bool:
	return _lid_hinge.rotation_degrees.x != 0.0
