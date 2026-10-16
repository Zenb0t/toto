class_name TouchControls
extends CanvasLayer
## Places the move stick and the action buttons according to a ControlLayout, and keeps them placed
## when the screen size changes (rotation, browser resize).

@onready var move_stick: TouchStick = $MoveStick
@onready var attack_button: AimButton = $AttackButton
@onready var utility_button: AimButton = $UtilityButton

var _layout := ControlLayout.new()


func _ready() -> void:
	get_viewport().size_changed.connect(_arrange)
	_arrange()


func apply_layout(layout: ControlLayout) -> void:
	_layout = layout
	_arrange()


func _arrange() -> void:
	var screen := get_viewport().get_visible_rect().size
	_place_button(attack_button, _layout.rect_in(ControlLayout.ATTACK, screen))
	_place_button(utility_button, _layout.rect_in(ControlLayout.UTILITY, screen))
	var stick_rect := _layout.rect_in(ControlLayout.STICK, screen)
	move_stick.radius = stick_rect.size.x / 2.0
	move_stick.rest_center = stick_rect.get_center() - move_stick.position


func _place_button(button: AimButton, rect: Rect2) -> void:
	button.position = rect.position
	button.size = rect.size
