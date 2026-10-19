class_name LayoutEditor
extends Control
## Full-screen editor for the touch control layout: drag a control to move it, tap one and use the
## slider to resize it. Works on its own copy and reports every change, so the real controls can preview it.

signal layout_changed(layout: ControlLayout)
signal finished(layout: ControlLayout)

const NO_TOUCH := -1
const DIM_COLOR := Color(0.02, 0.01, 0.04, 0.45)
const RING_COLOR := Color(1, 1, 1, 0.55)
const SELECTED_COLOR := Color(1, 0.8, 0.3, 1)
const STICK_ZONE_COLOR := Color(1, 1, 1, 0.06)
const NAMES := {
	ControlLayout.STICK: "MOVE",
	ControlLayout.ATTACK: "ATTACK",
	ControlLayout.MOVEMENT: "DASH / BLINK",
	ControlLayout.SKILL: "SKILL",
}

var _layout := ControlLayout.new()
var _selected := ControlLayout.ATTACK
var _touch_index := NO_TOUCH
var _grab_offset := Vector2.ZERO

@onready var _bar: Control = $Bar
@onready var _size_slider: HSlider = $Bar/Size
@onready var _selected_label: Label = $Bar/Selected


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_size_slider.min_value = ControlLayout.MIN_DIAMETER
	_size_slider.max_value = ControlLayout.MAX_DIAMETER
	_size_slider.value_changed.connect(_on_size_changed)
	$Bar/Reset.pressed.connect(_on_reset_pressed)
	$Bar/Done.pressed.connect(_on_done_pressed)
	hide()


func open(layout: ControlLayout) -> void:
	_layout = layout.copy()
	_touch_index = NO_TOUCH
	_select(ControlLayout.ATTACK)
	show()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_layout.set_center(_selected, (event.position + _grab_offset) / _screen_size())
		_report_change()


func _on_touch(event: InputEventScreenTouch) -> void:
	if not event.pressed:
		if event.index == _touch_index:
			_touch_index = NO_TOUCH
		return
	if _touch_index != NO_TOUCH or _bar.get_global_rect().has_point(event.position):
		return
	var id := _layout.control_at(event.position, _screen_size())
	if id == ControlLayout.NONE:
		return
	_select(id)
	_touch_index = event.index
	_grab_offset = _layout.rect_in(id, _screen_size()).get_center() - event.position
	get_viewport().set_input_as_handled()


func _select(id: StringName) -> void:
	_selected = id
	_selected_label.text = NAMES[id]
	_size_slider.set_value_no_signal(_layout.diameter_of(id))
	queue_redraw()


func _on_size_changed(diameter: float) -> void:
	_layout.set_diameter(_selected, diameter)
	_report_change()


func _on_reset_pressed() -> void:
	_layout = ControlLayout.new()
	_select(_selected)
	_report_change()


func _on_done_pressed() -> void:
	hide()
	finished.emit(_layout)


func _report_change() -> void:
	queue_redraw()
	layout_changed.emit(_layout)


func _screen_size() -> Vector2:
	return get_viewport_rect().size


func _draw() -> void:
	var screen := _screen_size()
	draw_rect(Rect2(Vector2.ZERO, screen), DIM_COLOR)
	draw_rect(ControlLayout.stick_zone(screen), STICK_ZONE_COLOR)
	var font := ThemeDB.fallback_font
	for id in ControlLayout.IDS:
		var rect := _layout.rect_in(id, screen)
		var is_selected := id == _selected
		var color := SELECTED_COLOR if is_selected else RING_COLOR
		draw_arc(rect.get_center(), rect.size.x / 2.0, 0.0, TAU, 64, color, 6.0 if is_selected else 3.0, true)
		var text: String = NAMES[id]
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		var label_at := Vector2(rect.get_center().x - text_size.x / 2.0, rect.position.y - 10.0)
		draw_string(font, label_at, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, color)
