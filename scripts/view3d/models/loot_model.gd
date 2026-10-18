class_name LootModel
extends Node3D
## Something on the floor, floating and turning, with its name above it: a weapon shows itself (the model
## characters hold), a utility a glowing cube and a potion a flask, in their colours. A weapon with no model
## (the knuckles) gets the utilities' glowing cube in its colour.

enum Look { WEAPON, CUBE, FLASK }

const FLOAT_HEIGHT := 0.55
const BOB_HEIGHT := 0.08
const BOB_SPEED := 3.0
const TURN_SPEED := 1.5
const GEM_SIZE := 0.32
const FLASK_NECK_COLOR := Color(0.85, 0.8, 0.7)
## Weapon models are sized for a character's hand (see CharacterModel); on the floor, a bit bigger.
const WEAPON_SCALE := 1.4
const LABEL_HEIGHT := 1.15
const LABEL_PIXEL_SIZE := 0.008
const LABEL_FONT_SIZE := 40

var _gem: Node3D
var _label := Label3D.new()
var _shown: Object
var _weapon_id := ""
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
	if item != _shown:
		_shown = item
		_weapon_id = item.id
		var modelled := item is Weapon and WeaponModel.has_model(item.id)
		_show(item.color, item.button_label, Look.WEAPON if modelled else Look.CUBE)


func show_potion(potion: Potion) -> void:
	if potion != _shown:
		_shown = potion
		_show(potion.color, potion.button_label, Look.FLASK)


func shown_label() -> String:
	return _label.text


func _show(color: Color, label: String, look: Look) -> void:
	if _gem != null:
		_gem.queue_free()
	_gem = _shape(color, look)
	_gem.position.y = FLOAT_HEIGHT
	add_child(_gem)
	_label.text = label
	_label.modulate = color


func _shape(color: Color, look: Look) -> Node3D:
	match look:
		Look.WEAPON:
			var weapon := WeaponModel.instance(_weapon_id)
			weapon.scale = Vector3.ONE * CharacterModel.HEIGHT / CharacterModel.MODEL_HEIGHT * WEAPON_SCALE
			weapon.rotation.z = PI / 2.0
			var holder := Node3D.new()
			holder.add_child(weapon)
			return holder
		Look.CUBE:
			return ModelParts.part(ModelParts.box(Vector3.ONE * GEM_SIZE), color, Vector3.ZERO, true)
	var flask := Node3D.new()
	flask.add_child(ModelParts.part(ModelParts.sphere(GEM_SIZE * 0.55), color, Vector3.ZERO, true))
	flask.add_child(ModelParts.part(
		ModelParts.box(Vector3(0.09, 0.16, 0.09)), FLASK_NECK_COLOR, Vector3(0, GEM_SIZE * 0.6, 0)))
	return flask


func _process(delta: float) -> void:
	_time += delta
	if _gem != null:
		_gem.position.y = FLOAT_HEIGHT + sin(_time * BOB_SPEED) * BOB_HEIGHT
		_gem.rotation.y = _time * TURN_SPEED
