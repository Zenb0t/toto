class_name RunSummaryPanel
extends Control
## The end-of-run screen: how the run ended (see RunSummary) and a button to start over. A won run can also go on
## playing in the same world. It only reports the choice; the composition root acts on it.

signal play_again_pressed
signal keep_playing_pressed

const BACKDROP_COLOR := Color(0.03, 0.02, 0.05, 0.82)
const TITLE_SIZE := 44
const LINE_SIZE := 22
const DIED_COLOR := Color(0.95, 0.4, 0.35)
const WON_COLOR := Color(0.95, 0.78, 0.35)

var _title := Label.new()
var _lines := VBoxContainer.new()
var _keep_playing := _button("Keep exploring")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	_title.add_theme_font_size_override("font_size", TITLE_SIZE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	column.add_child(_lines)
	_keep_playing.pressed.connect(keep_playing_pressed.emit)
	column.add_child(_keep_playing)
	var again := _button("Play again")
	again.pressed.connect(play_again_pressed.emit)
	column.add_child(again)
	hide()


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 72)
	button.add_theme_font_size_override("font_size", 26)
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button


func show_summary(ending: RunSummary.Ending, lines: PackedStringArray) -> void:
	_title.text = RunSummary.title(ending)
	_keep_playing.visible = ending == RunSummary.Ending.WON
	_title.add_theme_color_override("font_color", WON_COLOR if ending == RunSummary.Ending.WON else DIED_COLOR)
	for child in _lines.get_children():
		child.queue_free()
	for line in lines:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", LINE_SIZE)
		_lines.add_child(label)
	show()
