class_name CampfireModel
extends Node3D
## A campfire: a ring of stones round crossed logs and a flickering flame that lights the ground about it. Scenery
## for now (it will be a place to rest). It shows once its cell has been seen, and burns bright only while in sight.

const STONE_COLOR := Color(0.5, 0.48, 0.46)
const LOG_COLOR := Color(0.38, 0.24, 0.13)
const FLAME_COLOR := Color(1.0, 0.72, 0.3)
const EMBER_COLOR := Color(1.0, 0.4, 0.12)
const LIGHT_COLOR := Color(1.0, 0.62, 0.3)
const LIGHT_RANGE := 5.0
const LIGHT_ENERGY := 1.6
const STONE_COUNT := 7
const STONE_RING_RADIUS := 0.36
const FLICKER_SPEED := 11.0
const FLICKER_AMOUNT := 0.2

var _flame := Node3D.new()
var _light := OmniLight3D.new()
var _time := randf() * TAU
var _lit := true


func _init() -> void:
	for i in STONE_COUNT:
		var angle := TAU * i / STONE_COUNT
		add_child(ModelParts.part(ModelParts.box(Vector3(0.16, 0.12, 0.14)), STONE_COLOR,
			Vector3(cos(angle), 0.06, sin(angle)) * STONE_RING_RADIUS))
	for angle in [0.4, 1.97]:
		var log := ModelParts.part(ModelParts.box(Vector3(0.62, 0.1, 0.1)), LOG_COLOR, Vector3(0, 0.1, 0))
		log.rotation.y = angle
		add_child(log)
	add_child(_flame)
	_flame.add_child(ModelParts.part(ModelParts.sphere(0.2), EMBER_COLOR, Vector3(0, 0.22, 0), true))
	_flame.add_child(ModelParts.part(ModelParts.sphere(0.12), FLAME_COLOR, Vector3(0, 0.36, 0), true))
	_light.light_color = LIGHT_COLOR
	_light.omni_range = LIGHT_RANGE
	_light.light_energy = LIGHT_ENERGY
	_light.position = Vector3(0, 0.6, 0)
	add_child(_light)


## Stands on a cell; shows once seen (brightness: see MapView3D.HIDDEN, REMEMBERED_BRIGHTNESS, LIT).
func show_at(cell: Vector2i, brightness: float) -> void:
	position = WorldSpace.to_3d(DungeonView.cell_center(cell))
	visible = brightness > MapView3D.HIDDEN
	_lit = brightness >= MapView3D.LIT
	_flame.visible = _lit
	_light.visible = _lit


func is_burning() -> bool:
	return visible and _lit


func _process(delta: float) -> void:
	if not is_burning():
		return
	_time += delta
	var flicker := 1.0 + sin(_time * FLICKER_SPEED) * FLICKER_AMOUNT * 0.6 + sin(_time * 19.0) * FLICKER_AMOUNT * 0.4
	_flame.scale = Vector3(1.0, flicker, 1.0)
	_light.light_energy = LIGHT_ENERGY * (0.9 + 0.1 * flicker)
