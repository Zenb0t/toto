class_name TuningPanel
extends Control
## Full-screen editor for gameplay tuning. One row per knob, generated from the Tuning's params
## (optionally only some groups, e.g. just the equipped weapon's):
## a slider for big moves and -/+ buttons for exact steps. Works on its own copy and reports every
## change, so the game can apply it live.

signal tuning_changed(tuning: Tuning)
signal finished(tuning: Tuning)

const FONT_SIZE := 20
const HEADER_FONT_SIZE := 22
const ROW_HEIGHT := 56.0
const LABEL_WIDTH := 190.0
const VALUE_WIDTH := 80.0
const DEFAULT_COLOR := Color(1, 1, 1, 0.9)
const CHANGED_COLOR := Color(1, 0.8, 0.3)
const HEADER_COLOR := Color(0.45, 0.85, 1)


## The widgets of one knob's row, kept so the row can be refreshed without rebuilding it.
class Row:
	var slider: HSlider
	var value_label: Label

	func _init(row_slider: HSlider, row_value_label: Label) -> void:
		slider = row_slider
		value_label = row_value_label


var _tuning: Tuning
var _rows := {}  # param key -> Row

@onready var _columns: Array[VBoxContainer] = [$Scroll/Columns/Left, $Scroll/Columns/Right]
@onready var _send_button: Button = $Bar/Send


func _ready() -> void:
	$Bar/Reset.pressed.connect(_on_reset_pressed)
	_send_button.pressed.connect(func() -> void: TuningSender.send(_tuning.export_text()))
	_send_button.visible = TuningSender.is_available()
	$Bar/Done.pressed.connect(_on_done_pressed)
	hide()


## Shows the given groups, or every group when none are given.
func open(tuning: Tuning, groups: Array[String] = []) -> void:
	_tuning = tuning.copy()
	_build_rows(groups if not groups.is_empty() else _all_groups())
	_refresh_all()
	show()


## Moves a knob by whole steps, as the -/+ buttons do.
func nudge(key: String, steps: int) -> void:
	_change(key, _tuning.value(key) + steps * _tuning.param(key).step)


func _change(key: String, new_value: float) -> void:
	_tuning.set_value(key, new_value)
	_refresh_row(key)
	tuning_changed.emit(_tuning)


func _on_reset_pressed() -> void:
	_tuning.reset()
	_refresh_all()
	tuning_changed.emit(_tuning)


func _on_done_pressed() -> void:
	hide()
	finished.emit(_tuning)


# --- Building and refreshing rows ----------------------------------------------------------------

## Groups go to whichever column is shorter, so the screen fills evenly without scrolling.
func _build_rows(groups: Array[String]) -> void:
	_clear_rows()
	var heights: Array[int] = [0, 0]
	for group in groups:
		var column := 0 if heights[0] <= heights[1] else 1
		var params := _params_in(group)
		_columns[column].add_child(_header(group))
		for each in params:
			_columns[column].add_child(_row(each))
		heights[column] += params.size() + 1


func _clear_rows() -> void:
	_rows.clear()
	for column in _columns:
		for child in column.get_children():
			column.remove_child(child)
			child.free()


func _all_groups() -> Array[String]:
	var groups: Array[String] = []
	for each in _tuning.params():
		if each.group not in groups:
			groups.append(each.group)
	return groups


func _params_in(group: String) -> Array[Tuning.Param]:
	var params: Array[Tuning.Param] = []
	params.assign(_tuning.params().filter(func(each: Tuning.Param) -> bool: return each.group == group))
	return params


func _header(group: String) -> Label:
	var header := Label.new()
	header.text = group.to_upper()
	header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	header.add_theme_color_override("font_color", HEADER_COLOR)
	return header


func _row(param: Tuning.Param) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = param.key.replace(".", "_")
	row.custom_minimum_size.y = ROW_HEIGHT

	var name_label := _label(param.label + ("\n(next run)" if param.next_run_only else ""), LABEL_WIDTH)
	var minus := _step_button("-", func() -> void: nudge(param.key, -1))
	var slider := HSlider.new()
	slider.name = "Slider"
	slider.min_value = param.min_value
	slider.max_value = param.max_value
	slider.step = param.step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_FILL
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(new_value: float) -> void: _change(param.key, new_value))
	var plus := _step_button("+", func() -> void: nudge(param.key, 1))
	var value_label := _label("", VALUE_WIDTH)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	for child: Control in [name_label, minus, slider, plus, value_label]:
		row.add_child(child)
	_rows[param.key] = Row.new(slider, value_label)
	return row


func _label(text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label


func _step_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(ROW_HEIGHT, ROW_HEIGHT)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(on_pressed)
	return button


func _refresh_all() -> void:
	for key: String in _rows:
		_refresh_row(key)


func _refresh_row(key: String) -> void:
	var row: Row = _rows[key]
	var value := _tuning.value(key)
	row.slider.set_value_no_signal(value)
	row.value_label.text = _format(value, _tuning.param(key).step)
	var color := CHANGED_COLOR if _tuning.is_changed(key) else DEFAULT_COLOR
	row.value_label.add_theme_color_override("font_color", color)


static func _format(value: float, step: float) -> String:
	return "%.2f" % value if step < 1.0 else str(roundi(value))
