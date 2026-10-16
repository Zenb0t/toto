class_name InputMode
extends RefCounted
## Which way the player is playing: with fingers on a touch screen, or with a keyboard and mouse.
## The game follows whatever was used last, so a laptop with a touch screen works both ways.
## Godot turns mouse clicks into touches and touches into clicks so either kind of widget keeps working;
## those copies are marked as emulated and never count as the player switching.

enum Kind { TOUCH, KEYBOARD_MOUSE }


## Phones and tablets start with touch; everything else with keyboard and mouse.
static func initial(has_touch_screen: bool) -> Kind:
	return Kind.TOUCH if has_touch_screen else Kind.KEYBOARD_MOUSE


## The kind of play an event shows, or current when it shows nothing new.
static func after(event: InputEvent, current: Kind) -> Kind:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return current
	if event is InputEventScreenTouch and event.pressed:
		return Kind.TOUCH
	if event is InputEventKey and event.pressed:
		return Kind.KEYBOARD_MOUSE
	if event is InputEventMouseButton and event.pressed:
		return Kind.KEYBOARD_MOUSE
	return current
