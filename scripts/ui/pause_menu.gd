class_name PauseMenu
extends Control
## The in-game menu: a corner button opens it, and it offers the run and settings actions.
## It only reports what the player picked; the composition root decides what pausing or restarting means.

signal opened
signal closed
signal customize_requested
signal tuning_requested
signal restart_requested

@onready var _open_button: Button = $OpenButton
@onready var _panel: Control = $Panel


func _ready() -> void:
	_open_button.pressed.connect(open)
	$Panel/Items/Resume.pressed.connect(close)
	$Panel/Items/Customize.pressed.connect(_open_sub_screen.bind(customize_requested))
	$Panel/Items/Tune.pressed.connect(_open_sub_screen.bind(tuning_requested))
	$Panel/Items/Restart.pressed.connect(restart_requested.emit)
	_show_panel(false)


## True from open() until close(), including while a sub-screen is showing.
func is_open() -> bool:
	return not _open_button.visible


func open() -> void:
	_show_panel(true)
	opened.emit()


func close() -> void:
	_show_panel(false)
	closed.emit()


## Brings the panel back after a sub-screen (like the layout editor) is done.
func return_to_panel() -> void:
	_show_panel(true)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if not is_open():
		open()
	elif _panel.visible:
		close()
	get_viewport().set_input_as_handled()


func _open_sub_screen(requested: Signal) -> void:
	_panel.visible = false
	requested.emit()


func _show_panel(panel_visible: bool) -> void:
	_panel.visible = panel_visible
	_open_button.visible = not panel_visible
