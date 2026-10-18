class_name TuningPanel
extends Control
## Full-screen editor for gameplay tuning, in pages: a menu of sections (Player, Weapons, Enemies...), then,
## for a section with several groups, a list of them (every weapon...), then a group's knobs, one row each:
## a slider for big moves and -/+ buttons for exact steps. Back (or Esc) goes up a page. Menu entries
## that hold changed knobs are marked. Works on its own copy and reports every change, so the game can
## apply it live.

signal tuning_changed(tuning: Tuning)
signal finished(tuning: Tuning)
## From the World page: start the next world (a new seed), or this world's seed again. Both come after finished,
## so the tuning just edited is the one the new world is made with.
signal new_world_requested
signal same_seed_requested

const FONT_SIZE := 20
const MENU_FONT_SIZE := 26
const ROW_HEIGHT := 56.0
const MENU_BUTTON_HEIGHT := 76.0
const LABEL_WIDTH := 190.0
const VALUE_WIDTH := 80.0
const DEFAULT_COLOR := Color(1, 1, 1, 0.9)
const CHANGED_COLOR := Color(1, 0.8, 0.3)
const TITLE := "Tune"
const TITLE_SEPARATOR := "  ›  "
## Ends the entry of a section that opens onto a list rather than onto knobs.
const SUBMENU_MARK := "  ›"
const CHANGED_MARK := "  •"


## The widgets of one knob's row, kept so the row can be refreshed without rebuilding it.
class Row:
	var slider: HSlider
	var value_label: Label

	func _init(row_slider: HSlider, row_value_label: Label) -> void:
		slider = row_slider
		value_label = row_value_label


var _tuning: Tuning
var _sections: Array[TuningSection] = []
## The page showing: no section is the main menu; a section with no group is the list of its groups.
var _section: TuningSection
var _group := ""
var _world_seed := 0
var _rows := {}  # param key -> Row

@onready var _columns: Array[VBoxContainer] = [$Scroll/Columns/Left, $Scroll/Columns/Right]
@onready var _scroll: ScrollContainer = $Scroll
@onready var _title: Label = $Bar/Title
@onready var _back_button: Button = $Bar/Back
@onready var _reset_button: Button = $Bar/Reset
@onready var _send_button: Button = $Bar/Send


func _ready() -> void:
	_back_button.pressed.connect(back)
	_reset_button.pressed.connect(_on_reset_pressed)
	_send_button.pressed.connect(func() -> void: TuningSender.send(_tuning.export_text()))
	_send_button.visible = TuningSender.is_available()
	$Bar/Done.pressed.connect(_on_done_pressed)
	hide()


## sections: the menu (see GameTuning.sections). Opens on it. world_seed: the seed of the world being played,
## shown on the World page.
func open(tuning: Tuning, sections: Array[TuningSection], world_seed := 0) -> void:
	_tuning = tuning.copy()
	_sections = sections
	_world_seed = world_seed
	_show_page(null, "")
	show()


## Up one page. From the main menu, closes as Done does.
func back() -> void:
	if _section == null:
		_on_done_pressed()
	elif _group != "" and _section.has_submenu():
		_show_page(_section, "")
	else:
		_show_page(null, "")


## Moves a knob by whole steps, as the -/+ buttons do.
func nudge(key: String, steps: int) -> void:
	_change(key, _tuning.value(key) + steps * _tuning.param(key).step)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		back()
		get_viewport().set_input_as_handled()


func _change(key: String, new_value: float) -> void:
	_tuning.set_value(key, new_value)
	if _rows.has(key):
		_refresh_row(key)
	tuning_changed.emit(_tuning)


## Resets what the page shows: everything from the main menu, or just this section or group.
func _on_reset_pressed() -> void:
	_tuning.reset_keys(_keys_in(_shown_groups()))
	_show_page(_section, _group)
	tuning_changed.emit(_tuning)


func _on_done_pressed() -> void:
	hide()
	finished.emit(_tuning)


# --- Pages ---------------------------------------------------------------------------------------

func _show_page(section: TuningSection, group: String) -> void:
	_section = section
	_group = group
	_clear_page()
	if group != "":
		_build_rows(group)
	elif section != null:
		_build_group_menu(section)
	else:
		_build_main_menu()
	_title.text = TITLE_SEPARATOR.join(_page_path())
	_back_button.visible = section != null
	_reset_button.text = "Reset all" if section == null else "Reset"
	_scroll.scroll_vertical = 0


func _page_path() -> Array[String]:
	var path: Array[String] = [TITLE]
	if _section != null:
		path.append(_section.title)
		if _group != "" and _section.has_submenu():
			path.append(_section.label_of(_group))
	return path


func _shown_groups() -> Array[String]:
	if _group != "":
		return [_group]
	if _section != null:
		return _section.groups
	var groups: Array[String] = []
	for section in _sections:
		groups.append_array(section.groups)
	return groups


func _build_main_menu() -> void:
	var entries: Array[Button] = []
	for section in _sections:
		var text := section.title + (SUBMENU_MARK if section.has_submenu() else "")
		var open_it := func() -> void: _show_page(section, "" if section.has_submenu() else section.groups[0])
		entries.append(_menu_button(section.title, text, section.groups, open_it))
	_fill_columns(entries)


func _build_group_menu(section: TuningSection) -> void:
	var entries: Array[Button] = []
	for group in section.groups:
		var groups: Array[String] = [group]
		entries.append(_menu_button(group, section.label_of(group), groups, _show_page.bind(section, group)))
	_fill_columns(entries)


func _build_rows(group: String) -> void:
	var rows: Array[Control] = []
	if group == GameTuning.WORLD_GROUP:
		rows.append_array(_world_actions())
	for each in _tuning.params():
		if each.group == group:
			rows.append(_row(each))
	_fill_columns(rows)
	for key: String in _rows:
		_refresh_row(key)


## The World page opens with the world's seed and the two ways to start a world.
func _world_actions() -> Array[Control]:
	var seed_label := _label("World seed %d" % _world_seed, LABEL_WIDTH * 2)
	seed_label.name = "Seed"
	seed_label.custom_minimum_size.y = ROW_HEIGHT
	return [
		seed_label,
		_action_button("NewWorld", "New world", func() -> void: _start_world(new_world_requested)),
		_action_button("SameSeedAgain", "Same seed again", func() -> void: _start_world(same_seed_requested)),
	]


## Applies the tuning and closes the screen, then asks for the world.
func _start_world(request: Signal) -> void:
	_on_done_pressed()
	request.emit()


## The first half down the left column, the rest down the right, so the page reads top to bottom.
func _fill_columns(controls: Array) -> void:
	var left_count := ceili(controls.size() / 2.0)
	for index in controls.size():
		_columns[0 if index < left_count else 1].add_child(controls[index])


func _clear_page() -> void:
	_rows.clear()
	for column in _columns:
		for child in column.get_children():
			column.remove_child(child)
			child.queue_free()


func _keys_in(groups: Array[String]) -> Array[String]:
	var keys: Array[String] = []
	for each in _tuning.params():
		if each.group in groups:
			keys.append(each.key)
	return keys


# --- Widgets -------------------------------------------------------------------------------------

## An entry of a menu, marked when any knob under it differs from its default.
func _menu_button(id: String, text: String, groups: Array[String], on_pressed: Callable) -> Button:
	var changed := _keys_in(groups).any(_tuning.is_changed)
	var button := Button.new()
	button.name = id.validate_node_name()
	button.text = text + (CHANGED_MARK if changed else "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = MENU_BUTTON_HEIGHT
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", MENU_FONT_SIZE)
	if changed:
		button.add_theme_color_override("font_color", CHANGED_COLOR)
	button.pressed.connect(on_pressed)
	return button


func _action_button(id: String, text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = text
	button.custom_minimum_size.y = MENU_BUTTON_HEIGHT
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", MENU_FONT_SIZE)
	button.pressed.connect(on_pressed)
	return button


func _row(param: Tuning.Param) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = param.key.replace(".", "_")
	row.custom_minimum_size.y = ROW_HEIGHT

	var name_label := _label(param.label + ("\n(next world)" if param.next_run_only else ""), LABEL_WIDTH)
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


func _refresh_row(key: String) -> void:
	var row: Row = _rows[key]
	var value := _tuning.value(key)
	row.slider.set_value_no_signal(value)
	row.value_label.text = _format(value, _tuning.param(key).step)
	var color := CHANGED_COLOR if _tuning.is_changed(key) else DEFAULT_COLOR
	row.value_label.add_theme_color_override("font_color", color)


static func _format(value: float, step: float) -> String:
	return "%.2f" % value if step < 1.0 else str(roundi(value))
