class_name CampfireModel
extends Node3D
## A campfire: a ring of stones round crossed logs. Its look follows the fire's state (see Campfire): unlit, cold
## stones; burning, a flickering flame that lights the ground about it; embers, a dim glow with the seconds left
## before it can be lit again floating over it. A camp's fire, held by its band, burns for them. It shows once its
## cell has been seen, and its flame, glow and countdown only while in sight.

const STONE_COLOR := Color(0.5, 0.48, 0.46)
const LOG_COLOR := Color(0.38, 0.24, 0.13)
const FLAME_COLOR := Color(1.0, 0.72, 0.3)
const EMBER_COLOR := Color(1.0, 0.4, 0.12)
const COAL_COLOR := Color(0.75, 0.22, 0.08)
const COUNTDOWN_COLOR := Color(1.0, 0.7, 0.4)
const LIGHT_COLOR := Color(1.0, 0.62, 0.3)
const LIGHT_RANGE := 5.0
const LIGHT_ENERGY := 1.6
## An ember glow is a fraction of a flame's.
const EMBERS_LIGHT_SHARE := 0.25
const STONE_COUNT := 7
const STONE_RING_RADIUS := 0.36
const FLICKER_SPEED := 11.0
const FLICKER_AMOUNT := 0.2
const COUNTDOWN_HEIGHT := 1.0
const COUNTDOWN_FONT_SIZE := 40
const COUNTDOWN_PIXEL_SIZE := 0.01

var _flame := Node3D.new()
var _coals := Node3D.new()
var _light := OmniLight3D.new()
var _countdown := Label3D.new()
var _time := randf() * TAU
var _in_sight := true
var _state := Campfire.State.UNLIT
var _seconds_left := 0.0
## Held by a band: it burns for them whatever its state.
var _held := false


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
	add_child(_coals)
	_coals.add_child(ModelParts.part(ModelParts.sphere(0.16), COAL_COLOR, Vector3(0, 0.16, 0), true))
	_light.light_color = LIGHT_COLOR
	_light.omni_range = LIGHT_RANGE
	_light.light_energy = LIGHT_ENERGY
	_light.position = Vector3(0, 0.6, 0)
	add_child(_light)
	_countdown.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_countdown.no_depth_test = true
	_countdown.modulate = COUNTDOWN_COLOR
	_countdown.font_size = COUNTDOWN_FONT_SIZE
	_countdown.pixel_size = COUNTDOWN_PIXEL_SIZE
	_countdown.outline_size = 12
	_countdown.position = Vector3(0, COUNTDOWN_HEIGHT, 0)
	add_child(_countdown)
	_refresh()


## Stands on a cell; shows once seen (brightness: see MapView3D.HIDDEN, REMEMBERED_BRIGHTNESS, LIT).
func show_at(cell: Vector2i, brightness: float) -> void:
	position = WorldSpace.to_3d(DungeonView.cell_center(cell))
	visible = brightness > MapView3D.HIDDEN
	_in_sight = brightness >= MapView3D.LIT
	_refresh()


## The fire's state, and the seconds until it changes. held: a band holds it, so it burns for them.
func show_rest(state: Campfire.State, seconds_left: float, held := false) -> void:
	_state = state
	_seconds_left = seconds_left
	_held = held
	_refresh()


func is_burning() -> bool:
	return visible and _in_sight and (_held or _state == Campfire.State.BURNING)


func is_in_embers() -> bool:
	return visible and _in_sight and not _held and _state == Campfire.State.EMBERS


## The countdown over the embers ("" when there is none).
func countdown_text() -> String:
	return _countdown.text if _countdown.visible else ""


func _refresh() -> void:
	var embers := is_in_embers()
	_flame.visible = is_burning()
	_coals.visible = embers
	_light.visible = is_burning() or embers
	_light.light_energy = LIGHT_ENERGY * (EMBERS_LIGHT_SHARE if embers else 1.0)
	_countdown.visible = embers
	if embers:
		_countdown.text = "Embers %d s" % ceili(_seconds_left)


func _process(delta: float) -> void:
	if not is_burning():
		return
	_time += delta
	var flicker := 1.0 + sin(_time * FLICKER_SPEED) * FLICKER_AMOUNT * 0.6 + sin(_time * 19.0) * FLICKER_AMOUNT * 0.4
	_flame.scale = Vector3(1.0, flicker, 1.0)
	_light.light_energy = LIGHT_ENERGY * (0.9 + 0.1 * flicker)
