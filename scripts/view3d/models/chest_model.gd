class_name ChestModel
extends Node3D
## A treasure chest (KayKit's), whose lid swings open.

const SIZE := 2.0
const OPEN_ANGLE_DEGREES := -100.0

var _lid: Node3D


func _init() -> void:
	var chest := PropModel.make("chest", SIZE)
	add_child(chest)
	_lid = chest.find_child("chest_lid", true, false)


func show_open(open: bool) -> void:
	_lid.rotation_degrees.x = OPEN_ANGLE_DEGREES if open else 0.0


func is_shown_open() -> bool:
	return _lid.rotation_degrees.x != 0.0
