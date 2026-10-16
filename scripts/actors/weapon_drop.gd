class_name WeaponDrop
extends PickupArea
## A weapon lying on the floor, waiting for the player to take it or leave it.
## It holds the weapon only to show and identify it; taking it is decided elsewhere.

const PICKUP_RADIUS := 18.0
const FONT_SIZE := 12
const LABEL_OFFSET := Vector2(0, -24)

var weapon: Weapon:
	set(value):
		weapon = value
		queue_redraw()


func _init(dropped: Weapon) -> void:
	super(PICKUP_RADIUS)
	weapon = dropped


func _draw() -> void:
	draw_circle(Vector2.ZERO, PICKUP_RADIUS, Color(weapon.color, 0.25))
	draw_circle(Vector2.ZERO, PICKUP_RADIUS * 0.45, weapon.color)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(weapon.button_label, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE)
	var baseline := LABEL_OFFSET - Vector2(text_size.x / 2.0, 0)
	draw_string(font, baseline, weapon.button_label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, weapon.color)
