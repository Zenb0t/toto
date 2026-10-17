class_name CreditsPanel
extends Control
## Full-screen list of what the game is built with (see Credits): name, author, license and what it is used for,
## with a link to each source. Back or Esc closes it; it only reports that, the composition root decides what's next.

signal finished

const BACKDROP_COLOR := Color(0.03, 0.02, 0.05, 0.92)
const TITLE_SIZE := 44
const NAME_SIZE := 28
const LINE_SIZE := 20
const BUTTON_SIZE := Vector2(130, 72)
const MARGIN := 16
const ENTRY_SEPARATION := 24
const DETAIL_COLOR := Color(1, 1, 1, 0.75)

var _list := VBoxContainer.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.offset_left = MARGIN
	page.offset_top = MARGIN
	page.offset_right = -MARGIN
	page.offset_bottom = -MARGIN
	add_child(page)
	page.add_child(_build_bar())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", ENTRY_SEPARATION)
	scroll.add_child(_list)
	_fill_list()
	hide()


func open() -> void:
	show()


func close() -> void:
	hide()
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _build_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	var back := Button.new()
	back.text = "‹ Back"
	back.custom_minimum_size = BUTTON_SIZE
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(close)
	bar.add_child(back)
	var title := Label.new()
	title.text = "Credits"
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	bar.add_child(title)
	return bar


func _fill_list() -> void:
	for entry in Credits.entries():
		_list.add_child(_entry_view(entry))
	for line in Credits.thanks():
		_list.add_child(_line(line, DETAIL_COLOR))


func _entry_view(entry: Credits.Entry) -> Control:
	var box := VBoxContainer.new()
	var title := _line(entry.name, Color.WHITE)
	title.add_theme_font_size_override("font_size", NAME_SIZE)
	box.add_child(title)
	box.add_child(_line("%s · %s" % [entry.author, entry.license], DETAIL_COLOR))
	box.add_child(_line(entry.used_for, DETAIL_COLOR))
	var link := LinkButton.new()
	link.text = entry.url
	link.uri = entry.url
	link.focus_mode = Control.FOCUS_NONE
	link.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	link.add_theme_font_size_override("font_size", LINE_SIZE)
	box.add_child(link)
	return box


func _line(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", LINE_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
