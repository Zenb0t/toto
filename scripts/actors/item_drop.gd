class_name ItemDrop
extends PickupArea
## An item (weapon or utility) lying on the floor, waiting for the player to take it or leave it.
## It holds the item only to show and identify it; taking it is decided elsewhere.

const PICKUP_RADIUS := 18.0
const FONT_SIZE := 12
const LABEL_OFFSET := Vector2(0, -24)

var item: Item:
	set(value):
		item = value
		queue_redraw()


func _init(dropped: Item) -> void:
	super(PICKUP_RADIUS)
	item = dropped


func _draw() -> void:
	draw_circle(Vector2.ZERO, PICKUP_RADIUS, Color(item.color, 0.25))
	# Weapons are round, utilities square, so the slot an item goes in shows at a glance.
	var core := PICKUP_RADIUS * 0.45
	if item is Weapon:
		draw_circle(Vector2.ZERO, core, item.color)
	else:
		draw_rect(Rect2(-core, -core, core * 2.0, core * 2.0), item.color)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(item.button_label, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE)
	var baseline := LABEL_OFFSET - Vector2(text_size.x / 2.0, 0)
	draw_string(font, baseline, item.button_label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, item.color)
