class_name TouchControls
extends CanvasLayer
## Places the move stick and the action buttons according to a ControlLayout, and keeps them placed
## when the screen size changes (rotation, browser resize). While playing with keyboard and mouse the stick
## hides and the buttons only show what is equipped, its cooldown and the key that uses it.

const ATTACK_KEY_HINT := "click"
const MOVEMENT_KEY_HINT := "space"
const SKILL_KEY_HINT := "right click"
## The key that rests while the attack button reads REST.
const REST_KEY_HINT := "E"

@onready var move_stick: TouchStick = $MoveStick
@onready var attack_button: AimButton = $AttackButton
@onready var movement_button: AimButton = $MovementButton
@onready var skill_button: AimButton = $SkillButton

var _layout := ControlLayout.new()
var _touch := true
var _rest_offered := false


func _ready() -> void:
	get_viewport().size_changed.connect(_arrange)
	_arrange()


func apply_layout(layout: ControlLayout) -> void:
	_layout = layout
	_arrange()


## Touches on these controls (the minimap, the Map button) stay theirs: the stick and buttons leave them.
func keep_touches_for(keepers: Array[Control]) -> void:
	move_stick.blockers = keepers
	attack_button.blockers = keepers
	movement_button.blockers = keepers
	skill_button.blockers = keepers


## Off while playing with keyboard and mouse.
func use_touch(enabled: bool) -> void:
	move_stick.accepts_touch = enabled
	attack_button.accepts_touch = enabled
	movement_button.accepts_touch = enabled
	skill_button.accepts_touch = enabled
	_touch = enabled
	_show_attack_hint()
	movement_button.hint = "" if enabled else MOVEMENT_KEY_HINT
	skill_button.hint = "" if enabled else SKILL_KEY_HINT


## While the attack button reads REST, the key hint names the key that rests.
func offer_rest(offered: bool) -> void:
	_rest_offered = offered
	_show_attack_hint()


func _show_attack_hint() -> void:
	attack_button.hint = "" if _touch else (REST_KEY_HINT if _rest_offered else ATTACK_KEY_HINT)


func _arrange() -> void:
	var screen := get_viewport().get_visible_rect().size
	_place_button(attack_button, _layout.rect_in(ControlLayout.ATTACK, screen))
	_place_button(movement_button, _layout.rect_in(ControlLayout.MOVEMENT, screen))
	_place_button(skill_button, _layout.rect_in(ControlLayout.SKILL, screen))
	var zone := ControlLayout.stick_zone(screen)
	move_stick.position = zone.position
	move_stick.size = zone.size
	var stick_rect := _layout.rect_in(ControlLayout.STICK, screen)
	move_stick.radius = stick_rect.size.x / 2.0
	move_stick.rest_center = stick_rect.get_center() - move_stick.position


func _place_button(button: AimButton, rect: Rect2) -> void:
	button.position = rect.position
	button.size = rect.size
