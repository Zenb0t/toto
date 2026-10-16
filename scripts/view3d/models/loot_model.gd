class_name LootModel
extends Node3D
## Placeholder for an item on the floor: a gem in the item's colour that floats and turns, with the item's
## name above it. Weapons are round and utilities cubes, like the marks on the floor.

const FLOAT_HEIGHT := 0.55
const BOB_HEIGHT := 0.08
const BOB_SPEED := 3.0
const TURN_SPEED := 1.5
const GEM_SIZE := 0.32
const LABEL_HEIGHT := 1.15
const LABEL_PIXEL_SIZE := 0.008
const LABEL_FONT_SIZE := 40

var _gem: MeshInstance3D
var _label := Label3D.new()
var _shown: Item
var _time := 0.0


func _init() -> void:
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.pixel_size = LABEL_PIXEL_SIZE
	_label.font_size = LABEL_FONT_SIZE
	_label.outline_size = 10
	_label.position = Vector3(0, LABEL_HEIGHT, 0)
	add_child(_label)


func show_item(item: Item) -> void:
	if item == _shown:
		return
	_shown = item
	if _gem != null:
		_gem.queue_free()
	var mesh: Mesh = ModelParts.sphere(GEM_SIZE / 2.0) if item is Weapon else ModelParts.box(Vector3.ONE * GEM_SIZE)
	_gem = ModelParts.part(mesh, item.color, Vector3(0, FLOAT_HEIGHT, 0), true)
	add_child(_gem)
	_label.text = item.button_label
	_label.modulate = item.color


func shown_label() -> String:
	return _label.text


func _process(delta: float) -> void:
	_time += delta
	if _gem != null:
		_gem.position.y = FLOAT_HEIGHT + sin(_time * BOB_SPEED) * BOB_HEIGHT
		_gem.rotation.y = _time * TURN_SPEED
