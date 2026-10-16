class_name PotionBar
extends HBoxContainer
## The potion belt on screen: one button per kind of potion held, with how many are left. Tapping one
## asks to drink it; the composition root decides what happens.

signal drink_requested(potion_id: String)

const BUTTON_SIZE := Vector2(116, 64)
const FONT_SIZE := 20


## potions: every kind, in the order to show them; only those held get a button.
func show_belt(belt: PotionBelt, potions: Array[Potion]) -> void:
	for child in get_children():
		child.queue_free()
	for potion in potions:
		var count := belt.count(potion.id)
		if count > 0:
			add_child(_button(potion, count))


func _button(potion: Potion, count: int) -> Button:
	var button := Button.new()
	button.text = "%s ×%d" % [potion.button_label, count]
	button.custom_minimum_size = BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.add_theme_color_override("font_color", potion.color)
	button.pressed.connect(func() -> void: drink_requested.emit(potion.id))
	return button
