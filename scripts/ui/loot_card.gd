class_name LootCard
extends Control
## The quick compare shown while standing on a dropped item: what it is, what it replaces (the held item
## in the same slot, if any), Take or Leave.
## It only reports the choice; the composition root does the swap.

signal take_pressed
signal leave_pressed

const EMPTY_SLOT_TEXT := "Fills your empty skill slot"

@onready var _found_name: Label = $Panel/Rows/FoundName
@onready var _found_description: Label = $Panel/Rows/FoundDescription
@onready var _replaces: Label = $Panel/Rows/Replaces


func _ready() -> void:
	$Panel/Rows/Buttons/Take.pressed.connect(take_pressed.emit)
	$Panel/Rows/Buttons/Leave.pressed.connect(leave_pressed.emit)
	hide()


## held: what the item would replace, or null when its slot is empty.
func show_offer(found: Item, held: Item) -> void:
	_found_name.text = found.display_name
	_found_name.add_theme_color_override("font_color", found.color)
	_found_description.text = found.description
	_replaces.text = EMPTY_SLOT_TEXT if held == null else "Replaces your %s" % held.display_name
	show()
