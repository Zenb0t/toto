class_name ControlLayout
extends RefCounted
## Where each touch control sits and how big it is.
## Centers are fractions of the screen, so a layout keeps its shape on phones with different aspect ratios.
## Diameters are in viewport pixels.

const STICK := &"stick"
const ATTACK := &"attack"
const UTILITY := &"utility"
const IDS: Array[StringName] = [STICK, ATTACK, UTILITY]
const NONE := &""

const MIN_DIAMETER := 80.0
const MAX_DIAMETER := 320.0
## The stick floats inside the left half of the screen, so its resting spot stays there too.
const STICK_MAX_X := 0.5
## ...below the top of the screen, which is left to the status lines and the Map button.
const STICK_MIN_Y := 0.22
## Extra reach around a control when picking it up with a thumb.
const GRAB_SLOP := 24.0

const _DEFAULT_CENTERS := {
	STICK: Vector2(0.15, 0.74),
	ATTACK: Vector2(0.86, 0.66),
	UTILITY: Vector2(0.69, 0.82),
}
const _DEFAULT_DIAMETERS := {
	STICK: 190.0,
	ATTACK: 190.0,
	UTILITY: 140.0,
}

var _centers := _DEFAULT_CENTERS.duplicate()
var _diameters := _DEFAULT_DIAMETERS.duplicate()


## Rebuilds a layout from saved data. Anything missing or malformed falls back to the default.
static func from_dict(data: Dictionary) -> ControlLayout:
	var layout := ControlLayout.new()
	for id in IDS:
		var entry: Variant = data.get(String(id))
		if not entry is Dictionary:
			continue
		var center: Variant = entry.get("center")
		var diameter: Variant = entry.get("diameter")
		if center is Vector2:
			layout.set_center(id, center)
		if diameter is float or diameter is int:
			layout.set_diameter(id, diameter)
	return layout


func to_dict() -> Dictionary:
	var data := {}
	for id in IDS:
		data[String(id)] = {"center": _centers[id], "diameter": _diameters[id]}
	return data


func copy() -> ControlLayout:
	return ControlLayout.from_dict(to_dict())


func center_of(id: StringName) -> Vector2:
	return _centers[id]


func diameter_of(id: StringName) -> float:
	return _diameters[id]


func set_center(id: StringName, fraction: Vector2) -> void:
	var zone := Rect2(0.0, STICK_MIN_Y, STICK_MAX_X, 1.0 - STICK_MIN_Y) if id == STICK else Rect2(0, 0, 1, 1)
	_centers[id] = fraction.clamp(zone.position, zone.end)


## Where a thumb brings up the move stick: the left half of the screen, below the status lines and the Map
## button, so a tap on those isn't taken for a move.
static func stick_zone(screen_size: Vector2) -> Rect2:
	return Rect2(0.0, screen_size.y * STICK_MIN_Y, screen_size.x * STICK_MAX_X, screen_size.y * (1.0 - STICK_MIN_Y))


func set_diameter(id: StringName, diameter: float) -> void:
	_diameters[id] = clampf(diameter, MIN_DIAMETER, MAX_DIAMETER)


## The square a control occupies on a screen of the given size, nudged so it never sticks out of the screen.
func rect_in(id: StringName, screen_size: Vector2) -> Rect2:
	var diameter := minf(_diameters[id], minf(screen_size.x, screen_size.y))
	var size := Vector2(diameter, diameter)
	var top_left: Vector2 = _centers[id] * screen_size - size / 2.0
	top_left = top_left.clamp(Vector2.ZERO, screen_size - size)
	return Rect2(top_left, size)


## The control under a screen point (topmost first), or NONE.
func control_at(point: Vector2, screen_size: Vector2) -> StringName:
	for i in range(IDS.size() - 1, -1, -1):
		var rect := rect_in(IDS[i], screen_size)
		if point.distance_to(rect.get_center()) <= rect.size.x / 2.0 + GRAB_SLOP:
			return IDS[i]
	return NONE
