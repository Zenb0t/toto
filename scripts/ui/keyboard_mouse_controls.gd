class_name KeyboardMouseControls
extends Node
## Keyboard and mouse play: WASD or the arrow keys move, the mouse aims, the left button attacks (held, it
## keeps attacking), the right button or Space uses the utility, 1-3 drink potions, E takes the item on the
## floor and Q cycles weapons. Only reports what the player asked for; the composition root decides what it
## means. Also tells which kind of play (touch or keyboard and mouse) is in use, following the last one used.

signal mode_changed(mode: InputMode.Kind)
signal attack_held_changed(held: bool)
signal utility_requested
## slot: 0 for the first kind of potion, in the order the potion belt shows them.
signal potion_requested(slot: int)
signal take_requested
signal weapon_switch_requested

const NO_SLOT := -1
const POTION_ACTIONS: Array[StringName] = [&"drink_potion_1", &"drink_potion_2", &"drink_potion_3"]

var mode := InputMode.initial(DisplayServer.is_touchscreen_available())

var _attack_held := false


func is_keyboard_mouse() -> bool:
	return mode == InputMode.Kind.KEYBOARD_MOUSE


func is_attack_held() -> bool:
	return _attack_held


## Where the mouse points, in viewport coordinates.
func cursor() -> Vector2:
	return get_viewport().get_mouse_position()


## 0..1 from the movement keys (they work whatever the kind of play).
func move_strength() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_set_attack_held(false)


## Sees every event, even those a button on screen takes, to follow the kind of play. A release always ends
## a held attack, wherever it happens.
func _input(event: InputEvent) -> void:
	var next := InputMode.after(event, mode)
	if next != mode:
		mode = next
		_set_attack_held(false)
		mode_changed.emit(mode)
	if event.is_action_released(&"attack"):
		_set_attack_held(false)


## Only what no button on screen took, so clicking the HUD doesn't attack.
func _unhandled_input(event: InputEvent) -> void:
	if not is_keyboard_mouse() or event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if _report(event):
		get_viewport().set_input_as_handled()


## Reports what the event asks for. False when it asks for nothing.
func _report(event: InputEvent) -> bool:
	if event.is_action_pressed(&"attack"):
		_set_attack_held(true)
	elif event.is_action_pressed(&"use_utility"):
		utility_requested.emit()
	elif event.is_action_pressed(&"take_item"):
		take_requested.emit()
	elif event.is_action_pressed(&"switch_weapon"):
		weapon_switch_requested.emit()
	else:
		var slot := _potion_slot(event)
		if slot == NO_SLOT:
			return false
		potion_requested.emit(slot)
	return true


func _potion_slot(event: InputEvent) -> int:
	for slot in POTION_ACTIONS.size():
		if event.is_action_pressed(POTION_ACTIONS[slot]):
			return slot
	return NO_SLOT


func _set_attack_held(held: bool) -> void:
	if held != _attack_held:
		_attack_held = held
		attack_held_changed.emit(held)
